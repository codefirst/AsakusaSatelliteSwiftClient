//
//  Client.swift
//  
//
//  Created by BAN Jun on 2015/03/01.
//
//

import Foundation
import Alamofire


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
