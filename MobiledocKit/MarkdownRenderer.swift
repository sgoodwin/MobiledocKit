////
//  MobiledocKit
//

import Foundation

public func render(_ doc: Mobiledoc) -> String {
    return doc.sections.map({ (section) -> String in
        if let section = section as? MarkerSection {
            return section.markers.map({ $0.value }).joined(separator: "\n")
        }
        if let section = section as? ImageSection {
            return "![](\(section.src)"
        }
        if let section = section as? CardSection {
            return doc.cards[section.cardIndex].markdown
        }
        if let section = section as? ListSection {
            return section.markers.map({ "* \($0.value)" }).joined(separator: "\n")
        }
        return ""
    }).joined(separator: "\n")
}
