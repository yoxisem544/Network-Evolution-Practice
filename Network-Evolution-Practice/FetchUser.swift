//
//  FetchUser.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/2.
//  Copyright © 2016年 David. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

class FetchUser: NetworkRequest {
	typealias ResponseType = User
	
	var endpoint: String { return "post" }
	var method: Alamofire.Method { return .POST }
	var parameters: [String : AnyObject] { return ["param": username] }
	
	private var username: String = ""
	
	func perform(username: String) -> Promise<User> {
		self.username = username
		return networkClient.performRequest(self).then(responseHandler)
	}
	
}