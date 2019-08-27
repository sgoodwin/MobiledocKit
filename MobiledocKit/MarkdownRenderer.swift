////
//  MobiledocKit
//

import Foundation

public struct MarkdownRenderer {
    public init() {}
    
    func startText(for markup: TagName, attributes: [String]? = nil) -> String {
        switch markup {
        case .b:
            return "*"
        case .i:
            return "_"
        case .h1:
            return "#"
        case .h2:
            return "##"
        case .aside:
            return "<aside>"
        case .blockquote:
            return "<blockquote>"
        case .h3:
            return "###"
        case .h4:
            return "####"
        case .h5:
            return "#####"
        case .h6:
            return "######"
        case .p:
            return ""
        case .a:
            if let _ = attributes {
                return "["
            } else {
                return ""
            }
        case .em:
            return "*"
        }
    }
    func endText(for markup: TagName, attributes: [String]? = nil) -> String {
        switch markup {
        case .b:
            return "*"
        case .i:
            return "_"
        case .aside:
            return "</aside>"
        case .blockquote:
            return "</blockquote>"
        case .a:
            if let attributes = attributes {
                return "](\(attributes[1]))"
            } else {
                return ""
            }
        case .em:
            return "*"
        default:
            return ""
        }
    }
    
    public func render(_ doc: Mobiledoc) -> String {
        return doc.sections.compactMap({ (section) -> String? in
            if let section = section as? MarkerSection {
                let initialMarkup = section.tagName
                var openMarkers = [MobiledocMarkup(initialMarkup)]
                
                var text = startText(for: initialMarkup)
                
                for marker in section.markers {
                    for index in marker.markupIndexes {
                        let openMarker = doc.markups[index]
                        openMarkers.append(openMarker)
                        text.append(startText(for: openMarker.tagName, attributes: openMarker.attributes))
                    }
                    
                    text.append(marker.displayValue(doc.atoms))
                    
                    for _ in 0..<marker.numberOfClosedMarkups {
                        let marker = openMarkers.popLast()!
                        text.append(endText(for: marker.tagName, attributes: marker.attributes))
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
