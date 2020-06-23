
////
//  MobiledocKit
//

import Foundation

extension Bundle {
    static let testBundle: Bundle = {
        let baseBundle = Bundle(for: MarkdownRendererTests.classForCoder())
        return Bundle(path: baseBundle.bundlePath + "/../MobiledocKit_MobiledocKitTests.bundle")!
    }()
} 
