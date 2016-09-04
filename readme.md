#Network Evolution
這是之前聽一個前FB工程師給的talk，有關網路架構的設計。因為覺得有趣且實用，方便管理且容易測試，於是在一個下雨天寫了這一篇筆記。

## 前言
此筆記一共分為7個階段

1. [Make Requset With Alamofire](https://github.com/yoxisem544/Network-Evolution-Practice#1-make-requset-with-alamofire)
2. [讓 NetworkClient 來負責網路的處理](https://github.com/yoxisem544/Network-Evolution-Practice#2-讓-networkclient-來負責網路的處理)
3. [測試](https://github.com/yoxisem544/Network-Evolution-Practice#3-測試)
4. [API-Specific Methods](https://github.com/yoxisem544/Network-Evolution-Practice#4-api-specific-methods)
5. [Model 是要可以從 JSON 被解析出來的](https://github.com/yoxisem544/Network-Evolution-Practice#5-model-是要可以被解析成-json-的)
6. [Service Object to Encapsulate Network Requests](https://github.com/yoxisem544/Network-Evolution-Practice#6-service-object-to-encapsulate-network-requests)
7. [Callback -> Promise](https://github.com/yoxisem544/Network-Evolution-Practice#7-callback---promise)

分別講解每一個階段所做的不同的事情與變動，以及以我的角度去理解，每一個階段做出的改變的優點。

這個repo包含每一個階段的程式碼，可以直接切換到不同的commit來閱讀以下每一個階段的筆記。

code 是轉自 Austin Feight 的 [Evolution of a Network Layer](https://github.com/feighter09/Evolution-of-a-Network-Layer)

我並不擁有這份 code。

## 1. Make Requset With Alamofire
### 一般的網路處理
一開始我們先回顧一下，我們一般在 iOS 中處理網路請求時的狀況。
一般而言，在iOS寫網路的時候大部份的我們會用callback或者delegate來處理async的資料問題。

`callback`的好處是你可以隨時隨地呼叫他，但是缺點就是如果在callback中呼叫callback，那麼你的程式碼就會越來越難維護，會變成callback hell。而且容易造成dead lock跟memory leak等等問題。

`delegate`也是一個不錯的方式，處理得當的話，不會有callback會造成的問題。但他的自由度沒有像callback那樣自由，他可能要符合宣告的規範，才能被使用。

以下我們使用callback來做為我們開始：

今天我們會去某一個網址，抓取我們要的username並且顯示在畫面上，
我們可以這樣做，在viewDidLoad時發送一個請求，像是這樣：

```swift
override func viewDidLoad() {
	super.viewDidLoad()
	// Do any additional setup after loading the view, typically from a nib.
		
	let url = "http://httpbin.org/post"
	let params = ["param": "yoxisem544"]
		
	// make a request
	request(.POST, url, parameters: params).response { _, _, data, error in
		if let jsonData = data where error == nil {
			let json = JSON(data: jsonData)
			self.label.text = "Username: " + json["form"]["param"].stringValue
		} else {
			self.label.text = "Requset failed"
		}
	}
}
```

這邊我們使用`Alamofire`來幫我們處理網路的部份，並且在成功之後更新label上的文字。

### 缺點
可以看到上面我們在viewDidLoad中做了網路處理，網路處理所需要的資訊以及回傳的資料處理都暴露在外面。如果我們在view controller中需要處理越來越多request，而且如果這些requset開始交雜在一起之後，就會變得越來越難維護。

## 2. 讓 NetworkClient 來負責網路的處理
當網路連線處理越來越多，越來越難管理時，我們可以把網路處理的事情交給 `NetwokrClient`來處理。

我們需要`NetwokrClient`幫我們做一些事情，但相對的我們必須給他`url`, `params`，以及一個相對應的`callback`。

### 加入 NetworkClient
```swift
struct NetworkClient {
  static func makeRequest(url: String,
                          params: [String : AnyObject],
                          callback: (JSON?, ErrorType?) -> Void) {
    request(.POST, url, parameters: params).response { _, _, data, error in
      if let jsonData = data where error == nil {
        let json = JSON(data: jsonData)
        callback(json, nil)
      } else {
        callback(nil, error)
      }
    }
    
  }
}
```
我們將剛剛在 view controller 中，發送連線請求的code搬到 `NetworkClient` 中，讓處理網路的事情，全權交給他處理。

### 回到 View Controller 中
回到 view controller 中，我們可以將剛剛的 request 改成：

```swift
NetworkClient.makeRequest(url, params: params) { json, error in
  if let json = json where error == nil {
    self.label.text = "Username: " + json["form"]["param"].stringValue
  } else {
    self.label.text = "Requset failed"
  }
}
```

是不是稍微變簡潔一點了？

### 回顧
但相對我們還是有些資訊暴露在外面，而且callback回來的資料還是要稍加處理之後才可以使用，這邊可以在改進。但下一步我們會先講解測式的部份，確定測式是好維護而且有意義的之後我們才會再回來改善`NetwokrClient`。

## 3. 測試
寫測試是很重要的事情，不管是 UI, Model 或者是網路處理，皆需要寫測試來驗證程式執行的正確性。

但是網路處理難的部份就是在，網路連線是asynchronous的，我們無法預期他什麼時候完成，然後會花多少的時間完成。

這時候我們就需要來模擬他所有錯誤及成功的狀態了。只要確定錯誤跟成功的狀態都如我們所預期，這個測試就會有意義了！

### 模擬網路狀態
這邊我們要模擬出兩種網路狀態：

1. 有網路
2. 沒有網路

具體怎麼做呢？

#### NetworkClientType  Protocol
首先要先建立一個`protocol`：`NetworkClientType`，這個型態的protocol要實做makeRequest這個方法。

```swift
protocol NetworkClientType {
	static func makeRequest(url: String,
	                        params: [String : AnyObject],
	                        callback: (JSON?, ErrorType?) -> Void)
}
```

然後讓剛剛的 `NetworkClient` 也遵從（conform） `NetworkClientType` 這個協定（protocol）。

#### 建立假的網路狀態
我們要開始寫我們的測試了！這邊要新增一個 `ViewControllerTests`。

根據我們剛剛的 `NetworkClientType` protocol，我們可以假造兩個我們所預期的網路狀態。

```swift
private struct MockSuccessNetworkClient: NetworkClientType {
	private static func makeRequest(url: String, params: [String : AnyObject], callback: (JSON?, ErrorType?) -> Void) {
		let json = JSON(["form": ["params": "yoxisem544"]])
		callback(json, nil)
	}
}

private struct MockFailureNetworkClient: NetworkClientType {
	private static func makeRequest(url: String, params: [String : AnyObject], callback: (JSON?, ErrorType?) -> Void) {
		callback(nil, NSError(domain: "", code: -1, userInfo: nil))
	}
}
```

我們新增兩個假的`NetworkClient`來模擬兩個網路狀態，而且可以看到，只要conform `NetworkClientType`，我們就必須實做`makeRequset`這個方法。再來，我們直接在callback中回傳假資料，來假造出假的網路狀態。

### 寫測試
最後我們回到測試，我們要來看看我們所造假的網路狀態是不是跟我們所預期的一樣。

我們要先讓test可以將vc中的networkclient取代掉，所以我們必須把protocol中的方法改成不是static的方法：

```swift
protocol NetworkClientType {
	func makeRequest(url: String,
	                        params: [String : AnyObject],
	                        callback: (JSON?, ErrorType?) -> Void)
}
```

然後要先把 view controller 中的 NetworkClient 改成一個變數，這樣我們就可以在測試中賦予他我們所假造的 NetworkClient 了：

```swift
var networkClient: NetworkClientType = NetworkClient()
```
回到測試中，我們要開始寫我們的測試了

這邊要注意的是，view Controller 在測試中不是在模擬器或者裝置上執行，他上面的view不會被render出來，所以我們要用`viewController.loadViewIfNeeded()`強迫他將畫面render出來。

而且可以注意到，我們可以將 networkClient 抽換成我們所預期的網路狀態，然後測試 ui 上所顯示的是不是我們所預期的：

```swift
extension ViewControllerTests {
	func test_successNetworkResponse_showsUsername() {
		viewController.networkClient = MockSuccessNetworkClient()
		viewController.loadViewIfNeeded()
		XCTAssertEqual(viewController.label.text, "Username: yoxisem544")
	}
	
	func test_failureNetworkResponse_showsUsername() {
		viewController.networkClient = MockFailureNetworkClient()
		viewController.loadViewIfNeeded()
		XCTAssertEqual(viewController.label.text, "Request failed")
	}
}
```

一切就緒後就按下 `cmd + u` 來執行測試吧！

## 4. API-Specific Methods
上面的方法makeRequest會讓閱讀的人不清楚他主要的目的，所以我們要進一步包裝我們的API。進一步包裝過的API可以清楚的讓其他人知道他存在的目的，而且我們可以將處理資料的部分交由他處理，最後讓callback回傳一個已經包裝過且有意義的資料，讓我們可以直接使用不需要經過轉換。

#### 修改 NetworkClientType
首先我們要先修改 `NetworkClientType`，在這個protcol加入一個新的方法叫做`fetchUsername`，然後他會回傳`Username`：

```swift
protocol NetworkClientType {
	func fetchUsername(callback: (String?, ErrorType?) -> Void)
	func makeRequest(url: String,
	                        params: [String : AnyObject],
	                        callback: (JSON?, ErrorType?) -> Void)
}
```

修改完這個protocol後，我們的`NetworkClient`就會報錯，叫我們要實做`fetchUsername`這個方法。

以下：

```swift
func fetchUsername(callback: (String?, ErrorType?) -> Void) {
  let url = "http://httpbin.org/post"
  let params = ["param": "yoxisem544"]
  
  makeRequest(url, params: params) { (json, error) in
    if let json = json where error == nil {
      let username = json["form"]["param"].string
      callback(username, nil)
    } else {
      callback(nil, error)
    }
  }
}
```

可以看到上面的callback只會回傳一個有意義的username，我們就不用在 view controller 中處理資料了！這樣也可以降低打錯字的機會。

#### 修改 ViewController
我們把很多複雜的東西，譬如param, url都藏進`NetworkClient`中了

於是在VC中我們只要單純的呼叫`fetchUsername`即可：

```swift
// make a request
networkClient.fetchUsername { (username, error) in
  if let username = username where error == nil {
    self.label.text = "Username: " + username
  } else {
    self.label.text = "Request failed"
  }
}
```

## 5. Model 是要可以從 JSON 被解析出來的
如果今天這個 API 單純只有抓取 username 並且回傳，那不需要寫成 model，但如果今天你的 model 很複雜，且擁有巢狀結構，那勢必就要寫成 model 了。寫成 model 之後，我們在取值就會變的方便而且比較不容易出錯，不需要像以前一樣還要輸入 json 的 key，一個不小心就會取不到值（nil）。

但從網路上抓下來的 JSON 並不能直接被轉成 model，中間要經過一層轉換才行。

### User Model
我們來建立一個 User，這個 model 目前只包含使用者的名稱（name）:

```swift
struct User {
	let name: String
}
```

### JSONDecodable
我們希望這個User能從 JSON 被轉換出來，所以我們要定義一個 protocol，只要 conform 這個 protocol 的 model 都必須實做 `init?(json: JSON)` 這個方法，來確保這個 model 一定可以從 JSON 被轉換出來。

```swift
protocol JSONDecodable {
	init?(json: JSON)
}
```

回到`User`，現在要讓`User`conform to `JSONDecodable` protocol，並且實做 `init?(json: JSON)` 這個方法。

```swift
extension User : JSONDecodable {
	init?(json: JSON) {
		guard let name = json["form"]["param"].string else { return nil }
		self.name = name
	}
}
```

### 修改 NetworkClientType Protocol
因為我們已經有了 `JSONDecodable`這個protocol，所以我們可以修改一下`NetworkClient`，讓他的回傳（`Response`）conform to `JSONDecodable`這個 protocol。之後只要指定 makeRequest 的 Response，所有遵從 `JSONDecodable` 的資料型態皆可以交給他做網路處理。

目前我們不需要fetchUsername這個方法，所以我們先移除他。

然後回過頭來看 `NetworkClientType` 的 `makeRequest` 這個方法：

```swift
protocol NetworkClientType {
	func makeRequest(url: String,
	                        params: [String : AnyObject],
	                        callback: (JSON?, ErrorType?) -> Void)
}
```

我們可以看到callback回傳的是`JSON?`，現在我們希望他回傳一個`Response`，而且這個`Response`遵從`JSONDecodable`協定。

於是我們可以把他寫成`泛型`的樣子，傳入任何 conform to `JSONDecodable` 的 model，然後 callback 就會回傳一個如果們所預期的 `Response`：

```swift
protocol NetworkClientType {
	func makeRequest<Response: JSONDecodable>(url: String,
	                        params: [String : AnyObject],
	                        callback: (Response?, ErrorType?) -> Void)
}
```

### 修改 NetworkClient
因為`NetworkClientType`協定變動了的緣故，所以 `NetworkClient` 我們也要稍加修改：

```swift
func makeRequest<Response : JSONDecodable>(url: String,
                 params: [String : AnyObject],
                 callback: (Response?, ErrorType?) -> Void) {
  request(.POST, url, parameters: params).response { _, _, data, error in
    if let jsonData = data where error == nil {
      let json = JSON(data: jsonData)
      let response = Response(json: json)
      callback(response, nil)
    } else {
      callback(nil, error)
    }
  }
}
```

注意到 `Respnse`，因為他 conform to `JSONDecodable` protocol，所以他一定有一個`init?(json: JSON)` 的建構子可以根據 json 建構出 `Response`。

### 修改 View Controller
因為我們把fetchUsername拿掉的緣故，現在的View Controller會有問題。

我們要回到沒有API-Specific的方法來處理我們的request:

```swift
networkClient.makeRequest(url, params: params) { (JSONDecodable?, ErrorType?) in
	// code here...
}
```
注意看我們的 `makeReqeust` 的 callback 會回傳 `JSONDecodable` 型態的 Response。所以這邊我們必須指定這個 Response 為 `User` 這個型態。

```swift
networkClient.makeRequest(url, params: params) { (user: User?, error) in
	// code here...
}
```

complete:

```swift
// make a request
networkClient.makeRequest(url, params: params) { (user: User?, error) in
	if let user = user where error == nil {
		self.label.text = "Username: " + user.name
	} else {
		self.label.text = "Request failed"
	}
}
```
這樣處理就可以不用每次都要用 json["username"].string 去取值，也不會不小心打錯 KEY 而取到 nil。

### 回到測試
因為我們已經修改了makeRequest的方法，所以測試的部份我們也要微調一下。

#### 調整 Mock 
現在我們來看一下 MockSuccessNetworkClient:

```swift
private struct MockSuccessNetworkClient: NetworkClientType {}
```
其實只要簡單的調整一下即可：

```swift
private struct MockSuccessNetworkClient: NetworkClientType {
	private func makeRequest<Response : JSONDecodable>(url: String, params: [String : AnyObject], callback: (Response?, ErrorType?) -> Void) {
		let json = JSON(["form": ["param": "yoxisem544"]])
		let response = Response(json: json)
		callback(response, nil)
	}
}

private struct MockFailureNetworkClient: NetworkClientType {
	private func makeRequest<Response : JSONDecodable>(url: String, params: [String : AnyObject], callback: (Response?, ErrorType?) -> Void) {
		callback(nil, NSError(domain: "", code: -1, userInfo: nil))
	}
}
```
一樣跑一下測試～～

## 6. Service Object to Encapsulate Network Requests
我們前面把 makeRequest 變成泛型後，我們就要再次把 fetchUser 拉回來了。 fetchUser 可以說是包裝過後的 network request，他專門處理 fetch user 這件事。

### NetworkRequest Protocol
在包裝前，我們要先製作一個協定，讓所有的network request都遵從這個協定。他可以幫助我們列出並且做必要的事：

我們需要有一個泛型的型態`associatedtype ResponseType`，我們可以指定這個protocol的回傳型態。

`associatedtype ResponseType`

以下是call API滿常會用到的一些東西：

必要

1.	endpoint: API溝通的端點。
2. responseHandler: NSData -> ResponseType? ：傳入`NSData` 並且會回傳指定的 `ResponseType`

上面的 responseHandler 比較特別，我們定義了這個新的 protocol，我們會希望這個 protocol 有人可以幫我們處理轉換 model 這件事。而這個handler就可以幫我們定義這件事。這個 responseHandler 需要傳入一個 `NSData` 然後處理完畢之後回傳 `ResponseType?`。
 
非必要 

1. baseUrl: 固定的連線網址
2. method: Alamofire.Method RESTful API methods, ex. GET, POST
3. encoding
4. params: 參數
5. headers
6. networkClient: 處理網路連線的client

我們希望遵從`NetworkRequest`協定的request都包含以上條件，可以方便我們發送request。

```swift
protocol NetworkRequest {
	associatedtype ResponseType
	
	// Required
	var endpoint: String { get }
	var responseHandler: NSData -> ResponseType? { get }
	
	// Optional
	var baseURL: String { get }
	var method: Alamofire.Method { get }
	var encoding: Alamofire.ParameterEncoding { get }
	
	var parameters: [String : AnyObject] { get }
	var headers: [String : String] { get }
	
	var networkClient: NetworkClientType { get }
}
```

### 擴展並且實做一些預設的設定
一般在做api call時，我們都需要用baseURL跟endpoint串成一個有意義的url來做request。而baseURL就是剛剛的`http://httpbin.org/post`。

```swift
extension NetworkRequest {
	var url: String { return baseURL + endpoint }
	var baseURL: String { return "http://httpbin.org/" }
	var method: Alamofire.Method { return .GET }
	var encoding: Alamofire.ParameterEncoding { return .JSON }
	
	var parameters: [String : AnyObject] { return [:] }
	var headers: [String : String] { return [:] }
	
	var networkClient: NetworkClientType { return NetworkClient() }
}
```

### 處理 JSON ResponseType
如果今天這個 `ResponseType` 遵從 `JSONDecodable` 協定，那麼他就可以從 JSON 被解析，因此我們可以對他做一點特別的事情。我們來定義一個特別的方法專門來處理他：

```swift
private func jsonResponseHandler<Response: JSONDecodable>(data: NSData) -> Response? {
	let json = JSON(data: data)
	return Response(json: json)
}
```

他的型態有點像上面的`responseHandler: NSData -> ResponseType?`，但這樣還不夠，我們要擴展 `NetworkRequest` 然後只有在 `ResponseType` conform to `JSONDecodable` 時才有的特別方法，而且可以把 responseHandler 抽換成我們剛剛定義的 `jsonResponseHandler`：

```swift
extension NetworkRequest where ResponseType: JSONDecodable {
	var responseHandler: NSData -> ResponseType? { return jsonResponseHandler }
}
```

這樣我們就處理完`NetworkRequest`這個協定了！

### 修改 NetworkClientType
因為我們現在有 `NetworkRequest` 這個協定，所以我們現在要稍微修改一下 `NetworkClientType` 協定。

我們希望讓`NetworkClientType`專注處理request就好，並不需要傳url, params等等資訊。

這邊我們要傳給`NetworkClientType`的只有單純的`NetworkRequest`即可，因為裡面有我們所需要的資訊。

所以我們稍加修正變成這樣：

```swift
protocol NetworkClientType {
	func makeRequest<Request: NetworkRequest>(networkRequest: Request, callback: (NSData?, ErrorType?) -> Void)
}
```

### 修改 NetworkClient
`NetworkClientType`一變動，勢必也要更改`NetworkClient`。

回想一下剛剛的`NetworkRequest`已經可以處理JSON的事情，所以`NetworkClient`只負責網路處理的部份，他並不處理資料。

而且`NetworkClient`也被包進`NetworkRequest`，變成處理連線的一小部份了。之後想做網路連線，只要遵從`NetworkRequest`即可。

於是我們可以把`NetworkClient`改成這樣：

```swift
func makeRequest<Request : NetworkRequest>(networkRequest: Request, callback: (NSData?, ErrorType?) -> Void) {
  request(networkRequest.method,
      networkRequest.url,
      parameters: networkRequest.parameters,
      encoding: networkRequest.encoding,
      headers: networkRequest.headers)
    .response { (_, _, data, error) in
      if let data = data where error == nil {
        callback(data, nil)
      } else {
        callback(nil, error)
      }
  }
}
```

### FetchUser Object
我們終於要來包裝我們的API了～

我們現在要建立一個物件，他專門處理fetch user這件事，而且要遵從`NetworkRequest`這個協定。

```swift
class FetchUser: NetworkRequest {}
```

然後我們必須指定我們的回傳型態: `User`，然後指定一些endpoint跟params等等

```swift
class FetchUser: NetworkRequest {
	typealias ResponseType = User
	
	var endpoint: String { return "post" }
	var method: Alamofire.Method { return .POST }
	var parameters: [String : AnyObject] { return ["param": username] }
	
	private var username: String = ""
}
```

這些資訊一直以來都暴露在view controller之中，但這些資訊都不是我們需要知道的事情，所以最好藏著比較好。

接著我們要包裝出一個可以在view controller之中方便取用而且名字具有意義的方法，我們就把他叫做：

`perform(username: String, callback: (User?, ErrorType?) -> Void)`

只需要傳入使用者的名稱，他就會回傳一個`User`回來。

實做：

```swift
func perform(username: String, callback: (User?, ErrorType?) -> Void) {
	self.username = username
	let parsedCallback = { (data: NSData?, error: ErrorType?) in
		let response = data.flatMap(self.responseHandler)
		callback(response, error)
	}
	networkClient.makeRequest(self, callback: parsedCallback)
}
```

因為現在的`makeRequest`只能傳入`NetworkRequest`型態的資訊，且會回傳一個帶有`NSData?`的callback，這邊我們就需要改變一下callback的型態。

回想一下，我們的`NetworkRequest`具有一個幫我們處理response的`responseHandler`，這邊會需要傳入NSData，然後這個`responseHandler`會幫我們處理然後回傳`ResonseType`。其實我們的`ResonseType`剛剛被我們指定為`User`，所以這邊會觸發`jsonResponseHandler`進而直接幫我們把`NSData`轉成`User`，因為`User`是`JSONDecodable`。

所以

`let response = data.flatMap(self.responseHandler)`

的`response`其實已經是`User`型態了，因為上面有指定`ResponseType` = `User`。

到此，我們已經完成FetchUser這個Object了。

### 修改 View Controller
因為我們已經有`FetchUser`這個Object了，所以我們可以直接把networkClient取代掉。

```swift
var fetchUser: FetchUser = FetchUser()
```

然後：

```swift
// make a request
fetchUser.perform("yoxisem544") { (user, error) in
  if let user = user where error == nil {
    self.label.text = "Username: " + user.name
  } else {
    self.label.text = "Request failed"
  }
}
```

因為剛剛把encoding改成JSON，這邊還要改一下`User`：

```swift
struct User {
	let name: String
}

extension User : JSONDecodable {
	init?(json: JSON) {
		guard let name = json["json"]["param"].string else { return nil }
		self.name = name
	}
}
```

最後就執行看看吧。

### 回到測試
我們來修改一下 Mock 部份：

```swift
private class MockSuccessFetchUser: FetchUser {
	private override func perform(username: String, callback: (User?, ErrorType?) -> Void) {
		let user = User(name: username)
		callback(user, nil)
	}
}

private class MockFailureFetchUser: FetchUser {
	private override func perform(username: String, callback: (User?, ErrorType?) -> Void) {
		callback(nil, NSError(domain: "", code: -1, userInfo: nil))
	}
}
```

我們現在需要假造的是perform這個方法。

然後改一下test method：

```swift
extension ViewControllerTests {
	func test_successNetworkResponse_showsUsername() {
		viewController.fetchUser = MockSuccessFetchUser()
		viewController.loadViewIfNeeded()
		XCTAssertEqual(viewController.label.text, "Username: yoxisem544")
	}
	
	func test_failureNetworkResponse_showsUsername() {
		viewController.fetchUser = MockFailureFetchUser()
		viewController.loadViewIfNeeded()
		XCTAssertEqual(viewController.label.text, "Request failed")
	}
}
```
一樣跑一下測試！

## 7. Callback -> Promise
太多的callback大家應該都知道code會變的很髒很亂吧？
所以才衍伸出Promise這個概念，請自行Google。

fb的Bolts也有點類似promise。（應該啦）

### 從 NetworkClientType 下手
這邊我們不要回傳callback，我們要讓這個協定變成回傳Promist<NSData>。

```swift
protocol NetworkClientType {
	func performRequest<Request: NetworkRequest>(networkRequest: Request) -> Promise<NSData>
}
```

### 修改 NetworkClient
這邊是我們處理callback的地方，我們可以把這邊的callback包裝下，變成promise。

`Promise<NSData>.pendingPromise()`會回傳三個東西

1. promise
2. success
3. failure

然後`pendingPromise`可以不用立馬執行。

然後讓我們修改一下`NetworkClient`:

```swift
func performRequest<Request : NetworkRequest>(networkRequest: Request) -> Promise<NSData> {
		
	let (promise, success, failure) = Promise<NSData>.pendingPromise()
		
	request(networkRequest.method,
		networkRequest.url,
		parameters: networkRequest.parameters,
		encoding: networkRequest.encoding,
		headers: networkRequest.headers)
		.response { (_, _, data, error) in
			if let data = data where error == nil {
				success(data)
			} else if let error = error {
				failure(error)
			}
	}
		
	return promise
}
```

很簡單，只需要把要反應的地方加上promise即可。

### 修改 FetchUser
我們也要將`FetchUser`的callback改成promise

```swift
func perform(username: String) -> Promise<User> {}
```

然後這邊我們需要先改一下model的錯誤處理，一開始我們都是用`init?(json: JSON)`來init，然後檢查是不是optional。現在我們改用Promise，他必須使用throws來處理錯誤，所以我們要改以下這些東西：

JSONDecodable: 

```swift
protocol JSONDecodable {
	init(json: JSON) throws 
}
```

User:

```swift
struct User {
	let name: String
}

extension User : JSONDecodable {
	init(json: JSON) throws {
		guard let name = json["json"]["param"].string else { throw JSONError.MissingKey("json.param") }
		self.name = name
	}
}
```

NetworkRequest:

```swift
protocol NetworkRequest {
	associatedtype ResponseType
	
	// Required
	var responseHandler: NSData throws -> ResponseType { get }
}

extension NetworkRequest where ResponseType: JSONDecodable {
	var responseHandler: NSData throws -> ResponseType { return jsonResponseHandler }
}

private func jsonResponseHandler<Response: JSONDecodable>(data: NSData) throws -> Response {
	let json = JSON(data: data)
	return try Response(json: json)
}
```

接著我們回到FetchUser，準備要來修改perform這個方法了。
因為networkClient的promise的緣故，他會回傳NSData到then這個方法裡面，而剛好就可以直接交給`responseHandler`處理了。

接個按著option點擊then這個方法，可以看到他會throws，所以這也是剛剛為什麼要改model的原因。

以下就是串上promise的perform！

```swift
func perform(username: String) -> Promise<User> {
	self.username = username
	return networkClient.performRequest(self).then(responseHandler)
}
```

### 回到 View Controller
修改剛剛我們所變更的東西

```swift
// make a request
fetchUser.perform("yoxisem544")
  .then { user in
    self.label.text = "Username: " + user.name
  }
  .error { error in
    self.label.text = "Request failed"
  }
```

接著執行程式。

### 回到測試

```swift
private class MockSuccessFetchUser: FetchUser {
	private override func perform(username: String) -> Promise<User> {
		return Promise(User(name: username))
	}
}

private class MockFailureFetchUser: FetchUser {
	private override func perform(username: String) -> Promise<User> {
		return Promise(error: NSError(domain: "", code: -1, userInfo: nil))
	}
}
```

然後好像是因為Promise緣故，所以很多東西都會跑進queue中，所以在測試的方法中，我們必須稍微等待他執行。

```swift
extension ViewControllerTests {
	func test_successNetworkResponse_showsUsername() {
		viewController.fetchUser = MockSuccessFetchUser()
		viewController.loadViewIfNeeded()
		
		let expectation = expectationWithDescription("Label set")
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10), dispatch_get_main_queue()) {
			XCTAssertEqual(self.viewController.label.text, "Username: yoxisem544")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(10, handler: nil)
	}
	
	func test_failureNetworkResponse_showsUsername() {
		viewController.fetchUser = MockFailureFetchUser()
		viewController.loadViewIfNeeded()
		
		let expectation = expectationWithDescription("Label set")
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10), dispatch_get_main_queue()) {
			XCTAssertEqual(self.viewController.label.text, "Request failed")
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(10, handler: nil)
	}
}
```

接著在跑一下測試。

## 結語
我花了一整天讀這份code，然後一段一段寫筆記，媽呀真的有夠累的。

這是 Austin 在 Cocoaheads 上給的 talk，最近終於有時間來細讀了！感謝 Austin Feight 提供這麼棒的觀念！！！

Many thanks to Austin Feight!

以上的 code 皆是轉自 Austin Feight 的 [Evolution of a Network Layer](https://github.com/feighter09/Evolution-of-a-Network-Layer)