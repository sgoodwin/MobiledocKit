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
            markups: [],
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
        
        let rendered = renderMarkdown(doc)
        let url = dummyBundle.url(forResource: "article", withExtension: "md")!
        let raw = try! Data(contentsOf: url)
        let article = String(data: raw, encoding: .utf8)!
        
        XCTAssertEqual(rendered, article)
    }

    
    func testRendererIgnoresUnknownCards() {
        let doc = Mobiledoc(
            markups: [],
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
        
        let rendered = renderMarkdown(doc)
        let url = dummyBundle.url(forResource: "article", withExtension: "md")!
        let raw = try! Data(contentsOf: url)
        let article = String(data: raw, encoding: .utf8)!
        
        XCTAssertEqual(rendered, article)
    }

}
