//
//  ViewControllerTests.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/2.
//  Copyright © 2016年 David. All rights reserved.
//

@testable import Network_Evolution_Practice
import SwiftyJSON
import PromiseKit
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

// MARK: - Mocks
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