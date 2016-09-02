//
//  NetworkRequest.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/2.
//  Copyright © 2016年 David. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

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

extension NetworkRequest {
	var url: String { return baseURL + endpoint }
	var baseURL: String { return "http://httpbin.org/" }
	var method: Alamofire.Method { return .GET }
	var encoding: Alamofire.ParameterEncoding { return .JSON }
	
	var parameters: [String : AnyObject] { return [:] }
	var headers: [String : String] { return [:] }
	
	var networkClient: NetworkClientType { return NetworkClient() }
}

extension NetworkRequest where ResponseType: JSONDecodable {
	var responseHandler: NSData -> ResponseType? { return jsonResponseHandler }
}

private func jsonResponseHandler<Response: JSONDecodable>(data: NSData) -> Response? {
	let json = JSON(data: data)
	return Response(json: json)
}

