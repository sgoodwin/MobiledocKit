//
//  MobiledocKit
//

import Foundation

public enum MobiledocErrors: Error {
    case missingMarkdown
}

public struct Mobiledoc: Codable {
    public let version: String
    public let markups: [String]
    public let atoms = [String]()
    public let cards: [MobiledocMarkdownCard]
    public let sections: [MobiledocSection]
    
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
    
    public init(from decoder: Decoder) throws {
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
                let tagName = try sectionContainer.decode(MobiledocSectionTagName.self)
                let markers = try sectionContainer.decode([MobiledocMarker].self)
                parsed.append(MobiledocMarkerSection(tagName: tagName, markers: markers))
            case .list:
                let tagName = try sectionContainer.decode(MobiledocSectionTagName.self)
                let markers = try sectionContainer.decode([MobiledocMarker].self)
                parsed.append(MobiledocListSection(tagName: tagName, markers: markers))
            }
        }
        sections = parsed
    }
    
    public func encode(to encoder: Encoder) throws {
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
                try sectionContainer.encode(section.tagName.rawValue)
                try sectionContainer.encode(section.markers)
            }
            if let section = section as? MobiledocCardSection {
                try sectionContainer.encode(MobiledocSectionType.card)
                try sectionContainer.encode(section.cardIndex)
            }
        }
    }
}

public enum MobiledocSectionTagName: String, Codable {
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

public struct MobiledocMarkdownCard: Codable {
    public let markdown: String
    
    public init(_ markdown: String) {
        self.markdown = markdown
    }
    
    public init(from decoder: Decoder) throws {
        var values = try decoder.unkeyedContainer()
        let title = try values.decode(String.self)
        if title != "card-markdown" && title != "markdown" {
            throw MobiledocErrors.missingMarkdown
        }
        let realStuff = try values.decode([String:String].self)
        
        self.markdown = realStuff["markdown"]!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try  container.encode("card-markdown")
        try container.encode(["cardName": "card-markdown", "markdown": markdown])
    }
}

// Sections

public protocol MobiledocSection {}

public struct MobiledocListSection: MobiledocSection {
    public let tagName: MobiledocSectionTagName
    public let markers: [MobiledocMarker]
}

public struct MobiledocImageSection: MobiledocSection {
    public let src: String
}

public struct MobiledocCardSection: MobiledocSection {
    public let cardIndex: Int
}

public struct MobiledocMarkerSection: MobiledocSection {
    public let tagName: MobiledocSectionTagName
    public let markers: [MobiledocMarker]
}

public struct MobiledocMarker: Codable {
    public let textType: Int
    public let markupIndexes: [Int]
    public let numberOfClosedMarkups: Int
    public let value: String
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        textType = try container.decode(Int.self)
        markupIndexes = try container.decode([Int].self)
        numberOfClosedMarkups = try container.decode(Int.self)
        value = try container.decode(String.self)
    }
}
