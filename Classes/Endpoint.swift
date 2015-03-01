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
    
    func URLRequest(baseURL: String) -> NSURLRequest {
        let (method: Alamofire.Method, path: String, parameters: [String: AnyObject]?) = {
            switch self {
            case .ServiceInfo: return (.GET, "/service/info.json", nil)
            }
        }()
        return Endpoint.URLRequest(baseURL, method: method, path: path, parameters: parameters)
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
