//
//  Endpoint.swift
//  
//
//  Created by BAN Jun on 2015/03/01.
//
//

import Foundation
import Alamofire
import UTIKit


private let kBoundary = "AsakusaSatellite-boundary-db1235c63fb8967513000351c0482df321505fb7"


public enum Endpoint {
    case ServiceInfo
    case User
    case RoomList
    case PostMessage(message: String, roomID: String, files: [String])
    case MessageList(roomID: String, count: Int?, sinceID: String?, untilID: String?, order: SortOrder?)
    case AddDevice(deviceToken: NSData, name: String)
    
    func URLRequest(baseURL: String, apiKey: String?) -> NSURLRequest {
        let (method, path, parameters, body, requiresApiKey) = { () -> (Alamofire.Method, String, [String: AnyObject]?, NSData?, Bool) in
            switch self {
            case .ServiceInfo: return (.GET, "/service/info.json", nil, nil, false)
            case .User: return (.GET, "/user.json", nil, nil, true)
            case .RoomList: return (.GET, "/room/list.json", nil, nil, true)
            case let .PostMessage(message, roomID, files):
                var body: NSMutableData!
                if files.count > 0 {
                    // add multipart (currently Alamofire does not have multipart API)
                    body = NSMutableData()
                    let crlf = "\r\n"
                    let crlfData = crlf.dataUsingEncoding(NSUTF8StringEncoding)!
                    var index = 0
                    for f in files {
                        if let data = NSData(contentsOfFile: f) {
                            let sequenceNumber = index > 0 ? "-\(index)" : ""
                            let filename = "AsakusaSat\(sequenceNumber).\(f.pathExtension)"
                            let mimeType: String = UTI(filenameExtension: f.pathExtension).MIMEType ?? "application/octet-stream"
                            
                            body.appendData("--\(kBoundary)\(crlf)".dataUsingEncoding(NSUTF8StringEncoding)!)
                            body.appendData("Content-Disposition: form-data; name=\"files[\(filename)]\"; filename=\"\(filename)\"\(crlf)".dataUsingEncoding(NSUTF8StringEncoding)!)
                            body.appendData("Content-Type: \(mimeType)\(crlf)".dataUsingEncoding(NSUTF8StringEncoding)!)
                            body.appendData(crlfData)
                            body.appendData(data)
                            body.appendData(crlfData)
                        }
                        ++index
                    }
                    body.appendData("--\(kBoundary)--\(crlf)".dataUsingEncoding(NSUTF8StringEncoding)!)
                }
                return (.POST, "/message.json", ["room_id": roomID, "message": message], body, true)
            case let .MessageList(roomID, count, sinceID, untilID, order):
                var params = [String: AnyObject]()
                params["room_id"] = roomID
                params["count"] = count
                params["since_id"] = sinceID
                if let untilID = untilID { params["until_id"] = untilID } // workaround for Xcode 7b3: "" is set when untilID = nil
                params["order"] = order?.rawValue
                return (.GET, "/message/list.json", params, nil, true)
            case let .AddDevice(deviceToken, name):
                return (.POST, "/user/add_device", ["device": deviceToken.description, "name": name], nil, true)
            }
            }()
        
        var params = parameters ?? [:]
        if requiresApiKey {
            params["api_key"] = apiKey
        }
        
        return Endpoint.URLRequest(baseURL, method: method, path: path, parameters: params, body: body)
    }
    
    static func URLRequest(baseURL: String, method: Alamofire.Method, path: String, parameters: [String: AnyObject]?, body: NSData?) -> NSURLRequest {
        let urlRequestWithParams: NSURLRequest = {
            let getRequest = NSMutableURLRequest(URL: NSURL(string: baseURL.stringByAppendingPathComponent(path))!)
            getRequest.HTTPMethod = Method.GET.rawValue
            let (request, error) = Alamofire.ParameterEncoding.URL.encode(getRequest, parameters: parameters) // Alamofire encode params into body when POST
            if let e = error {
                NSLog("error during creating request: \(e)")
            }
            return request
            }()
        
        let request = NSMutableURLRequest(URL: urlRequestWithParams.URL!)
        request.HTTPMethod = method.rawValue
        if let b = body {
            request.addValue("multipart/form-data; boundary=\(kBoundary)", forHTTPHeaderField: "Content-Type")
            request.addValue("\(b.length)", forHTTPHeaderField: "Content-Length")
            request.HTTPBody = b
        }
        
        return request
    }
}


