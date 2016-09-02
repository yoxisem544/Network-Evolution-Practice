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
		
		// make a request
		networkClient.fetchUsername { (username, error) in
			if let username = username where error == nil {
				self.label.text = "Username: " + username
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

