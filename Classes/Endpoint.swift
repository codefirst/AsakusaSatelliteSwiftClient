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
    
    public func URLRequest(baseURL: String) -> NSURLRequest {
        let (method: Alamofire.Method, path: String, parameters: [String: AnyObject]?) = {
            switch self {
            case .ServiceInfo: return (.GET, "/service/info.json", nil)
            }
        }()
        let baseRequest = NSMutableURLRequest(URL: NSURL(string: baseURL + path)!)
        baseRequest.HTTPMethod = method.rawValue
        let (request, error) = Alamofire.ParameterEncoding.URL.encode(baseRequest, parameters: parameters)
        if let e = error {
            NSLog("error during creating request: \(e)")
        }
        return request
    }
}


public class ServiceInfo {
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
    
    init(_ json: SwiftyJSON.JSON) {
        messagePusher = MessagePusher(json["message_pusher"])
    }
}
