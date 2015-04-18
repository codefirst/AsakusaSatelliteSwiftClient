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


class ViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    var client = AsakusaSatellite.Client(apiKey: nil)
    let apiKeyField = UITextField()
    let usernameLabel = UILabel()
    let roomIDToPostField = UITextField()
    let messageToPostField = UITextField()
    let postButton = UIButton.buttonWithType(.System) as! UIButton
    let listButton = UIButton.buttonWithType(.System) as! UIButton
    let messagesTextView = UITextView()
    var pusher: MessagePusherClient?
    
    override func loadView() {
        super.loadView()
        
        edgesForExtendedLayout = nil
        
        view.backgroundColor = UIColor.whiteColor()
        
        apiKeyField.placeholder = "Your secret api key"
        apiKeyField.borderStyle = .RoundedRect
        apiKeyField.delegate = self
        
        roomIDToPostField.placeholder = "room ID to post or list"
        roomIDToPostField.borderStyle = .RoundedRect
        messageToPostField.placeholder = "message to post"
        messageToPostField.borderStyle = .RoundedRect
        postButton.setTitle("Send", forState: .Normal)
        postButton.addTarget(self, action: "post:", forControlEvents: .TouchUpInside)
        listButton.setTitle("List", forState: .Normal)
        listButton.addTarget(self, action: "list:", forControlEvents: .TouchUpInside)
        messagesTextView.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign in", style: .Plain, target: self, action: "signin:")
        
        let views = [
            "apiKey": apiKeyField,
            "name": usernameLabel,
            "roomID": roomIDToPostField,
            "message": messageToPostField,
            "post": postButton,
            "listButton": listButton,
            "messages": messagesTextView,
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
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-p-[listButton]", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[post]-p-|", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[messages]|", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-p-[apiKey]-p-[name]-20-[roomID]-[message]-[post]-[messages]|", options: nil, metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[message]-[listButton]", options: nil, metrics: metrics, views: views))
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
        // client = AsakusaSatellite.Client(rootURL: "http://localhost:3000", apiKey: apiKey)
        NSLog("initialized client with apiKey = \(apiKey)")
        
        usernameLabel.text = "(initialized)"
        client.user() { response in
            switch response {
            case .Success(let user):
                self.usernameLabel.text = "logged in as \(user.value.name)"
            case .Failure(let error):
                self.usernameLabel.text = "cannot log in: \(error)"
            }
        }
        
        client.roomList { response in
            switch response {
            case .Success(let many):
                let rooms = many.value.items
                NSLog("rooms: " + rooms.map{"\($0.name)(\($0.id))"}.description)
            case .Failure(let error):
                NSLog("failed to list rooms: \(error)")
            }
        }
        
        client.messagePusher(roomIDToPostField.text) { mpc in
            NSLog("pusher: \(mpc)")
            
            self.pusher = mpc
            if let pusher = self.pusher {
                pusher.onMessageCreate = { message in
                    // NSLog("onMessageCreate: \(message)")
                    self.messagesTextView.text = "\(self.messagesTextView.text)\n\(message.name): \(message.body)"
                }
                pusher.connect()
            }
        }
    }
    
    func post(sender: AnyObject?) {
        client.postMessage(messageToPostField.text, roomID: roomIDToPostField.text, files: []) { response in
            switch response {
            case .Success(let postMessage):
                NSLog("message posted successfully: \(postMessage.value.messageID)")
                self.messageToPostField.text = ""
            case .Failure(let error):
                NSLog("failed to post message: \(error)")
            }
        }
    }
    
    func list(sender: AnyObject?) {
        client.messageList(roomIDToPostField.text, count: 20, sinceID: nil, untilID: nil, order: .Desc) { response in
            switch response {
            case .Success(let many):
                let messages = many.value.items
                // NSLog("messages (\(messages.count)): \(messages)")
                self.messagesTextView.text = "\n".join(messages.map{"\($0.name): \($0.body)"})
            case .Failure(let error):
                NSLog("failed to list messages: \(error)")
            }
        }
    }
    
    func signin(sender: AnyObject?) {
        let vc = TwitterAuthViewController(rootURL: NSURL(string: client.rootURL)!) { [weak self] apiKey in
            let defaults = NSUserDefaults.standardUserDefaults()
            if let apiKey = apiKey {
                defaults.setObject(apiKey, forKey: kDefaultsKeyApiKey)
            } else {
                NSLog("cannot sign in")
                defaults.removeObjectForKey(kDefaultsKeyApiKey)
            }
            defaults.synchronize()
            self?.reloadClient()
        }
        navigationController?.pushViewController(vc, animated: true)
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
    
    // MARK: - TextView

    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        view.endEditing(true)
        return false
    }
}

