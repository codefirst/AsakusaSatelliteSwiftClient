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


open class Client {
    open let rootURL: String
    var apiBaseURL: String { return rootURL.appendingFormat("api/v1") }
    let apiKey: String?
    
    public convenience init(apiKey: String?) {
        self.init(rootURL: "https://asakusa-satellite.herokuapp.com/", apiKey: apiKey)
    }
    
    public init(rootURL: String, apiKey: String?) {
        self.rootURL = rootURL
        self.apiKey = apiKey
        
        // remove all AasakusaSatellite cookies
        // make sure AsakusaSatellite cause error result with invalid apiKey
        removeCookies()
    }
    
    private func removeCookies() {
        AsakusaSatellite.removeCookiesForURL(URL(string: rootURL)!)
    }
    
    // MARK: - public APIs

    open func serviceInfo(_ completion: @escaping (Response<ServiceInfo>) -> Void) {
        request(Endpoint.serviceInfo, completion: completion)
    }
    
    open func user(_ completion: @escaping (Response<User>) -> Void) {
        request(Endpoint.user, completion: completion)
    }
    
    open func roomList(_ completion: @escaping (Response<Many<Room>>) -> Void) {
        request(Endpoint.roomList, completion: completion)
    }
    
    open func postMessage(_ message: String, roomID: String, files: [String], completion: @escaping (Response<PostMessage>) -> Void) {
        request(Endpoint.postMessage(message: message, roomID: roomID, files: files), completion: completion)
    }
    open func messageList(_ roomID: String, count: Int?, sinceID: String?, untilID: String?, order: SortOrder?, completion: @escaping (Response<Many<Message>>) -> Void) {
        request(Endpoint.messageList(roomID: roomID, count: count, sinceID: sinceID, untilID: untilID, order: order), completion: completion)
    }
    
    open func addDevice(_ deviceToken: Data, name: String, completion: @escaping (Response<Nothing>) -> Void) {
        request(Endpoint.addDevice(deviceToken: deviceToken, name: name), requestModifier: {$0.validate(statusCode: [200])}, completion: completion)
    }
    
    open func messagePusher(_ roomID: String, completion: @escaping ((MessagePusherClient?) -> Void)) {
        serviceInfo { response in
            switch response {
            case .success(let serviceInfo):
                if let engine = MessagePusherClient.Engine(messagePusher: serviceInfo.messagePusher) {
                    completion(MessagePusherClient(engine: engine, roomID: roomID))
                } else {
                    completion(nil)
                }
            case .failure(_):
                completion(nil)
            }
        }
    }
    
    // MARK: -
    
    private func request<T: APIModel>(_ endpoint: Endpoint, requestModifier: ((DataRequest) -> DataRequest) = {$0}, completion: @escaping (Response<T>) -> Void) {
        requestModifier(Alamofire.request(endpoint.URLRequest(apiBaseURL, apiKey: apiKey))).responseJSON { response in
            switch response.result {
            case .success(let value):
                self.completeWithResponse(response.response, endpoint.modifyJSON(JSON(value)), nil, completion: completion)
            case .failure(let error):
                NSLog("%@", "failure in Client.request(\(endpoint)): \(error)")
                completion(.failure(error as NSError))
            }
        }
    }
    
    private func completeWithResponse<T: APIModel>(_ response: HTTPURLResponse?, _ json: JSON, _ error: NSError?, completion: (Response<T>) -> Void) {
        if let responseItem = T(json: json) {
            completion(Response.success(responseItem))
        } else {
            NSLog("%@", "failure in completeWithResponse")
            completion(.failure(error))
        }
    }
}


public enum Response<T> {
    case success(T)
    case failure(NSError?)
}


public enum SortOrder: String {
    case Asc = "asc"
    case Desc = "desc"
}


internal func removeCookiesForURL(_ URL: Foundation.URL) {
    let cs = HTTPCookieStorage.shared
    for cookie in cs.cookies(for: URL) ?? [] {
        cs.deleteCookie(cookie)
    }
}

