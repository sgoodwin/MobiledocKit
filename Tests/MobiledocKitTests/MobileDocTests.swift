////
//  MobiledocKit
//

import XCTest
@testable import MobiledocKit

class MobileDocTests: XCTestCase {
    lazy var dummyBundle: Bundle = {
        return Bundle.testBundle
    }()
    
    func testCreatingMobileDocFromJSON()  {
        let url =  dummyBundle.url(forResource: "mobiledoccard", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        let card = try? decoder.decode([MobiledocCard].self, from: data)
        XCTAssertNotNil(card)
        
        let notacard =  try? decoder.decode([MobiledocCard].self, from: "[{\"title\":\"sup\"]".data(using: .utf8)!)
        XCTAssertNil(notacard)
    }
    
    func testMobileMarkdownCardDecoding() {
        let url = dummyBundle.url(forResource: "markdowncard", withExtension: "json")!
        let decoder = JSONDecoder()
        do {
            let rawCard = try Data(contentsOf: url)
            let _ = try decoder.decode(MobiledocCard.self, from: rawCard)
        } catch{
            XCTFail(String(describing: error))
        }
    }
    
    func testDecodingSections() {
        let raw = "{\"version\":\"0.3.1\",\"atoms\":[],\"cards\":[],\"markups\":[],\"sections\":[[1,\"p\",[[0,[],0,\"Hmmm\"]]]]}"
        let mobiledoc = try! JSONDecoder().decode(Mobiledoc.self, from: raw.data(using: .utf8)!)
        
        guard let section = mobiledoc.sections[0] as? MarkerSection else {
            XCTFail("Incorrect section parsed")
            return
        }
        
        XCTAssertEqual(section.markers.first?.value, .string("Hmmm"))
    }
    
    func testDecodingProblemPost() {
        let raw = "{\"version\":\"0.3.1\",\"atoms\":[],\"cards\":[[\"markdown\",{\"markdown\":\"Non-markdowned stuff\"}]],\"markups\":[],\"sections\":[[10,0],[1,\"p\",[[0,[],0,\"This is regular text\"]]]]}"
        let mobiledoc = try! JSONDecoder().decode(Mobiledoc.self, from: raw.data(using: .utf8)!)
        
        let expectedDoc = Mobiledoc(
            cards: [
                MobiledocCard("Non-markdowned stuff")
            ],
            sections: [
                CardSection(cardIndex: 0),
                MarkerSection(
                    tagName: .p,
                    markers: [
                        Marker(text: "This is regular text")
                    ]
                )
            ]
        )
        XCTAssertEqual(mobiledoc, expectedDoc)
    }
    
    func testDecodingReleaseDayPost() {
        let url = dummyBundle.url(forResource: "release_day_mobiledoc", withExtension: "json")!
        let decoder = JSONDecoder()
        do {
            let rawCard = try Data(contentsOf: url)
            let _ = try decoder.decode(Mobiledoc.self, from: rawCard)
        } catch{
            XCTFail(String(describing: error))
        }
    }
    
    func testDecodingOtherReleaseDayPost() {
        let url = dummyBundle.url(forResource: "publisher_release_mobiledoc", withExtension: "json")!
        let decoder = JSONDecoder()
        do {
            let rawCard = try Data(contentsOf: url)
            let _ = try decoder.decode(Mobiledoc.self, from: rawCard)
        } catch{
            XCTFail(String(describing: error))
        }
    }
    
    func testReencoding() throws {
        let mobiledoc = Mobiledoc(
            markups: [MobiledocMarkup(.b)],
            cards: [
                MobiledocCard("this is a *thing*")
            ],
            sections: [
                CardSection(cardIndex:0),
                ImageSection(src: "https://cdn.bulbagarden.net/upload/thumb/5/5d/010Caterpie.png/250px-010Caterpie.png"),
                ListSection(tagName: .ol, markers: [Marker(textType: .text, markupIndexes: [0], numberOfClosedMarkups: 1, value: .string("bold?"))]),
                MarkerSection(tagName: .h1, markers: [Marker(textType: .text, markupIndexes: [], numberOfClosedMarkups: 0, value: .string("header?"))])
            ]
        )
        
        let encoded = try JSONEncoder().encode(mobiledoc)
        let decoded = try JSONDecoder().decode(Mobiledoc.self, from: encoded)
        
        XCTAssertEqual(mobiledoc, decoded)
    }
    
    struct GibberishPosts: Decodable {
        let posts: [GibberishPost]
    }
    
    struct GibberishPost: Decodable {
        let mobiledoc: String
    }
    
    func testDecodingGibberish() throws {
        // Because some API's embed encoded mobiledocs into other docs.
        let url = dummyBundle.url(forResource: "gibberish", withExtension: "json")!
        let raw = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let posts = try decoder.decode(GibberishPosts.self, from: raw)
        let post = posts.posts[0]
        
        let doc = try? decoder.decode(Mobiledoc.self, from: post.mobiledoc.data(using: .utf8)!)
        XCTAssertNotNil(doc)
    }
    
    func testNonEquivalentDocs() {
        let doc1 = Mobiledoc(cards: [MobiledocCard("sup")], sections: [CardSection(cardIndex: 0)])
        let doc2 = Mobiledoc(cards: [MobiledocCard("sup")], sections: [ImageSection(src: "image!")])
        
        XCTAssertNotEqual(doc1, doc2)
    }
    
    func testEncodingAtoms() throws {
        let atom = MobiledocAtom(name: "mention", text: "@bob", payload: ["id": "42"])
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(atom)
        let raw = String(data: data, encoding: .utf8)!
        
        XCTAssertEqual(raw, "[\"mention\",\"@bob\",{\"id\":\"42\"}]")
    }
    
    func testDecodingAtoms() throws {
        let atom = MobiledocAtom(name: "mention", text: "@bob", payload: ["id": "42"])
        let decoder = JSONDecoder()
        let raw = "[\"mention\",\"@bob\",{\"id\":\"42\"}]"
        
        let data = raw.data(using: .utf8)!
        let decoded = try decoder.decode(MobiledocAtom.self, from: data)
        
        XCTAssertEqual(atom, decoded)
    }
    
    func testParsingSingleMarker() throws {
        let raw = """
[
0,
[

],
0,
"LICENSE"
]
""".data(using: .utf8)!
        
        let marker = try JSONDecoder().decode(Marker.self, from: raw)
        XCTAssertEqual(marker.value, .string("LICENSE"))
    }
}


