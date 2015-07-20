//
//  MessageSpec.swift
//  AsakusaSatelliteSwiftClientExample
//
//  Created by BAN Jun on 2015/07/20.
//  Copyright © 2015年 codefirst. All rights reserved.
//

import AsakusaSatellite
import SwiftyJSON
import Quick
import Nimble


private func testJSON(basename: String) -> JSON {
    let path = NSBundle(forClass: MessageSpec.self).pathForResource(basename, ofType: "json")!
    return JSON(data: NSData(contentsOfFile: path)!, options: .AllowFragments, error: nil)
}


class MessageSpec: QuickSpec {
    override func spec() {
        describe ("load from json") {
            it ("load from message.json") {
                let m = Message(json: testJSON("message"))
                expect(m).notTo(beNil())
                expect(m!.body).to(equal("example message"))
            }
        }
    }
}
