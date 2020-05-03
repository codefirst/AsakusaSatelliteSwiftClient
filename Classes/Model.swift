//
//  Model.swift
//  Pods
//
//  Created by BAN Jun on 2015/07/20.
//
//

import Foundation


public protocol APIModel: Codable {
}

extension APIModel  {
    var jsonString: String? {
        return (try? Self.encoder.encode(self)).flatMap {String(data: $0, encoding: .utf8)}
    }
    
    public func saveToFile(_ path: String) -> Bool {
        do {
            guard let s = jsonString else { return false }
            try s.write(toFile: path, atomically: true, encoding: .utf8)
            return true
        } catch _ {
            return false
        }
    }

    public static var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:SSZZZZ"
        return df
    }

    public static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        return encoder
    }

    public static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
    
    public init(file path: String) throws {
        self = try Self.decoder.decode(Self.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
    }
}

extension Array: APIModel where Element: APIModel {

}


public struct Nothing: APIModel {
}


public struct ServiceInfo: APIModel {
    public struct MessagePusher: APIModel {
        public let name: String?
        public let param: [String: String]
        public var url: String? { return param["url"] }
        public var key: String? { return param["key"] }
    }
    public let message_pusher: MessagePusher
}


public struct User: APIModel {
    public let id: String
    public let name: String
    public let screen_name: String
    public let profile_image_url: String
}


public struct Room: APIModel {
    public let id: String
    public let name: String
    public let owner: User?
    public let members: [User]
    public var ownerAndMembers: [User] {
        return compact([owner]) + members
    }
}


public struct PostMessage: APIModel {
    public let message_id: String
}

public struct Message: APIModel, CustomStringConvertible {
    public let id: String
    public var prev_id: String?
    public let name: String
    public let screen_name: String
    public let body: String
    public let html_body: String
    public let created_at: Date
    public let profile_image_url: String
    public let attachment: [Attachment]?
    public var imageAttachments: [Attachment] { return attachment?.filter{$0.content_type.hasPrefix("image/")} ?? [] }
    
    public var description: String {
        return "Message([\(id) (prev = \(String(describing: prev_id)))] \(created_at) @\(screen_name)(\(name)) ![\(profile_image_url)]: \(body) \(html_body))"
    }
}


public struct Attachment: APIModel, CustomStringConvertible {
    public let url: String // can be relative URL
    public let filename: String
    public let content_type: String
    
    public var description: String {
        return "Attachment([\(content_type)] \(filename) at \(url))"
    }
}


private func compact<T>(_ array: [T?]) -> [T] {
    return array.reduce([]){ a, b in b.map{a + [$0]} ?? a}
}

