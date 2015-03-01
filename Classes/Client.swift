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
    public init() {
        
    }
    
    public func request(endpoint: Endpoint, handler: (string: String?) -> Void) -> Void {
        Alamofire.request(endpoint)
            .responseString { (request, response, string, error) -> Void in
                handler(string: string)
        }
    }
}
