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
import UTIKit


private let kBoundary = "AsakusaSatellite-boundary-db1235c63fb8967513000351c0482df321505fb7"


public enum Endpoint {
    case ServiceInfo
    case User
    case RoomList
    case PostMessage(message: String, roomID: String, files: [String])
    case MessageList(roomID: String, count: Int?, sinceID: String?, untilID: String?, order: SortOrder?)
    case AddDevice(deviceToken: NSData, name: String)
    
    func URLRequest(baseURL: String, apiKey: String?) -> NSURLRequest {
        let (method, path, parameters, body, requiresApiKey) = { () -> (Alamofire.Method, String, [String: AnyObject]?, NSData?, Bool) in
            switch self {
            case .ServiceInfo: return (.GET, "/service/info.json", nil, nil, false)
            case .User: return (.GET, "/user.json", nil, nil, true)
            case .RoomList: return (.GET, "/room/list.json", nil, nil, true)
            case let .PostMessage(message, roomID, files):
                var body: NSMutableData!
                if files.count > 0 {
                    // add multipart (currently Alamofire does not have multipart API)
                    body = NSMutableData()
                    let crlf = "\r\n"
                    let crlfData = crlf.dataUsingEncoding(NSUTF8StringEncoding)!
                    var index = 0
                    for f in files {
                        if let data = NSData(contentsOfFile: f) {
                            let sequenceNumber = index > 0 ? "-\(index)" : ""
                            let filename = "AsakusaSat\(sequenceNumber).\(f.pathExtension)"
                            let mimeType: String = UTI(filenameExtension: f.pathExtension).MIMEType ?? "application/octet-stream"
                            
                            body.appendData("--\(kBoundary)\(crlf)".dataUsingEncoding(NSUTF8StringEncoding)!)
                            body.appendData("Content-Disposition: form-data; name=\"files[\(filename)]\"; filename=\"\(filename)\"\(crlf)".dataUsingEncoding(NSUTF8StringEncoding)!)
                            body.appendData("Content-Type: \(mimeType)\(crlf)".dataUsingEncoding(NSUTF8StringEncoding)!)
                            body.appendData(crlfData)
                            body.appendData(data)
                            body.appendData(crlfData)
                        }
                        ++index
                    }
                    body.appendData("--\(kBoundary)--\(crlf)".dataUsingEncoding(NSUTF8StringEncoding)!)
                }
                return (.POST, "/message.json", ["room_id": roomID, "message": message], body, true)
            case let .MessageList(roomID, count, sinceID, untilID, order):
                var params = [String: AnyObject]()
                params["room_id"] = roomID
                params["count"] = count
                params["since_id"] = sinceID
                if let untilID = untilID { params["until_id"] = untilID } // workaround for Xcode 7b3: "" is set when untilID = nil
                params["order"] = order?.rawValue
                return (.GET, "/message/list.json", params, nil, true)
            case let .AddDevice(deviceToken, name):
                return (.POST, "/user/add_device", ["device": deviceToken.description, "name": name], nil, true)
            }
            }()
        
        var params = parameters ?? [:]
        if requiresApiKey {
            params["api_key"] = apiKey
        }
        
        return Endpoint.URLRequest(baseURL, method: method, path: path, parameters: params, body: body)
    }
    
    static func URLRequest(baseURL: String, method: Alamofire.Method, path: String, parameters: [String: AnyObject]?, body: NSData?) -> NSURLRequest {
        let urlRequestWithParams: NSURLRequest = {
            let getRequest = NSMutableURLRequest(URL: NSURL(string: baseURL.stringByAppendingPathComponent(path))!)
            getRequest.HTTPMethod = Method.GET.rawValue
            let (request, error) = Alamofire.ParameterEncoding.URL.encode(getRequest, parameters: parameters) // Alamofire encode params into body when POST
            if let e = error {
                NSLog("error during creating request: \(e)")
            }
            return request
            }()
        
        let request = NSMutableURLRequest(URL: urlRequestWithParams.URL!)
        request.HTTPMethod = method.rawValue
        if let b = body {
            request.addValue("multipart/form-data; boundary=\(kBoundary)", forHTTPHeaderField: "Content-Type")
            request.addValue("\(b.length)", forHTTPHeaderField: "Content-Length")
            request.HTTPBody = b
        }
        
        return request
    }
}


public protocol APIModel {
    var json: SwiftyJSON.JSON { get }
    init?(json: SwiftyJSON.JSON)
}

extension APIModel {
    public func saveToFile(path: String) -> Bool {
        do {
            guard let s = json.rawString() else { return false }
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
                NSLog("cannot init from json: \(a)")
                return nil
            }
            items.append(item)
        }
        self.items = items
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

