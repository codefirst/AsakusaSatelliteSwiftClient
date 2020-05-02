//
//  MessageSpec.swift
//  AsakusaSatelliteSwiftClientExample
//
//  Created by BAN Jun on 2015/07/20.
//  Copyright © 2015年 codefirst. All rights reserved.
//

import AsakusaSatellite
import Foundation
import Quick
import Nimble


private func testDataPath(_ subpath: String) -> String {
    let s = subpath as NSString
    return Bundle(for: MessageSpec.self).path(forResource: (s.lastPathComponent as NSString).deletingPathExtension,
                                              ofType: s.pathExtension,
                                              inDirectory: s.deletingLastPathComponent)!
}


class MessageSpec: QuickSpec {
    override func spec() {
        describe ("load from json") {
            it ("load from message.json") {
                guard let m = try? Message(file: testDataPath("message.json")) else { return fail() }
                expect(m.body).to(equal("example message"))
            }
        }
        
        describe ("serialize") {
            let serializedFile = (NSTemporaryDirectory() as NSString).appendingPathComponent("serialized.json")
            
            beforeEach {
                do {try FileManager.default.removeItem(atPath: serializedFile)} catch _ {}
            }
            
            it ("serialize to file and deserialize from it") {
                do {
                    let m1 = (try Message.decoder.decode(Message.self, from: """
                    {
                    "id": "id",
                    "name": "name",
                    "screen_name": "screen_name",
                    "body": "body",
                    "html_body": "html_body",
                    "profile_image_url": "http://example.com/example.png",
                    "created_at": "2015-12-31 23:59:59+0900"
                    }
                    """.data(using: .utf8)!
                        ))
                    
                    _ = m1.saveToFile(serializedFile)
                    
                    let m2 = try Message(file: serializedFile)
                    expect(m2.id).to(equal(m1.id))
                    expect(m2.name).to(equal(m1.name))
                    expect(m2.screen_name).to(equal(m1.screen_name))
                    expect(m2.body).to(equal(m1.body))
                    expect(m2.html_body).to(equal(m1.html_body))
                    expect(m2.profile_image_url).to(equal(m1.profile_image_url))
                    expect(m2.created_at).to(equal(m1.created_at))
                } catch {
                    fail(String(describing: error))
                }
            }
            
            it ("deserialize multiple messages") {
                do {
                    let messages = try [Message](file: testDataPath("messages.json"))
                    let m1 = messages.first
                    let m2 = messages.last
                    
                    expect(m1?.body).to(equal("example message1"))
                    expect(m2?.body).to(equal("example message2"))
                } catch {
                    fail(String(describing: error))
                }
            }
            
            it ("serialize multiple messages") {
                do {
                    let m1 = try Message.decoder.decode(Message.self, from: """
                    {
                    "id": "id",
                    "name": "name",
                    "screen_name": "screen_name",
                    "body": "body1",
                    "html_body": "html_body1",
                    "profile_image_url": "http://example.com/example.png",
                    "created_at": "2015-12-31 23:59:59+0900"
                    }
                    """.data(using: .utf8)!
                    )
                    let m2 = try Message.decoder.decode(Message.self, from: """
                        {
                        "id": "id",
                        "name": "name",
                        "screen_name": "screen_name",
                        "body": "body2",
                        "html_body": "html_body2",
                        "profile_image_url": "http://example.com/example.png",
                        "created_at": "2015-12-31 23:59:59+0900"
                        }
                        """.data(using: .utf8)!
                    )
                    
                    _ = [m1, m2].saveToFile(serializedFile)
                    let messages = try [Message](file: serializedFile)
                    expect(messages.count).to(equal(2))
                    expect(messages.first!.body).to(equal("body1"))
                    expect(messages.last!.body).to(equal("body2"))
                } catch {
                    fail(String(describing: error))
                }
            }
        }
    }
}
