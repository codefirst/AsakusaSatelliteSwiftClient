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
    
    // MARK: - public APIs
    
    public func serviceInfo(completion: Response<ServiceInfo> -> Void) {
        request(Endpoint.ServiceInfo, completion)
    }
    
    // MARK: -
    
    private func request<T: ResponseItem>(endpoint: Endpoint, completion: Response<T> -> Void) {
        Alamofire.request(endpoint.URLRequest(baseURL)).responseJSON { (request, response, object, error) -> Void in
            if object == nil || error != nil {
                NSLog("failure in Client.call(\(endpoint)): \(error)")
                completion(.Failure(error))
            } else {
                self.completeWithResponse(response, object!, error, completion)
            }
        }
    }
    
    private func completeWithResponse<T: ResponseItem>(response: NSHTTPURLResponse?, _ jsonObject: AnyObject, _ error: NSError?, completion: Response<T> -> Void) {
        if let responseItem = T(SwiftyJSON.JSON(jsonObject)) {
            completion(Response.Success(responseItem))
        } else {
            NSLog("failure in completeWithResponse")
            completion(.Failure(error))
        }
    }
}


public enum Response<T> {
    case Success(@autoclosure() -> T) // workaround for Swift compiler error
    case Failure(NSError?)
}

