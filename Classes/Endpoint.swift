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
    
    func URLRequest(baseURL: String, apiKey: String?) -> NSURLRequest {
        let (method: Alamofire.Method, path: String, parameters: [String: AnyObject]?, requiresApiKey: Bool) = {
            switch self {
            case .ServiceInfo: return (.GET, "/service/info.json", nil, false)
            case .User: return (.GET, "/user.json", nil, true)
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


protocol ResponseItem {
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
