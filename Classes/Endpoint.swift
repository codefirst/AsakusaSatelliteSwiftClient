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


public protocol Requestable {
    var method: Alamofire.Method { get }
    var path: String { get }
    typealias ResponseItem: Any
    
    func URLRequest(baseURL: String) -> NSURLRequest
    func responseFromJSON(request: NSURLRequest, response: NSHTTPURLResponse?, object: AnyObject?, error: NSError?) -> ResponseItem?
}

public class Endpoint {
    public class ServiceInfo: Requestable {
        public let method = Method.GET
        public let path = "/service/info.json"
        public typealias ResponseItem = AsakusaSatelliteSwiftClient.ServiceInfo
        
        public init() {}
        
        public func URLRequest(baseURL: String) -> NSURLRequest {
            return Endpoint.URLRequest(baseURL, method: method, path: path, parameters: nil)
        }
        
        public func responseFromJSON(request: NSURLRequest, response: NSHTTPURLResponse?, object: AnyObject?, error: NSError?) -> ResponseItem? {
            if let json = object as? NSDictionary {
                return AsakusaSatelliteSwiftClient.ServiceInfo(SwiftyJSON.JSON(json))
            }
            return nil
        }
    }
    
    class func URLRequest(baseURL: String, method: Alamofire.Method, path: String, parameters: [String: AnyObject]?) -> NSURLRequest {
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
