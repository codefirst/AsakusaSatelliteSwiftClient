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
    case serviceInfo
    case user
    case roomList
    case postMessage(message: String, roomID: String, files: [String])
    case messageList(roomID: String, count: Int?, sinceID: String?, untilID: String?, order: SortOrder?)
    case addDevice(deviceToken: Data, name: String)
    
    func URLRequest(_ baseURL: String, apiKey: String?) -> Foundation.URLRequest {
        let (method, path, parameters, formData, requiresApiKey) = { () -> (HTTPMethod, String, [String: Any]?, MultipartFormData?, Bool) in
            switch self {
            case .serviceInfo: return (.get, "/service/info.json", nil, nil, false)
            case .user: return (.get, "/user.json", nil, nil, true)
            case .roomList: return (.get, "/room/list.json", nil, nil, true)
            case let .postMessage(message, roomID, files):
                var formData: MultipartFormData?
                
                if files.count > 0 {
                    formData = MultipartFormData()
                    for (i, f) in files.enumerated() {
                        guard let data = try? Data(contentsOf: URL(fileURLWithPath: f)) else { continue }
                        let sequenceNumber = i > 0 ? "-\(i)" : ""
                        let ext = (f as NSString).pathExtension
                        let filename = "AsakusaSat\(sequenceNumber).\(ext)"
                        let mimeType: String = UTI(filenameExtension: ext)?.mimeType ?? "application/octet-stream"

                        formData?.append(data, withName: "files[\(filename)]", fileName: filename, mimeType: mimeType)
                    }
                }
                return (.post, "/message.json", ["room_id": roomID, "message": message], formData, true)
            case let .messageList(roomID, count, sinceID, untilID, order):
                var params = [String: Any]()
                params["room_id"] = roomID
                params["count"] = count
                params["since_id"] = sinceID
                if let untilID = untilID { params["until_id"] = untilID } // workaround for Xcode 7b3: "" is set when untilID = nil
                params["order"] = order?.rawValue
                return (.get, "/message/list.json", params, nil, true)
            case let .addDevice(deviceToken, name):
                return (.post, "/user/add_device", ["device": deviceToken.description, "name": name], nil, true)
            }
            }()
        
        var params = parameters ?? [:]
        if requiresApiKey {
            params["api_key"] = apiKey as AnyObject?
        }
        
        return Endpoint.URLRequest(baseURL, method: method, path: path, parameters: params, formData: formData)
    }

    static func URLRequest(_ baseURL: String, method: HTTPMethod, path: String, parameters: [String: Any]?, formData: MultipartFormData?) -> URLRequest {
        let urlRequestWithParams: URLRequest = {
            var getRequest = Foundation.URLRequest(url: URL(string: baseURL)!.appendingPathComponent(path))
            getRequest.httpMethod = HTTPMethod.get.rawValue
            guard let request = try? Alamofire.URLEncoding(destination: .queryString).encode(getRequest, with: parameters) else {
                NSLog("%@", "error during creating request: ")
                return Foundation.URLRequest(url: URL(string: baseURL)!.appendingPathComponent(path))
            }
            return request
            }()
        
        var request = Foundation.URLRequest(url: urlRequestWithParams.url!)
        request.httpMethod = method.rawValue
        
        if let formData = formData {
            do {
                try request.httpBody = formData.encode()
                request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
            } catch _ {
                
            }
        }
        
        return request
    }
    
    func modifyJSON(_ json: JSON) -> JSON {
        var json = json
        switch self {
        case .messageList(_, _, _, _, .some(.Asc)):
            // link messages in a sequence using prevID
            for i in 1..<(json.count) {
                json[i]["prev_id"] = json[i - 1]["id"]
            }
        case .messageList(_, _, _, _, .some(.Desc)):
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


