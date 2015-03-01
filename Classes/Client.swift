//
//  Client.swift
//  
//
//  Created by BAN Jun on 2015/03/01.
//
//

import Foundation
import Alamofire
import SwiftyJSON


public class Client {
    let baseURL: String
    
    public convenience init() {
        self.init(baseURL: "http://asakusa-satellite.org/api/v1")
    }
    
    public init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    public func request(endpoint: Endpoint) -> Request {
        return Alamofire.request(endpoint.URLRequest(baseURL))
    }
}


public enum Response<T> {
    case Success(@autoclosure() -> T) // workaround for Swift compiler error
    case Failure(NSError?)
}


public extension Alamofire.Request {
    func responseAsakusaSatellite(completion: AsakusaSatelliteSwiftClient.Response<SwiftyJSON.JSON> -> Void) -> Self {
        return responseJSON { (request, response, object, error) -> Void in
            if object == nil || error != nil {
                NSLog("failure in responseAsakusaSatellite: \(error)")
                completion(.Failure(error))
            } else {
                let json = SwiftyJSON.JSON(object!)
                completion(.Success(json))
            }
        }
    }
    
    func responseServiceInfo(completion: Response<ServiceInfo> -> Void) -> Self {
        return responseAsakusaSatellite { responseAS in
            switch responseAS {
            case .Success(let json):
                completion(.Success(ServiceInfo(json())))
            case .Failure(let e):
                completion(.Failure(e))
            }
        }
    }
}
