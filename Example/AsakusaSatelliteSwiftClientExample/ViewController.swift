//
//  ViewController.swift
//  AsakusaSatelliteSwiftClientExample
//
//  Created by BAN Jun on 2015/03/01.
//  Copyright (c) 2015年 codefirst. All rights reserved.
//

import UIKit
import AsakusaSatelliteSwiftClient
import SwiftyJSON

class ViewController: UIViewController {
    let client = AsakusaSatelliteSwiftClient.Client()
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "AsakusaSatelliteSwiftClientExample"
        
        client.request(.ServiceInfo).responseServiceInfo{ response in
            switch response {
            case .Success(let serviceInfo):
                NSLog("service/info: \(serviceInfo())")
                NSLog("service/info url: \(serviceInfo().messagePusher.url)")
            case .Failure(_):
                break
            }
        }
    }
}

