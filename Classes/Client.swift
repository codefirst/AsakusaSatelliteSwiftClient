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
    public let rootURL: String
    var apiBaseURL: String { return "\(rootURL)/api/v1" }
    let apiKey: String?
    
    public convenience init(apiKey: String?) {
        self.init(rootURL: "https://asakusa-satellite.herokuapp.com", apiKey: apiKey)
    }
    
    public init(rootURL: String, apiKey: String?) {
        self.rootURL = rootURL
        self.apiKey = apiKey
        
        // remove all AasakusaSatellite cookies
        // make sure AsakusaSatellite cause error result with invalid apiKey
        removeCookies()
    }
    
    private func removeCookies() {
        let cs = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in (cs.cookiesForURL(NSURL(string: rootURL)!) as? [NSHTTPCookie]) ?? [] {
            cs.deleteCookie(cookie)
        }
    }
    
    // MARK: - public APIs
    
    public func serviceInfo(completion: Response<ServiceInfo> -> Void) {
        request(Endpoint.ServiceInfo, completion: completion)
    }
    
    public func user(completion: Response<User> -> Void) {
        request(Endpoint.User, completion: completion)
    }
    
    public func roomList(completion: Response<Many<Room>> -> Void) {
        request(Endpoint.RoomList, completion: completion)
    }
    
    public func postMessage(message: String, roomID: String, files: [String], completion: Response<PostMessage> -> Void) {
        request(Endpoint.PostMessage(message: message, roomID: roomID, files: files), completion: completion)
    }
    public func messageList(roomID: String, count: Int?, sinceID: String?, untilID: String?, order: SortOrder?, completion: Response<Many<Message>> -> Void) {
        request(Endpoint.MessageList(roomID: roomID, count: count, sinceID: sinceID, untilID: untilID, order: order), completion: completion)
    }
    
    public func addDevice(deviceToken: NSData, name: String, completion: Response<Nothing> -> Void) {
        request(Endpoint.AddDevice(deviceToken: deviceToken, name: name), {$0.validate(statusCode: [200])}, completion: completion)
    }
    
    public func messagePusher(roomID: String, completion: (MessagePusherClient? -> Void)) {
        serviceInfo { response in
            switch response {
            case .Success(let serviceInfo):
                if let engine = MessagePusherClient.Engine(messagePusher: serviceInfo().messagePusher) {
                    completion(MessagePusherClient(engine: engine, roomID: roomID))
                } else {
                    completion(nil)
                }
            case .Failure(let error):
                completion(nil)
            }
        }
    }
    
    // MARK: -
    
    private func request<T: ResponseItem>(endpoint: Endpoint, requestModifier: (Request -> Request) = {$0}, completion: Response<T> -> Void) {
        requestModifier(Alamofire.request(endpoint.URLRequest(apiBaseURL, apiKey: apiKey))).responseJSON { (request, response, object, error) -> Void in
            if object == nil || error != nil {
                NSLog("failure in Client.request(\(endpoint)): \(error)")
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


public enum SortOrder: String {
    case Asc = "asc"
    case Desc = "desc"
}

