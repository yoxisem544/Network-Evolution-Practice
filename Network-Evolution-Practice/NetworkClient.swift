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
	func makeRequest<Request: NetworkRequest>(networkRequest: Request, callback: (NSData?, ErrorType?) -> Void)
}

struct NetworkClient: NetworkClientType {
	
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
	
}