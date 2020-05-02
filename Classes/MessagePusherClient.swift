//
//  MessagePusherClient.swift
//  Pods
//
//  Created by BAN Jun on 2015/03/15.
//
//

import Foundation
import SocketIO


open class MessagePusherClient: CustomStringConvertible {
    let engine: Engine
    let roomID: String
    let socketManager: SocketManager
    let socket: SocketIOClient
    
    // callbacks
    open var onMessageCreate: ((Message) -> Void)?
    
    
    public enum Engine: CustomStringConvertible {
        case keima(url: URL, key: String)
        
        public init?(messagePusher: ServiceInfo.MessagePusher) {
            switch messagePusher.name {
            case .some("asakusasatellite::messagepusher::keima"):
                guard let urlString = messagePusher.url, let url = URL(string: urlString), let key = messagePusher.key else { return nil }
                self = .keima(url: url, key: key)
            default:
                return nil
            }
        }
        
        var url: URL {
            switch self {
            case .keima(let url, _): return url
            }
        }
        
        public var description: String {
            return "Engine(\(url))"
        }
    }
    
    
    public init(engine: Engine, roomID: String) {
        self.engine = engine
        self.roomID = roomID
        let connectParams: [String: Any] = {
            switch engine {
            case .keima(_, let key): return ["app": key]
            }
            }()
        self.socketManager = SocketManager(socketURL: engine.url, config: [.connectParams(connectParams)])
        self.socket = self.socketManager.defaultSocket
        self.socket.on("connect") { data, ack in
            // NSLog("%@", "\(self): on connect")
            ack.with([])
            self.subscribe()
        }
        self.socket.on("message_create") { data, ack in
            // NSLog("%@", "\(self): on message_create")
            ack.with([])
            
            // args matches Pusher interface and thus: [0] => ID?, [1] => app content json
            if let args = data as? [String] {
                if args.count < 2 { NSLog("%@", "\(self) unexpected message_create args: \(data)"); return }
                
                do {
                    struct MessageWrapper: APIModel {
                        var content: Message
                    }
                    guard let data = args[1].data(using: .utf8, allowLossyConversion: true) else { return }
                    let message = try MessageWrapper.decoder.decode(MessageWrapper.self, from: data)
                    self.onMessageCreate?(message.content)
                } catch {
                    NSLog("%@", "\(self) cannot parse json: \(data)")
                }
            }
        }
    }
    
    
    open var description: String {
        return "MessagePusherClient(\(engine), roomID: \(roomID))"
    }
    
    
    open func connect() {
        socket.connect()
    }
    
    open func subscribe() {
        socket.emit("subscribe", "as-\(roomID)")
    }
}
