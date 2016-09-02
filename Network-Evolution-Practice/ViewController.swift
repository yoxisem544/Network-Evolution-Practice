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

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		let url = "http://httpbin.org/post"
		let params = ["param": "yoxisem544"]
		
		// make a request
		request(.POST, url, parameters: params).response { _, _, data, error in
			if let jsonData = data where error == nil {
				let json = JSON(data: jsonData)
				self.label.text = "Username: " + json["form"]["param"].stringValue
			} else {
				self.label.text = "Requset failed"
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

