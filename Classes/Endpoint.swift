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
import SwiftyJSON


public enum Endpoint {
    case ServiceInfo
    case User
    case RoomList
    case PostMessage(message: String, roomID: String, files: [String])
    case MessageList(roomID: String, count: Int?, sinceID: String?, untilID: String?, order: SortOrder?)
    case AddDevice(deviceToken: NSData, name: String)
    
    func URLRequest(baseURL: String, apiKey: String?) -> NSURLRequest {
        let (method, path, parameters, formData, requiresApiKey) = { () -> (Alamofire.Method, String, [String: AnyObject]?, MultipartFormData?, Bool) in
            switch self {
            case .ServiceInfo: return (.GET, "/service/info.json", nil, nil, false)
            case .User: return (.GET, "/user.json", nil, nil, true)
            case .RoomList: return (.GET, "/room/list.json", nil, nil, true)
            case let .PostMessage(message, roomID, files):
                var formData: MultipartFormData?
                
                if files.count > 0 {
                    formData = MultipartFormData()
                    for (i, f) in files.enumerate() {
                        guard let data = NSData(contentsOfFile: f) else { continue }
                        let sequenceNumber = i > 0 ? "-\(i)" : ""
                        let ext = (f as NSString).pathExtension
                        let filename = "AsakusaSat\(sequenceNumber).\(ext)"
                        let mimeType: String = UTI(filenameExtension: ext).MIMEType ?? "application/octet-stream"
                        
                        formData?.appendBodyPart(data: data, name: "files[\(filename)]", fileName: filename, mimeType: mimeType)
                    }
                }
                return (.POST, "/message.json", ["room_id": roomID, "message": message], formData, true)
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
        
        return Endpoint.URLRequest(baseURL, method: method, path: path, parameters: params, formData: formData)
    }
    
    static func URLRequest(baseURL: String, method: Alamofire.Method, path: String, parameters: [String: AnyObject]?, formData: MultipartFormData?) -> NSURLRequest {
        let urlRequestWithParams: NSURLRequest = {
            let getRequest = NSMutableURLRequest(URL: NSURL(string: (baseURL as NSString).stringByAppendingPathComponent(path))!)
            getRequest.HTTPMethod = Method.GET.rawValue
            let (request, error) = Alamofire.ParameterEncoding.URL.encode(getRequest, parameters: parameters) // Alamofire encode params into body when POST
            if let e = error {
                NSLog("%@", "error during creating request: \(e)")
            }
            return request
            }()
        
        let request = NSMutableURLRequest(URL: urlRequestWithParams.URL!)
        request.HTTPMethod = method.rawValue
        
        if let formData = formData {
            do {
                try request.HTTPBody = formData.encode()
                request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
            } catch _ {
                
            }
        }
        
        return request
    }
    
    func modifyJSON(var json: JSON) -> JSON {
        switch self {
        case .MessageList(_, _, _, _, .Some(.Asc)):
            // link messages in a sequence using prevID
            for i in 1..<(json.count) {
                json[i]["prev_id"] = json[i - 1]["id"]
            }
        case .MessageList(_, _, _, _, .Some(.Desc)):
            // link messages in a sequence using prevID
            for i in 0..<(json.count - 1) {
                json[i]["prev_id"] = json[i + 1]["id"]
            }
        default:
            break
        }
        return json
    }
}


