//
//  MobiledocKit
//

import Foundation

enum MobiledocErrors: Error {
    case missingMarkdown
}

struct Mobiledoc: Codable {
    let version: String
    let markups: [String]
    let atoms = [String]()
    let cards: [MobiledocMarkdownCard]
    let sections: [MobiledocSection]
    
    var contents: String {
        return sections.map({ (section) -> String in
            if let section = section as? MobiledocMarkerSection {
                return section.markdown
            }
            if let section = section as? MobiledocImageSection {
                return "![](\(section.src)"
            }
            if let section = section as? MobiledocCardSection {
                return cards[section.cardIndex].markdown
            }
            if let section = section as? MobiledocListSection {
                return section.markdown
            }
            return ""
        }).joined(separator: "\n")
    }
    
    enum CodingKeys: CodingKey {
        case version
        case markups
        case atoms
        case cards
        case sections
    }
    
    init(version: String, markups: [String], cards: [MobiledocMarkdownCard], sections: [MobiledocSection]) {
        self.version = version
        self.markups = markups
        self.cards = cards
        self.sections = sections
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        version = try container.decode(String.self, forKey: .version)
        cards = try container.decode([MobiledocMarkdownCard].self, forKey: .cards)
        markups = try container.decode([String].self, forKey: .markups)
        
        var parsed = [MobiledocSection]()
        var sectionsContainer = try container.nestedUnkeyedContainer(forKey: .sections)
        while !sectionsContainer.isAtEnd {
            var sectionContainer = try sectionsContainer.nestedUnkeyedContainer()
            let sectionType = try sectionContainer.decode(MobiledocSectionType.self)
            switch sectionType {
            case .card:
                let index = try sectionContainer.decode(Int.self)
                parsed.append(MobiledocCardSection(cardIndex: index))
            case .image:
                let src = try sectionContainer.decode(String.self)
                parsed.append(MobiledocImageSection(src: src))
            case .markup:
                let tagName = try sectionContainer.decode(String.self)
                let markers = try sectionContainer.decode([MobiledocMarker].self)
                parsed.append(MobiledocMarkerSection(tagName: tagName, markers: markers))
            case .list:
                let tagName = try sectionContainer.decode(String.self)
                let markers = try sectionContainer.decode([MobiledocMarker].self)
                parsed.append(MobiledocListSection(tagName: tagName, markers: markers))
            }
        }
        sections = parsed
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(markups, forKey: .markups)
        try container.encode(atoms, forKey: .atoms)
        try container.encode(cards, forKey: .cards)
        
        var sectionsContainer = container.nestedUnkeyedContainer(forKey: .sections)
        for section in sections {
            
            var sectionContainer = sectionsContainer.nestedUnkeyedContainer()
            
            if let section = section as? MobiledocImageSection {
                try sectionContainer.encode(MobiledocSectionType.image)
                try sectionContainer.encode(section.src)
            }
            if let section = section as? MobiledocMarkerSection {
                try sectionContainer.encode(MobiledocSectionType.markup)
                try sectionContainer.encode(section.tagName)
                try sectionContainer.encode(section.markers)
            }
            if let section = section as? MobiledocCardSection {
                try sectionContainer.encode(MobiledocSectionType.card)
                try sectionContainer.encode(section.cardIndex)
            }
        }
    }
}

enum MobiledocSectionTagName: String {
    case aside
    case blockquote
    case h1
    case h2
    case h3
    case h4
    case h5
    case h6
    case p
}

enum MobiledocSectionType: Int, Codable {
    case markup = 1
    case image = 2
    case list = 3
    case card = 10
}

struct MobiledocMarkdownCard: Codable {
    let markdown: String
    
    init(_ markdown: String) {
        self.markdown = markdown
    }
    
    init(from decoder: Decoder) throws {
        var values = try decoder.unkeyedContainer()
        let title = try values.decode(String.self)
        if title != "card-markdown" && title != "markdown" {
            throw MobiledocErrors.missingMarkdown
        }
        let realStuff = try values.decode([String:String].self)
        
        self.markdown = realStuff["markdown"]!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try  container.encode("card-markdown")
        try container.encode(["cardName": "card-markdown", "markdown": markdown])
    }
}

// Sections

protocol MobiledocSection {}

struct MobiledocListSection: MobiledocSection {
    let tagName: String
    let markers: [MobiledocMarker]
    
    var markdown: String {
        return markers.map({ "* \($0.value)" }).joined(separator: "\n")
    }
}

struct MobiledocImageSection: MobiledocSection {
    let src: String
}

struct MobiledocCardSection: MobiledocSection {
    let cardIndex: Int
}

struct MobiledocMarkerSection: MobiledocSection {
    var markdown: String {
        return markers.map({ $0.value }).joined(separator: "\n")
    }
    
    let tagName: String
    let markers: [MobiledocMarker]
}

struct MobiledocMarker: Codable {
    let textType: Int
    let markupIndexes: [Int]
    let numberOfClosedMarkups: Int
    let value: String
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        textType = try container.decode(Int.self)
        markupIndexes = try container.decode([Int].self)
        numberOfClosedMarkups = try container.decode(Int.self)
        value = try container.decode(String.self)
    }
}
