#Network Evolution
這是之前聽一個前FB工程師講的，有關網路的架構

因為覺得很有趣而且很實用

方便管理且容易測式

於是就來寫一篇筆記

## 前言
這邊會分為7個階段

分別講解每一個階段所做的不同的事情與變動

以及，以我的角度去理解，做出這個改變的優點

這個repo包含所有的程式碼

可以直接切換到不同的commit來閱讀以下每一個階段的筆記

code 是轉自 Austin Feight 的 [Evolution of a Network Layer](https://github.com/feighter09/Evolution-of-a-Network-Layer)

我並不擁有這份 code。

## 1. Make Requset With Alamofire
### 一般的網路處理
一如往常，在iOS寫網路的時候大部份的我們會用callback或者delegate來處理async的資料問題。

以下就可能是我們一般處理網路時的寫法，

我們可能在viewDidLoad時，發送一個請求，像是這樣：

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

我們會在callback回來之後處理資料，並且更新label上的文字。

### 缺點
當我們有很多的request雜在view中的時候，我們的程式碼就會越來越難維護。

## 2. 讓 NetworkClient 來負責網路的處理
當網路連線處理越來越多，越來越難管理時，我們可以把網路處理的是情交給 `NetwokrClient` 來處理。

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
回到VC中，我們可以將剛剛的request改成：

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

## 3. 測式
寫測式是很重要的事情

而且我們在寫網路的測式時，還會想要模擬出有網路跟沒有網路的狀況

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

然後讓剛剛的 `NetworkClient` 也comform `NetworkClientType` 這個protocol。

#### 建立假的網路狀態
這邊我們要新增一個 `ViewControllerTests`，然後我們要這邊模擬網路狀態。

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

### 寫測式
最後我們回到測式，我們要來看看我們所造假的網路狀態是不是跟我們所預期的一樣。

我們要先讓test可以抓到vc中的networkclient，所以我們必須把protocol中的方法改成不是static的方法
```swift
protocol NetworkClientType {
	func makeRequest(url: String,
	                        params: [String : AnyObject],
	                        callback: (JSON?, ErrorType?) -> Void)
}
```

我們要先把viewcontroller中的 NetworkClient 改成一個變數，且要是`NetworkClientType`型態的networkClient才可以，讓我們在測式中可以改變他的值
```swift
var networkClient: NetworkClientType = NetworkClient()
```
回到測式中，我們要開始寫我們的測式了

這邊要注意的是，viewController在測式中不是在模擬器或者裝置上執行，他上面的view不會被render出來，所以我們要用`viewController.loadViewIfNeeded()`強迫他render畫面。

而且可以注意到，我們可以將networkClient抽換成我們所預期的網路狀態，然後看ui是不是如我們所預期的顯示。

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
接下來就執行測式囉！

## 4. API-Specific Methods
上面的方法makeRequest會讓閱讀的人不清楚他主要的目的，所以我們要進一步包裝我們的API。

#### 修改 NetworkClientType
我們要先修改 `NetworkClientType`，在這個protcol加入一個新的方法叫做`fetchUsername`，然後他會回傳`Username`。
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

## 5. Model 是要可以被解析成 JSON 的
如果今天這個API單純只有抓取username並且回傳，那不需要寫成model，但如果今天你的model很複雜，且擁有巢狀結構，那勢必就要寫成model了。

但從網路上抓下來的JSON並不能直接被轉成model，中間要經過一層轉換才行。

### User Model
我們來建立一個User的model，這個model包含使用者的名稱

```swift
struct User {
	let name: String
}
```

### JSONDecodable
然後這個User勢必要可以從JSON被轉換出來，所以我們要寫一個protocol來規範他，讓他可以從JSON被轉換出來。

這邊我們要加入一個protocol `JSONDecodable`，conform這個protocol的model，必須實做`init?(json: JSON)`這個方法。
這樣可以確保這個model一定可以從JSON被轉換出來。

```swift
protocol JSONDecodable {
	init?(json: JSON)
}
```

讓我們回到`User`，我們要讓`User`conform to `JSONDecodable` protocol，並且實做這個方法。

```swift
extension User : JSONDecodable {
	init?(json: JSON) {
		guard let name = json["form"]["param"].string else { return nil }
		self.name = name
	}
}
```

### 修改 NetworkClientType Protocol
因為我們已經有了 `JSONDecodable`這個protocol，所以我們可以修改一下`NetworkClient`，讓他的回傳（Response）conform to `JSONDecodable`這個型態。之後只要指定makeRequest的Response即可。以後不一定只能Response `User`，只要遵從`JSONDecodable`這個協定的任何model皆可回傳。

目前我們不需要fetchUsername這個方法，所以我們先移除他。

然後回過頭來看`NetworkClientType`的`makeRequest `這個方法:

```swift
protocol NetworkClientType {
	func makeRequest(url: String,
	                        params: [String : AnyObject],
	                        callback: (JSON?, ErrorType?) -> Void)
}
```

我們可以看到callback回傳的是`JSON?`，現在我們希望他回傳一個`Response`，而且這個`Response`遵從`JSONDecodable`協定。

以下：

```swift
protocol NetworkClientType {
	func makeRequest<Response: JSONDecodable>(url: String,
	                        params: [String : AnyObject],
	                        callback: (Response?, ErrorType?) -> Void)
}
```
我們讓`Response`只遵從`JSONDecodable`協定，所以這個request方法就變成泛型的方法了。之後可以回傳任何型態的model。

### 修改 NetworkClient
因為`NetworkClientType`協定變動了的緣故，所以這邊我們也要稍加修改。

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

可以看到我們要把callback的response改成`Response`這個泛型型態。然後注意到，因為`Response`遵從`JSONDecodable`協定，所以他一定可以從JSON被轉換出來。

### 修改 View Controller
因為我們把fetchUsername拿掉的緣故，現在的View Controller會有問題。

我們要回到沒有API-Specific的方法來處理我們的request:

```swift
networkClient.makeRequest(url, params: params) { (JSONDecodable?, ErrorType?) in
	// code here...
}
```
注意看我們的`makeReqeust`的callback會回傳`JSONDecodable`型態的Response。所以我們可以指定說，這個回傳要回傳成`User`這個model型態。

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
這樣處理就可以不用每打json["username"].string 去取值，也不會不小心打錯KEY而取到nil。

### 回到測式
因為我們已經修改了makeRequest的方法，所以測式的部份我們也要微調一下。

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
一樣跑一下測式，成功！

## 6. Service Object to Encapsulate Network Requests
我們前面把makeRequest變成泛型後，我們就要再次把fetchUser拉回來了。fetchUser可以說是包裝過後的network request，他專門處理fetch user這件事。

### NetworkRequest Protocol
在包裝前，我們要先製作一個協定，讓所有的network request都遵從這個協定。他可以幫助我們列出並且做必要的事：

我們需要有一個泛型的型態`associatedtype ResponseType`，他將會是這個protocol的回傳型態。`associatedtype`可以在之後才指定。

`associatedtype ResponseType`

以下是call API滿常會用到的一些東西：

必要

1.	endpoint: API溝通的端點。
2. responseHandler: NSData -> ResponseType? ：傳入`NSData` 並且會回傳指定的 `ResponseType`
 
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
如果今天這個 `ResponseType` 遵從 `JSONDecodable` 協定，那麼他就可以從JSON被解析。

這邊我們需要一個幫我們處理json的方法

```swift
private func jsonResponseHandler<Response: JSONDecodable>(data: NSData) -> Response? {
	let json = JSON(data: data)
	return Response(json: json)
}
```
他的型態有點像上面的`responseHandler: NSData -> ResponseType?`

所以當今天這個`ResponseType`遵從`JSONDecodable`協定時，我們就可以使用`jsonResponseHandler`來幫助我們處理轉換JSON的事情。

```swift
extension NetworkRequest where ResponseType: JSONDecodable {
	var responseHandler: NSData -> ResponseType? { return jsonResponseHandler }
}
```

這樣我們就處理完`NetworkRequest`這個協定了！

### 修改 NetworkClientType
因為我們現在有`NetworkRequest`這個協定，所以我們現在要稍微修改一下`NetworkClientType`協定。

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

### 回到測式
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
一樣跑一下測式！

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

### 回到測式

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

然後好像是因為Promise緣故，所以很多東西都會跑進queue中，所以在測式的方法中，我們必須稍微等待他執行。

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

接著在跑一下測式。

## 結語
我花了一整天讀這份code，然後一段一段寫筆記，媽呀真的有夠累的。

這是 Austin 在 Cocoaheads 上給的 talk，最近終於有時間來細讀了！感謝 Austin Feight 提供這麼棒的觀念！！！

Many thanks to Austin Feight!

以上的 code 皆是轉自 Austin Feight 的 [Evolution of a Network Layer](https://github.com/feighter09/Evolution-of-a-Network-Layer)