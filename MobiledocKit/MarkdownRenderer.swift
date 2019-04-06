////
//  MobiledocKit
//

import Foundation

public struct MarkdownRenderer {
    public init() {}
    
    func startText(for markup: String) -> String {
        switch markup {
        case "b":
            return "*"
        case "i":
            return "_"
        case "h1":
            return "#"
        case "h2":
            return "##"
        default:
            return ""
        }
    }
    func endText(for markup: String) -> String {
        switch markup {
        case "b":
            return "*"
        case "i":
            return "_"
        default:
            return ""
        }
    }
    
    public func render(_ doc: Mobiledoc) -> String {
        return doc.sections.compactMap({ (section) -> String? in
            if let section = section as? MarkerSection {
                let initialMarkup = section.tagName.rawValue
                var openMarkers = [initialMarkup]
                
                var text = startText(for: initialMarkup)
                
                for (markerIndex, marker) in section.markers.enumerated() {
                    for index in marker.markupIndexes {
                        let openMarker = doc.markups[index]
                        openMarkers.append(openMarker)
                        text.append(startText(for: openMarker))
                    }
                    
                    text.append(marker.displayValue(doc.atoms))
                    
                    for _ in 0..<marker.numberOfClosedMarkups {
                        let marker = openMarkers.popLast()!
                        text.append(endText(for: marker))
                    }
                    
                    if markerIndex != (section.markers.endIndex-1) {
                        text.append(" ")
                    }
                }
                return text
            }
            if let section = section as? ImageSection {
                return "![\(section.caption ?? "")](\(section.src))\n"
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
                case "card-markdown":
                    return card.values["markdown"]?.appending("\n")
                default:
                    return nil
                }
            }
            if let section = section as? ListSection {
                return section.markers.map({ "- \($0.displayValue(doc.atoms))" }).joined(separator: "\n")
            }
            return ""
        }).joined(separator: "\n").appending("\n")
    }
}
