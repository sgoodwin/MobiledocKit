////
//  MobiledocKit
//

import Foundation

public func render(_ doc: Mobiledoc) -> String {
    return doc.sections.map({ (section) -> String in
        if let section = section as? MobiledocMarkerSection {
            return section.markers.map({ $0.value }).joined(separator: "\n")
        }
        if let section = section as? MobiledocImageSection {
            return "![](\(section.src)"
        }
        if let section = section as? MobiledocCardSection {
            return doc.cards[section.cardIndex].markdown
        }
        if let section = section as? MobiledocListSection {
            return section.markers.map({ "* \($0.value)" }).joined(separator: "\n")
        }
        return ""
    }).joined(separator: "\n")
}
