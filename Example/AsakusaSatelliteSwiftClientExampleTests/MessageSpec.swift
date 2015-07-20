//
//  MessageSpec.swift
//  AsakusaSatelliteSwiftClientExample
//
//  Created by BAN Jun on 2015/07/20.
//  Copyright © 2015年 codefirst. All rights reserved.
//

import AsakusaSatellite
import SwiftyJSON
import Foundation
import Quick
import Nimble


private func testDataPath(subpath: String) -> String {
    return NSBundle(forClass: MessageSpec.self).pathForResource(subpath.lastPathComponent.stringByDeletingPathExtension,
        ofType: subpath.pathExtension,
        inDirectory: subpath.stringByDeletingLastPathComponent)!
}

private func testJSON(subpath: String) -> JSON {
    return JSON(data: NSData(contentsOfFile: testDataPath(subpath))!, options: [], error: nil)
}


class MessageSpec: QuickSpec {
    override func spec() {
        describe ("load from json") {
            it ("load from message.json") {
                guard let m = Message(json: testJSON("message.json")) else { return fail() }
                expect(m.body).to(equal("example message"))
            }
        }
        
        describe ("serialize") {
            it ("serialize to file and deserialize from it") {
                guard let m1 = Message(json: JSON([
                    "id": "id",
                    "name": "name",
                    "screen_name": "screen_name",
                    "body": "body",
                    "html_body": "html_body",
                    "profile_image_url": "http://example.com/example.png",
                    "created_at": "2015-12-31 23:59:59+0900",
                    ])) else { return fail() }
                
                let file = NSTemporaryDirectory().stringByAppendingPathComponent("serialized.json")
                do {try NSFileManager.defaultManager().removeItemAtPath(file)} catch _ {}
                m1.saveToFile(file)
                
                guard let m2 = Message(file: file) else { return fail() }
                expect(m2.id).to(equal(m1.id))
                expect(m2.name).to(equal(m1.name))
                expect(m2.screenName).to(equal(m1.screenName))
                expect(m2.body).to(equal(m1.body))
                expect(m2.htmlBody).to(equal(m1.htmlBody))
                expect(m2.profileImageURL).to(equal(m1.profileImageURL))
                expect(m2.createdAt).to(equal(m1.createdAt))
            }
            
            it ("deserialize multiple messages") {
                guard let messages = Many<Message>(file: testDataPath("messages.json")),
                    m1 = messages.items.first,
                    m2 = messages.items.last else { return fail() }
                
                expect(m1.body).to(equal("example message1"))
                expect(m2.body).to(equal("example message2"))
            }
        }
    }
}
