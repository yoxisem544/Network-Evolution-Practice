//
//  ViewController.swift
//  Network-Evolution-Practice
//
//  Created by David on 2016/9/1.
//  Copyright © 2016年 David. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class ViewController: UIViewController {
	
	convenience init() {
		self.init(nibName: "ViewController", bundle: nil)
	}
	
	@IBOutlet weak var label: UILabel!
	var networkClient: NetworkClientType = NetworkClient()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		let url = "http://httpbin.org/post"
		let params = ["param": "feighter09"]
		
		// make a request
		networkClient.makeRequest(url, params: params) { (user: User?, error) in
			if let user = user where error == nil {
				self.label.text = "Username: " + user.name
			} else {
				self.label.text = "Request failed"
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

