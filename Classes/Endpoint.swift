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
        let (method: Alamofire.Method, path: String, parameters: [String: AnyObject]?, body: NSData?, requiresApiKey: Bool) = {
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
                params["until_id"] = untilID
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
            let getRequest = NSMutableURLRequest(URL: NSURL(string: baseURL + path)!)
            getRequest.HTTPMethod = Method.GET.rawValue
            let (request, error) = Alamofire.ParameterEncoding.URL.encode(getRequest, parameters: parameters) // Alamofire encode params into body when POST
            if let e = error {
                NSLog("error during creating request: \(e)")
            }
            return request
            }()
        
        let request = NSMutableURLRequest(URL: urlRequestWithParams.URL)
        request.HTTPMethod = method.rawValue
        if let b = body {
            request.addValue("multipart/form-data; boundary=\(kBoundary)", forHTTPHeaderField: "Content-Type")
            request.addValue("\(b.length)", forHTTPHeaderField: "Content-Length")
            request.HTTPBody = b
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
    public let attachments: [Attachment] = []
    public var imageAttachments: [Attachment] { return attachments.filter{$0.contentType.hasPrefix("image/")} }
    
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
        self.attachments = compact(json["attachment"].arrayValue.map{Attachment($0)})
    }
    
    public var description: String {
        return "Message([\(id)] \(createdAt) @\(screenName)(\(name)) ![\(profileImageURL)]: \(body) \(htmlBody))"
    }
}


public class Attachment: ResponseItem, Printable {
    public let url: String = "" // can be relative URL
    public let filename: String = ""
    public let contentType: String = ""
    
    public required init?(_ json: SwiftyJSON.JSON) {
        let url = json["url"].string
        let filename = json["filename"].string
        let contentType = json["content_type"].string
        
        if compact([url, filename, contentType]).count == 0 {
            return nil
        }
        
        self.url = url!
        self.filename = filename!
        self.contentType = contentType!
    }
    
    public var description: String {
        return "Attachment([\(contentType)] \(filename) at \(url))"
    }
}


public class RawJSON: ResponseItem {
    public let json: SwiftyJSON.JSON
    public required init?(_ json: SwiftyJSON.JSON) {
        self.json = json
    }
}


public class Nothing: ResponseItem {
    public required init?(_ json: SwiftyJSON.JSON) {
    }
}


private func compact<T>(array: [T?]) -> [T] {
    return array.reduce([]){ a, b in b.map{a + [$0]} ?? a}
}

