// To import AsakusaSatellite:
// * Manage Schemes -> enable Pods-AsakusaSatellite
// * Select Pods-AsakusaSatellite > iPhone 6
// * build
// See Also:
// https://developer.apple.com/library/ios/recipes/xcode_help-source_editor/chapters/ImportingaFrameworkIntoaPlayground.html

import XCPlayground
import UIKit
import AsakusaSatellite


let c = Client(apiKey: nil)
c.roomList() { r in
    switch r {
    case .Success(let many):
        let rooms = many().items
        for room in rooms {
            room
        }
    case .Failure(let error):
        error
    }
}

XCPSetExecutionShouldContinueIndefinitely(continueIndefinitely: true)
