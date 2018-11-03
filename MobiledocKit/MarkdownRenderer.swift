////
//  MobiledocKit
//

import Foundation

public func renderMarkdown(_ doc: Mobiledoc) -> String {
    return doc.sections.compactMap({ (section) -> String? in
        if let section = section as? MarkerSection {
            return section.markers.map({ $0.value }).joined(separator: "\n")
        }
        if let section = section as? ImageSection {
            return "![](\(section.src))\n"
        }
        if let section = section as? CardSection {
            let card = doc.cards[section.cardIndex]
            switch card.title {
                /*
                This is where we add support for rendering other kinds of cards.
                there could be any number of cards and I have no idea what other kinds
                people use.
                 */
            case "markdown":
                return card.values["markdown"]?.appending("\n")
            default:
                return nil
            }
        }
        if let section = section as? ListSection {
            return section.markers.map({ "- \($0.value)" }).joined(separator: "\n")
        }
        return ""
    }).joined(separator: "\n").appending("\n")
}
