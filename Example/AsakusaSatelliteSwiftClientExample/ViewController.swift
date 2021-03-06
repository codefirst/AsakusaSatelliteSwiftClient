//
//  ViewController.swift
//  AsakusaSatelliteSwiftClientExample
//
//  Created by BAN Jun on 2015/03/01.
//  Copyright (c) 2015年 codefirst. All rights reserved.
//

import UIKit
import AsakusaSatellite


private let kDefaultsKeyApiKey = "apiKey"


class ViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, URLHandler {
    var client = AsakusaSatellite.Client(apiKey: nil)
    let apiKeyField = UITextField()
    let usernameLabel = UILabel()
    let roomIDToPostField = UITextField()
    let messageToPostField = UITextField()
    let postButton = UIButton(type: .system)
    let listButton = UIButton(type: .system)
    let messagesTextView = UITextView()
    var pusher: MessagePusherClient?
    
    override func loadView() {
        super.loadView()
        
        edgesForExtendedLayout = []
        
        view.backgroundColor = .white
        
        apiKeyField.placeholder = "Your secret api key"
        apiKeyField.borderStyle = .roundedRect
        apiKeyField.delegate = self
        
        roomIDToPostField.placeholder = "room ID to post or list"
        roomIDToPostField.borderStyle = .roundedRect
        messageToPostField.placeholder = "message to post"
        messageToPostField.borderStyle = .roundedRect
        postButton.setTitle("Send", for: .normal)
        postButton.addTarget(self, action: #selector(post(_:)), for: .touchUpInside)
        listButton.setTitle("List", for: .normal)
        listButton.addTarget(self, action: #selector(list(_:)), for: .touchUpInside)
        messagesTextView.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign in", style: .plain, target: self, action: #selector(signin))
        
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
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-p-[apiKey]-p-|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-p-[name]-p-|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-p-[roomID]-p-|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-p-[message]-p-|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-p-[listButton]", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[post]-p-|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[messages]|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-p-[apiKey]-p-[name]-20-[roomID]-[message]-[post]-[messages]|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[message]-[listButton]", options: [], metrics: metrics, views: views))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "AsakusaSatelliteSwiftClientExample"
        reloadClient()
    }
    
    private func reloadClient() {
        let apiKey = UserDefaults.standard.object(forKey: kDefaultsKeyApiKey) as? String
        apiKeyField.text = apiKey
        client = AsakusaSatellite.Client(apiKey: apiKey)
        // client = AsakusaSatellite.Client(rootURL: "http://localhost:3000", apiKey: apiKey)
        NSLog("initialized client with apiKey = \(String(describing: apiKey))")
        
        usernameLabel.text = "(initialized)"
        client.user() { response in
            switch response {
            case .success(let user):
                self.usernameLabel.text = "logged in as \(user.name)"
            case .failure(let error):
                self.usernameLabel.text = "cannot log in: \(String(describing: error))"
            }
        }
        
        client.roomList { response in
            switch response {
            case .success(let rooms):
                NSLog("rooms: " + rooms.map{"\($0.name)(\($0.id))"}.description)
            case .failure(let error):
                NSLog("failed to list rooms: \(String(describing: error))")
            }
        }
        
        client.messagePusher(roomIDToPostField.text ?? "") { mpc in
            NSLog("pusher: \(String(describing: mpc))")
            
            self.pusher = mpc
            if let pusher = self.pusher {
                pusher.onMessageCreate = { message in
                    // NSLog("onMessageCreate: \(message)")
                    self.messagesTextView.text = "\(self.messagesTextView.text ?? "")\n\(message.name): \(message.body)"
                }
                pusher.connect()
            }
        }
    }
    
    @objc func post(_ sender: AnyObject?) {
        client.postMessage(messageToPostField.text ?? "", roomID: roomIDToPostField.text ?? "", files: []) { response in
            switch response {
            case .success(let postMessage):
                NSLog("message posted successfully: \(postMessage.message_id)")
                self.messageToPostField.text = ""
            case .failure(let error):
                NSLog("failed to post message: \(String(describing: error))")
            }
        }
    }
    
    @objc func list(_ sender: AnyObject?) {
        client.messageList(roomIDToPostField.text ?? "", count: 20, sinceID: nil, untilID: nil, order: .Desc) { response in
            switch response {
            case .success(let messages):
                // NSLog("messages (\(messages.count)): \(messages)")
                self.messagesTextView.text = messages.map{"\($0.name): \($0.body)"}.joined(separator: "\n")
            case .failure(let error):
                NSLog("failed to list messages: \(String(describing: error))")
            }
        }
    }

    // MARK: - Sign in

    private var auth: Auth?

    @objc private func signin() {
        guard let rootURL = URL(string: client.rootURL) else { return }
        let auth = Auth()
        auth.completion = { apiKey in
            let defaults = UserDefaults.standard
            if let apiKey = apiKey {
                defaults.set(apiKey, forKey: kDefaultsKeyApiKey)
            } else {
                NSLog("cannot sign in")
                defaults.removeObject(forKey: kDefaultsKeyApiKey)
            }
            defaults.synchronize()
            self.reloadClient()
            self.auth = nil
        }
        auth.presentSignInViewController(on: self, rootURL: rootURL, callbackScheme: "org.codefirst.AsakusaSatelliteSwiftClientExample")
        self.auth = auth
    }

    func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return auth?.open(url: url, options: options) ?? false
    }
    
    // MARK: - TextField
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let defaults = UserDefaults.standard
        let apiKey = apiKeyField.text
        if !(apiKey?.isEmpty ?? true) {
            defaults.set(apiKey, forKey: kDefaultsKeyApiKey)
        } else {
            defaults.removeObject(forKey: kDefaultsKeyApiKey)
        }
        defaults.synchronize()
        
        reloadClient()
        
        return true
    }
    
    // MARK: - TextView

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        view.endEditing(true)
        return false
    }
}

