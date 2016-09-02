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
	var fetchUser: FetchUser = FetchUser()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		// make a request
		fetchUser.perform("yoxisem544")
			.then { user in
				self.label.text = "Username: " + user.name
			}
			.error { error in
				self.label.text = "Request failed"
			}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

