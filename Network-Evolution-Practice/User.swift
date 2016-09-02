//
//  User.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/2.
//  Copyright © 2016年 David. All rights reserved.
//

import Foundation
import SwiftyJSON

struct User {
	let name: String
}

extension User : JSONDecodable {
	init?(json: JSON) {
		guard let name = json["json"]["param"].string else { return nil }
		self.name = name
	}
}