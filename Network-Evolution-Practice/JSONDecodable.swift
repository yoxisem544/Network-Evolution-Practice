//
//  JSONDecodable.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/2.
//  Copyright © 2016年 David. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol JSONDecodable {
	init(json: JSON) throws 
}