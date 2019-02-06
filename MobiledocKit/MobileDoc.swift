//
//  MobiledocKit
//

import Foundation

public struct Mobiledoc: Codable, Equatable {
    public let version: String
    public let markups: [String]
    public let atoms: [MobiledocAtom]
    public let cards: [MobiledocCard]
    public let sections: [Section]
    
    enum CodingKeys: CodingKey {
        case version
        case markups
        case atoms
        case cards
        case sections
    }
    
    public init(markups: [String] = [], atoms: [MobiledocAtom] = [], cards: [MobiledocCard] = [], sections: [Section]) {
        self.markups = markups
        self.cards = cards
        self.sections = sections
        self.version = "0.3.1"
        self.atoms = atoms
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        version = try container.decode(String.self, forKey: .version)
        cards = try container.decode([MobiledocCard].self, forKey: .cards)
        markups = try container.decode([String].self, forKey: .markups)
        atoms = try container.decode([MobiledocAtom].self, forKey: .atoms)
        
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
                let tagName = try sectionContainer.decode(ListType.self)
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
            if let section = section as? ListSection {
                try sectionContainer.encode(SectionType.list)
                try sectionContainer.encode(section.tagName.rawValue)
                try sectionContainer.encode(section.markers)
            }
        }
    }
}

extension Mobiledoc {
    public static func == (lhs: Mobiledoc, rhs: Mobiledoc) -> Bool {
        guard lhs.version == rhs.version && lhs.markups == rhs.markups && lhs.atoms == rhs.atoms && lhs.cards == rhs.cards else {
            return false
        }
        
        return lhs.sections.enumerated().reduce(true) { (result, arg1) -> Bool in
            let (offset, lhsSection) = arg1
            let rhsSection = rhs.sections[offset]
            
            if let rhsSection = rhsSection as? ListSection, let lhsSection = lhsSection as? ListSection {
                return result && (rhsSection == lhsSection)
            }
            
            if let rhsSection = rhsSection as? CardSection, let lhsSection = lhsSection as? CardSection {
                return result && (rhsSection == lhsSection)
            }
            
            if let rhsSection = rhsSection as? MarkerSection, let lhsSection = lhsSection as? MarkerSection {
                return result && (rhsSection == lhsSection)
            }
            
            if let rhsSection = rhsSection as? ImageSection, let lhsSection = lhsSection as? ImageSection {
                return result && (rhsSection == lhsSection)
            }
            
            return false
        }
    }
}

public enum SectionTagName: String, Codable, Equatable {
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

enum SectionType: Int, Codable, Equatable {
    case markup = 1
    case image = 2
    case list = 3
    case card = 10
}

public struct MobiledocAtom: Codable, Equatable {
    let name: String
    let text: String
    let payload: [String: String]
    
    public init(name: String, text: String, payload: [String: String]) {
        self.name = name
        self.text = text
        self.payload = payload
    }
    
    public init(from decoder: Decoder) throws {
        var values = try decoder.unkeyedContainer()
        name = try values.decode(String.self)
        text = try values.decode(String.self)
        payload = try values.decode([String:String].self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(name)
        try container.encode(text)
        try container.encode(payload)
    }
}

public struct MobiledocCard: Codable, Equatable {
    public let title: String
    public let values: [String: String]
    
    public init(_ markdown: String) {
        self.title = "markdown"
        self.values = ["markdown": markdown]
    }
    
    public init(title: String, values: [String: String]) {
        self.title = title
        self.values = values
    }
    
    public init(from decoder: Decoder) throws {
        var values = try decoder.unkeyedContainer()
        let title = try values.decode(String.self)
        let realStuff = try values.decode([String:String].self)
        
        self.title = title
        self.values = realStuff
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(title)
        try container.encode(values)
    }
}

// Sections

public protocol Section {}

public enum ListType: String, Codable {
    case ol
    case ul
}

public struct ListSection: Section, Equatable {
    public let tagName: ListType
    public let markers: [Marker]
    
    public init(tagName: ListType, markers: [Marker]) {
        self.tagName = tagName
        self.markers = markers
    }
}

public struct ImageSection: Section, Equatable{
    public let src: String
    public let caption: String?
    
    public init(src: String, caption: String? = nil) {
        self.src = src
        self.caption = caption
    }
}

public struct CardSection: Section, Equatable {
    public let cardIndex: Int
    
    public init(cardIndex: Int) {
        self.cardIndex = cardIndex
    }
}

public struct MarkerSection: Section, Equatable {
    public let tagName: SectionTagName
    public let markers: [Marker]
    
    public init(tagName: SectionTagName, markers: [Marker]) {
        self.tagName = tagName
        self.markers = markers
    }
}

public enum TextTypeIdentifier: Int, Codable {
    case text = 0
    case atom = 1
}

public struct Marker: Codable, Equatable {
    public let textType: TextTypeIdentifier
    public let markupIndexes: [Int]
    public let numberOfClosedMarkups: Int
    public let value: String
    
    public init(textType: TextTypeIdentifier, markupIndexes: [Int], numberOfClosedMarkups: Int, value: String) {
        self.textType = textType
        self.markupIndexes = markupIndexes
        self.numberOfClosedMarkups = numberOfClosedMarkups
        self.value = value
    }
    
    public init(text: String) {
        self.textType = .text
        self.markupIndexes = []
        self.numberOfClosedMarkups = 0
        self.value = text
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        textType = try container.decode(TextTypeIdentifier.self)
        markupIndexes = try container.decode([Int].self)
        numberOfClosedMarkups = try container.decode(Int.self)
        value = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(textType)
        try container.encode(markupIndexes)
        try container.encode(numberOfClosedMarkups)
        try container.encode(value)
    }
}
