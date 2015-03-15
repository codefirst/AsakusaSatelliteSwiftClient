//
//  MessagePusherClient.swift
//  Pods
//
//  Created by BAN Jun on 2015/03/15.
//
//

import Foundation
import Socket_IO_Client_Swift
import SwiftyJSON


public class MessagePusherClient: Printable {
    let engine: Engine
    let roomID: String
    let socket: SocketIOClient
    
    // callbacks
    public var onMessageCreate: (Message -> Void)?
    
    
    public enum Engine: Printable {
        case Keima(url: String, key: String)
        
        public init?(messagePusher: ServiceInfo.MessagePusher) {
            switch messagePusher.name {
            case .Some("asakusasatellite::messagepusher::keima"):
                if messagePusher.url == nil || messagePusher.key == nil { return nil }
                self = Keima(url: messagePusher.url!, key: messagePusher.key!)
            default:
                return nil
            }
            
            self = Keima(url: messagePusher.url!, key: messagePusher.key!)
        }
        
        var url: String {
            switch self {
            case .Keima(let url, _): return url
            }
        }
        
        public var description: String {
            return "Engine(\(url))"
        }
    }
    
    
    public init(engine: Engine, roomID: String) {
        self.engine = engine
        self.roomID = roomID
        self.socket = SocketIOClient(socketURL: engine.url)
        self.socket.on("connect") { data, ack in
            // NSLog("\(self): on connect")
            ack?()
            self.subscribe()
        }
        self.socket.on("message_create") { data, ack in
            // NSLog("\(self): on message_create")
            ack?()
            
            // args matches Pusher interface and thus: [0] => ID?, [1] => app content json
            if let args = data as? [String] {
                if args.count < 2 { NSLog("\(self) unexpected message_create args: \(data)"); return }
                
                let contentJsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(
                    args[1].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData(),
                    options: .AllowFragments,
                    error: nil)
                if contentJsonObject == nil { NSLog("\(self) cannot parse json: \(data)"); return }
                let contentJson = SwiftyJSON.JSON(contentJsonObject!)["content"]
                
                if let message = Message(contentJson) {
                    self.onMessageCreate?(message)
                } else {
                    NSLog("error in creating message from json: \(contentJson)")
                }
            }
        }
    }
    
    
    public var description: String {
        return "MessagePusherClient(\(engine), roomID: \(roomID))"
    }
    
    
    public func connect() {
        switch engine {
        case .Keima(_, let key): socket.connectWithParams(["app": key])
        }
        
    }
    
    public func subscribe() {
        socket.emit("subscribe", "as-\(roomID)")
    }
}
