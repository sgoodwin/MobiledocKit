////
//  MobiledocKit
//

import XCTest
import MobiledocKit

class MarkdownRendererTests: XCTestCase {
    lazy var dummyBundle: Bundle = {
        return Bundle(for: self.classForCoder)
    }()

    func testGeneratingSampleArticle() {
        let doc = Mobiledoc(
            cards: [
                MobiledocCard("This is a document I wrote.")
            ],
            sections: [
                CardSection(cardIndex: 0),
                ImageSection(src: "http://placekitten.com/200/100"),
                ListSection(tagName: .ul, markers: [
                    Marker(text: "Write documents"),
                    Marker(text: "???"),
                    Marker(text: "Get money")
                ])
            ]
        )
        
        let rendered = MarkdownRenderer().render(doc)
        let url = dummyBundle.url(forResource: "article", withExtension: "md")!
        let raw = try! Data(contentsOf: url)
        let article = String(data: raw, encoding: .utf8)!
        
        XCTAssertEqual(rendered, article)
    }

    
    func testRendererIgnoresUnknownCards() {
        let doc = Mobiledoc(
            cards: [
                MobiledocCard("This is a document I wrote."),
                MobiledocCard(title: "poopin", values: ["content": "doesn't matter"])
            ],
            sections: [
                CardSection(cardIndex: 0),
                CardSection(cardIndex: 1),
                ImageSection(src: "http://placekitten.com/200/100"),
                ListSection(tagName: .ul, markers: [
                    Marker(text: "Write documents"),
                    Marker(text: "???"),
                    Marker(text: "Get money")
                ])
            ]
        )
        
        let rendered = MarkdownRenderer().render(doc)
        let url = dummyBundle.url(forResource: "article", withExtension: "md")!
        let raw = try! Data(contentsOf: url)
        let article = String(data: raw, encoding: .utf8)!
        
        XCTAssertEqual(rendered, article)
    }
    
    func testRendererTreatsAtomsAsPlaintext() {
        let doc = Mobiledoc(
            atoms: [
                MobiledocAtom(name: "mention", text: "@bob", payload: ["id": "xxx"])
            ],
            sections: [
                MarkerSection(tagName: .p, markers: [
                    Marker(text: "I mention"),
                    Marker(textType: .atom, markupIndexes: [], numberOfClosedMarkups: 0, value: "0"),
                    Marker(text: "sometimes.")
                ])
            ]
        )
        
        let rendered = MarkdownRenderer().render(doc)
        let url = dummyBundle.url(forResource: "article_with_mentions", withExtension: "md")!
        let raw = try! Data(contentsOf: url)
        let article = String(data: raw, encoding: .utf8)!
        
        XCTAssertEqual(rendered, article)
    }
    
    func testRendererHandlesMarkups() {
        let doc = Mobiledoc(
            markups: ["b"],
            sections: [
                MarkerSection(tagName: .p, markers: [
                    Marker(textType: .text, markupIndexes: [0], numberOfClosedMarkups: 1, value: "sup"),
                ])
            ]
        )
        
        let rendered = MarkdownRenderer().render(doc)
        XCTAssertEqual(rendered, "*sup*\n")
    }

}
