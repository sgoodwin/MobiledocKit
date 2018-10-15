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
    public let cards: [MarkdownCard]
    public let sections: [Section]
    
    enum CodingKeys: CodingKey {
        case version
        case markups
        case atoms
        case cards
        case sections
    }
    
    public init(version: String, markups: [String], cards: [MarkdownCard], sections: [Section]) {
        self.version = version
        self.markups = markups
        self.cards = cards
        self.sections = sections
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        version = try container.decode(String.self, forKey: .version)
        cards = try container.decode([MarkdownCard].self, forKey: .cards)
        markups = try container.decode([String].self, forKey: .markups)
        
        var parsed = [Section]()
        var sectionsContainer = try container.nestedUnkeyedContainer(forKey: .sections)
        while !sectionsContainer.isAtEnd {
            var sectionContainer = try sectionsContainer.nestedUnkeyedContainer()
            let sectionType = try sectionContainer.decode(SectionType.self)
            switch sectionType {
            case .card:
                let index = try sectionContainer.decode(Int.self)
                parsed.append(CardSection(cardIndex: index))
            case .image:
                let src = try sectionContainer.decode(String.self)
                parsed.append(ImageSection(src: src))
            case .markup:
                let tagName = try sectionContainer.decode(SectionTagName.self)
                let markers = try sectionContainer.decode([Marker].self)
                parsed.append(MarkerSection(tagName: tagName, markers: markers))
            case .list:
                let tagName = try sectionContainer.decode(SectionTagName.self)
                let markers = try sectionContainer.decode([Marker].self)
                parsed.append(ListSection(tagName: tagName, markers: markers))
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
            
            if let section = section as? ImageSection {
                try sectionContainer.encode(SectionType.image)
                try sectionContainer.encode(section.src)
            }
            if let section = section as? MarkerSection {
                try sectionContainer.encode(SectionType.markup)
                try sectionContainer.encode(section.tagName.rawValue)
                try sectionContainer.encode(section.markers)
            }
            if let section = section as? CardSection {
                try sectionContainer.encode(SectionType.card)
                try sectionContainer.encode(section.cardIndex)
            }
        }
    }
}

public enum SectionTagName: String, Codable {
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

enum SectionType: Int, Codable {
    case markup = 1
    case image = 2
    case list = 3
    case card = 10
}

public struct MarkdownCard: Codable {
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

public protocol Section {}

public struct ListSection: Section {
    public let tagName: SectionTagName
    public let markers: [Marker]
    
    public init(tagName: SectionTagName, markers: [Marker]) {
        self.tagName = tagName
        self.markers = markers
    }
}

public struct ImageSection: Section {
    public let src: String
    
    public init(src: String) {
        self.src = src
    }
}

public struct CardSection: Section {
    public let cardIndex: Int
    
    public init(cardIndex: Int) {
        self.cardIndex = cardIndex
    }
}

public struct MarkerSection: Section {
    public let tagName: SectionTagName
    public let markers: [Marker]
    
    public init(tagName: SectionTagName, markers: [Marker]) {
        self.tagName = tagName
        self.markers = markers
    }
}

public struct Marker: Codable {
    public let textType: Int
    public let markupIndexes: [Int]
    public let numberOfClosedMarkups: Int
    public let value: String
    
    public init(textType: Int, markupIndexes: [Int], numberOfClosedMarkups: Int, value: String) {
        self.textType = textType
        self.markupIndexes = markupIndexes
        self.numberOfClosedMarkups = numberOfClosedMarkups
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        textType = try container.decode(Int.self)
        markupIndexes = try container.decode([Int].self)
        numberOfClosedMarkups = try container.decode(Int.self)
        value = try container.decode(String.self)
    }
}
