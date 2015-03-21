//
//  Endpoint.swift
//  
//
//  Created by BAN Jun on 2015/03/01.
//
//

import Foundation
import Alamofire
import SwiftyJSON


public enum Endpoint {
    case ServiceInfo
    case User
    case RoomList
    case PostMessage(message: String, roomID: String, files: [String])
    case MessageList(roomID: String, count: Int?, sinceID: String?, untilID: String?, order: SortOrder?)
    
    func URLRequest(baseURL: String, apiKey: String?) -> NSURLRequest {
        let (method: Alamofire.Method, path: String, parameters: [String: AnyObject]?, requiresApiKey: Bool) = {
            switch self {
            case .ServiceInfo: return (.GET, "/service/info.json", nil, false)
            case .User: return (.GET, "/user.json", nil, true)
            case .RoomList: return (.GET, "/room/list.json", nil, true)
            case let .PostMessage(message, roomID, files):
                return (.POST, "/message.json", ["room_id": roomID, "message": message], true) // TODO: files
            case let .MessageList(roomID, count, sinceID, untilID, order):
                var params = [String: AnyObject]()
                params["room_id"] = roomID
                params["count"] = count
                params["since_id"] = sinceID
                params["until_id"] = untilID
                params["order"] = order?.rawValue
                return (.GET, "/message/list.json", params, true)
            }
        }()
        
        var params = parameters ?? [:]
        if requiresApiKey {
            params["api_key"] = apiKey
        }
        
        return Endpoint.URLRequest(baseURL, method: method, path: path, parameters: params)
    }
    
    static func URLRequest(baseURL: String, method: Alamofire.Method, path: String, parameters: [String: AnyObject]?) -> NSURLRequest {
        let baseRequest = NSMutableURLRequest(URL: NSURL(string: baseURL + path)!)
        baseRequest.HTTPMethod = method.rawValue
        let (request, error) = Alamofire.ParameterEncoding.URL.encode(baseRequest, parameters: parameters)
        if let e = error {
            NSLog("error during creating request: \(e)")
        }
        return request
    }
}


public protocol ResponseItem {
    init?(_ json: SwiftyJSON.JSON)
}


public class ServiceInfo: ResponseItem {
    public class MessagePusher {
        public let name: String?
        public let param: [String: String]
        public var url: String? { return param["url"] }
        public var key: String? { return param["key"] }
        
        init(_ json: SwiftyJSON.JSON) {
            name = json["name"].string
            var param = [String: String]()
            for (k, v) in json["param"].dictionaryValue {
                param[k] = v.string
            }
            self.param = param
        }
    }
    public let messagePusher: MessagePusher
    
    public required init?(_ json: SwiftyJSON.JSON) {
        messagePusher = MessagePusher(json["message_pusher"])
    }
}


public class User: ResponseItem {
    public let id = ""
    public let name = ""
    public let screenName = ""
    public let profileImageURL = ""
    // NOTE: user_profiles for each rooms are not yet supported
    
    public required init?(_ json: SwiftyJSON.JSON) {
        let id = json["id"].string
        let name = json["name"].string
        let screenName = json["screen_name"].string
        let profileImageURL = json["profile_image_url"].string
        
        if ([id, name, screenName, profileImageURL].filter{$0 == nil}).count > 0 {
            return nil
        }
        
        self.id = id!
        self.name = name!
        self.screenName = screenName!
        self.profileImageURL = profileImageURL!
    }
}


public class Room: ResponseItem {
    public let id: String = ""
    public let name: String = ""
    public let owner: User?
    public let members: [User]
    public var ownerAndMembers: [User] {
        return compact([owner]) + members
    }
    
    public required init?(_ json: SwiftyJSON.JSON) {
        let id = json["id"].string
        let name = json["name"].string
        self.owner = User(json["user"])
        self.members = compact(json["members"].arrayValue.map{User($0)})
        
        if ([id, name].filter{$0 == nil}).count > 0 {
            return nil
        }
        
        self.id = id!
        self.name = name!
    }
}


public class PostMessage: ResponseItem {
    public let messageID: String = ""
    public required init?(_ json: SwiftyJSON.JSON) {
        let status = json["status"].string
        let error = json["error"].string
        let messageID = json["message_id"].string

        if status != "ok" || error != nil || messageID == nil {
            return nil
        }
        
        self.messageID = messageID!
    }
}


public class Many<T: ResponseItem>: ResponseItem {
    public let items = [T]()
    public required init?(_ json: SwiftyJSON.JSON) {
        if json.array == nil { return nil }
        
        var items = [T]()
        for a in json.array! {
            if let item = T(a) {
                items.append(item)
            } else {
                NSLog("cannot init from json: \(a)")
                return nil
            }
        }
        self.items = items
    }
}


private let dateFormatter: NSDateFormatter = {
    let df = NSDateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:SSZZZZ"
    return df
}()


public class Message: ResponseItem, Printable {
    public let id: String = ""
    public let name: String = ""
    public let screenName: String = ""
    public let body: String = ""
    public let htmlBody: String = ""
    public let createdAt: NSDate = NSDate()
    public let profileImageURL: String = ""
    
    public required init?(_ json: SwiftyJSON.JSON) {
        let id = json["id"].string
        let name = json["name"].string
        let screenName = json["screen_name"].string
        let body = json["body"].string
        let htmlBody = json["html_body"].string
        let profileImageURL = json["profile_image_url"].string
        let createdAt: NSDate? = json["created_at"].string.map{dateFormatter.dateFromString($0)} ?? nil
        
        let shouldBeNonNils: [Any?] = [id, name, screenName, body, htmlBody, profileImageURL, createdAt]
        if (shouldBeNonNils.filter{$0 == nil}).count > 0 {
            return nil
        }
        
        self.id = id!
        self.name = name!
        self.screenName = screenName!
        self.body = body!
        self.htmlBody = htmlBody!
        self.createdAt = createdAt!
        self.profileImageURL = profileImageURL!
    }
    
    public var description: String {
        return "Message([\(id)] \(createdAt) @\(screenName)(\(name)) ![\(profileImageURL)]: \(body) \(htmlBody))"
    }
}


public class RawJSON: ResponseItem {
    public let json: SwiftyJSON.JSON
    public required init?(_ json: SwiftyJSON.JSON) {
        self.json = json
    }
}


private func compact<T>(array: [T?]) -> [T] {
    return array.reduce([]){ a, b in b.map{a + [$0]} ?? a}
}

