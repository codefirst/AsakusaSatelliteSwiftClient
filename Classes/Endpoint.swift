//
//  Endpoint.swift
//  
//
//  Created by BAN Jun on 2015/03/01.
//
//

import Foundation
import Alamofire


internal let ASBaseURLString = "http://asakusa-satellite.org/api/v1"


public enum Endpoint: URLRequestConvertible {
    case ServiceInfo
    
    public var URLRequest: NSURLRequest {
        let (path: String, parameters: [String: AnyObject]?) = {
            switch self {
            case .ServiceInfo: return ("/service/info.json", nil)
            }
        }()
        let baseRequest = NSURLRequest(URL: NSURL(string: ASBaseURLString + path)!)
        let (request, error) = Alamofire.ParameterEncoding.URL.encode(baseRequest, parameters: parameters)
        if let e = error {
            NSLog("error during creating request: \(e)")
        }
        return request
    }
    
    public var method: Alamofire.Method {
        return .GET
    }
}
