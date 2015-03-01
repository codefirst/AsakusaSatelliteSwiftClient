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
    
    public func call<T: Requestable>(endpoint: T, completion: Response<T.ResponseItem> -> Void)  {
        Alamofire.request(endpoint.URLRequest(baseURL)).responseJSON { (request, response, object, error) -> Void in
            if object == nil || error != nil {
                NSLog("failure in Client.call(\(endpoint)): \(error)")
                completion(.Failure(error))
            } else {
                if let responseItem = endpoint.responseFromJSON(request, response: response, object: object!, error: error) {
                    completion(.Success(responseItem))
                } else {
                    completion(.Failure(error))
                }
            }
        }
    }
}


public enum Response<T> {
    case Success(@autoclosure() -> T) // workaround for Swift compiler error
    case Failure(NSError?)
}

