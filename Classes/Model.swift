//
//  Model.swift
//  Pods
//
//  Created by BAN Jun on 2015/07/20.
//
//

import Foundation
import SwiftyJSON


public protocol APIModel {
    var json: SwiftyJSON.JSON { get }
    init?(json: SwiftyJSON.JSON)
}

extension APIModel {
    var jsonString: String? { return json.rawString(NSUTF8StringEncoding, options: .PrettyPrinted) }
    
    public func saveToFile(path: String) -> Bool {
        do {
            guard let s = jsonString else { return false }
            try s.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
            return true
        } catch _ {
            return false
        }
    }
    
    public init?(file path: String) {
        if let json = (NSData(contentsOfFile: path).map{SwiftyJSON.JSON(data: $0, options: .AllowFragments, error: nil)}) {
            self.init(json: json)
        } else {
            return nil
        }
    }
}


public struct Many<T: APIModel>: APIModel {
    public let json: JSON
    
    public let items: [T]
    
    public init?(json: JSON) {
        self.json = json
        
        guard let array = json.array else { return nil }
        
        var items = [T]()
        for a in array {
            guard let item = T(json: a) else {
                NSLog("%@", "cannot init from json: \(a)")
                return nil
            }
            items.append(item)
        }
        self.items = items
    }
    
    public init?(items: [T]) {
        self.init(json: JSON(items.map{$0.json}))
    }
}


public struct Nothing: APIModel {
    public let json: JSON
    
    public init?(json: JSON) {
        self.json = json
    }
}


public struct ServiceInfo: APIModel {
    public let json: JSON
    
    public struct MessagePusher: APIModel {
        public let json: JSON
        
        public let name: String?
        public let param: [String: String]
        public var url: String? { return param["url"] }
        public var key: String? { return param["key"] }
        
        public init?(json: JSON) {
            self.json = json
            
            name = json["name"].string
            var param = [String: String]()
            for (k, v) in json["param"].dictionaryValue {
                param[k] = v.string
            }
            self.param = param
        }
    }
    public let messagePusher: MessagePusher
    
    public init?(json: JSON) {
        self.json = json
        guard let messagePusher = MessagePusher(json: json["message_pusher"]) else { return nil }
        
        self.messagePusher = messagePusher
    }
}


public struct User: APIModel {
    public let json: JSON
    
    public let id: String
    public let name: String
    public let screenName: String
    public let profileImageURL: String
    
    public init?(json: JSON) {
        self.json = json
        guard let id = json["id"].string,
            name = json["name"].string,
            screenName = json["screen_name"].string,
            profileImageURL = json["profile_image_url"].string else { return nil }
        
        self.id = id
        self.name = name
        self.screenName = screenName
        self.profileImageURL = profileImageURL
    }
}


public struct Room: APIModel {
    public let json: JSON
    
    public let id: String
    public let name: String
    public let owner: User?
    public let members: [User]
    public var ownerAndMembers: [User] {
        return compact([owner]) + members
    }
    
    public init?(json: JSON) {
        self.json = json
        guard let id = json["id"].string,
            name = json["name"].string else { return nil }
        
        self.id = id
        self.name = name
        self.owner = User(json: json["user"])
        self.members = compact(json["members"].arrayValue.map{User(json: $0)})
    }
}


public struct PostMessage: APIModel {
    public let json: JSON
    
    public let messageID: String
    
    public init?(json: JSON) {
        self.json = json
        if json["status"].string != "ok" || json["error"].string != nil { return nil }
        guard let messageID = json["message_id"].string else { return nil }
        
        self.messageID = messageID
    }
}


private let dateFormatter: NSDateFormatter = {
    let df = NSDateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:SSZZZZ"
    return df
    }()


public struct Message: APIModel, CustomStringConvertible {
    public let json: JSON
    
    public let id: String
    public let name: String
    public let screenName: String
    public let body: String
    public let htmlBody: String
    public let createdAt: NSDate
    public let profileImageURL: String
    public let attachments: [Attachment]
    public var imageAttachments: [Attachment] { return attachments.filter{$0.contentType.hasPrefix("image/")} }
    
    public init?(json: JSON) {
        self.json = json
        
        guard let id = json["id"].string,
            name = json["name"].string,
            screenName = json["screen_name"].string,
            body = json["body"].string,
            htmlBody = json["html_body"].string,
            profileImageURL = json["profile_image_url"].string,
            createdAt = json["created_at"].string.flatMap({dateFormatter.dateFromString($0)}) else { return nil }
        
        self.id = id
        self.name = name
        self.screenName = screenName
        self.body = body
        self.htmlBody = htmlBody
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.attachments = compact(json["attachment"].arrayValue.map{Attachment(json: $0)})
    }
    
    public var description: String {
        return "Message([\(id)] \(createdAt) @\(screenName)(\(name)) ![\(profileImageURL)]: \(body) \(htmlBody))"
    }
}


public struct Attachment: APIModel, CustomStringConvertible {
    public let json: JSON
    
    public let url: String // can be relative URL
    public let filename: String
    public let contentType: String
    
    public init?(json: JSON) {
        self.json = json
        
        guard let url = json["url"].string,
            filename = json["filename"].string,
            contentType = json["content_type"].string else { return nil }
        
        self.url = url
        self.filename = filename
        self.contentType = contentType
    }
    
    public var description: String {
        return "Attachment([\(contentType)] \(filename) at \(url))"
    }
}


private func compact<T>(array: [T?]) -> [T] {
    return array.reduce([]){ a, b in b.map{a + [$0]} ?? a}
}

