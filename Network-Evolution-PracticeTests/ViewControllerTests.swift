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

// MARK: - Mocks
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