//
//  NetworkClient.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/2.
//  Copyright © 2016年 David. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol NetworkClientType {
	func fetchUsername(callback: (String?, ErrorType?) -> Void)
	func makeRequest(url: String,
	                        params: [String : AnyObject],
	                        callback: (JSON?, ErrorType?) -> Void)
}

struct NetworkClient: NetworkClientType {
	
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
	
	func makeRequest(url: String,
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