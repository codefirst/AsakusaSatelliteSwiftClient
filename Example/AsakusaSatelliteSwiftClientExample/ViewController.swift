//
//  ViewController.swift
//  AsakusaSatelliteSwiftClientExample
//
//  Created by BAN Jun on 2015/03/01.
//  Copyright (c) 2015年 codefirst. All rights reserved.
//

import UIKit
import AsakusaSatellite
import SwiftyJSON


private let kDefaultsKeyApiKey = "apiKey"


class ViewController: UIViewController, UITextFieldDelegate {
    var client = AsakusaSatellite.Client(apiKey: nil)
    let apiKeyField = UITextField()
    let usernameLabel = UILabel()
    let roomIDToPostField = UITextField()
    let messageToPostField = UITextField()
    let postButton = UIButton.buttonWithType(.System) as UIButton
    
    override func loadView() {
        super.loadView()
        
        edgesForExtendedLayout = nil
        
        view.backgroundColor = UIColor.whiteColor()
        
        apiKeyField.placeholder = "Your secret api key"
        apiKeyField.borderStyle = .RoundedRect
        apiKeyField.delegate = self
        
        roomIDToPostField.placeholder = "room ID to post"
        roomIDToPostField.borderStyle = .RoundedRect
        messageToPostField.placeholder = "message to post"
        messageToPostField.borderStyle = .RoundedRect
        postButton.setTitle("Send", forState: .Normal)
        postButton.addTarget(self, action: "post:", forControlEvents: .TouchUpInside)
        
        let views = [
            "apiKey": apiKeyField,
            "name": usernameLabel,
            "roomID": roomIDToPostField,
            "message": messageToPostField,
            "post": postButton,
        ]
        let metrics = ["p": 8]
        for v in views.values {
            v.setTranslatesAutoresizingMaskIntoConstraints(false)
            view.addSubview(v)
        }
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-p-[apiKey]-p-|", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-p-[name]-p-|", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-p-[roomID]-p-|", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-p-[message]-p-|", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-p-[post]-p-|", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-p-[apiKey]-p-[name]-20-[roomID]-[message]-[post]", options: nil, metrics: metrics, views: views))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "AsakusaSatelliteSwiftClientExample"
        reloadClient()
    }
    
    private func reloadClient() {
        let apiKey = NSUserDefaults.standardUserDefaults().objectForKey(kDefaultsKeyApiKey) as? String
        apiKeyField.text = apiKey
        client = AsakusaSatellite.Client(apiKey: apiKey)
        NSLog("initialized client with apiKey = \(apiKey)")
        
        client.serviceInfo() { response in
            switch response {
            case .Success(let serviceInfo):
                NSLog("service/info: name = \(serviceInfo().messagePusher.name), url = \(serviceInfo().messagePusher.url)")
            case .Failure(_):
                break
            }
        }
        
        usernameLabel.text = "(initialized)"
        client.user() { response in
            switch response {
            case .Success(let user):
                self.usernameLabel.text = "logged in as \(user().name)"
            case .Failure(let error):
                self.usernameLabel.text = "cannot log in: \(error)"
            }
        }
    }
    
    func post(sender: AnyObject?) {
        client.postMessage(messageToPostField.text, roomID: roomIDToPostField.text, files: []) { response in
            switch response {
            case .Success(let json):
                NSLog("message posted successfully: \(json())")
                self.messageToPostField.text = ""
            case .Failure(let error):
                NSLog("failed to post message: \(error)")
            }
        }
    }
    
    // MARK: - TextField
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        let apiKey = apiKeyField.text
        if !(apiKey?.isEmpty ?? true) {
            defaults.setObject(apiKey, forKey: kDefaultsKeyApiKey)
        } else {
            defaults.removeObjectForKey(kDefaultsKeyApiKey)
        }
        defaults.synchronize()
        
        reloadClient()
        
        return true
    }
}

