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
import PromiseKit

protocol NetworkClientType {
	func performRequest<Request: NetworkRequest>(networkRequest: Request) -> Promise<NSData>
}

struct NetworkClient: NetworkClientType {
	
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
	
}