//
//  ViewControllerTests.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/2.
//  Copyright © 2016年 David. All rights reserved.
//

@testable import Network_Evolution_Practice
import SwiftyJSON
import XCTest

class ViewControllerTests: XCTestCase {
	
	var viewController: ViewController!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		viewController = ViewController()
    }
    
}

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

// MARK: - Mocks
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