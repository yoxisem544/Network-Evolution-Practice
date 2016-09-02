//
//  FetchUser.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/2.
//  Copyright © 2016年 David. All rights reserved.
//

import Foundation
import Alamofire

class FetchUser: NetworkRequest {
	typealias ResponseType = User
	
	var endpoint: String { return "post" }
	var method: Alamofire.Method { return .POST }
	var parameters: [String : AnyObject] { return ["param": username] }
	
	private var username: String = ""
	
	func perform(username: String, callback: (User?, ErrorType?) -> Void) {
		self.username = username
		let parsedCallback = { (data: NSData?, error: ErrorType?) in
			let response = data.flatMap(self.responseHandler)
			callback(response, error)
		}
		networkClient.makeRequest(self, callback: parsedCallback)
	}
}