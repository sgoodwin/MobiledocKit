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
            markups: ["b", "i", "h1", "h2"],
            sections: [
                MarkerSection(tagName: .p, markers: [
                    Marker(textType: .text, markupIndexes: [0], numberOfClosedMarkups: 0, value: "sup"),
                    Marker(textType: .text, markupIndexes: [1], numberOfClosedMarkups: 2, value: "nah"),
                ]),
                MarkerSection(tagName: .p, markers: [
                    Marker(textType: .text, markupIndexes: [2], numberOfClosedMarkups: 1, value: "title"),
                ]),
                MarkerSection(tagName: .p, markers: [
                    Marker(textType: .text, markupIndexes: [3], numberOfClosedMarkups: 1, value: "subtitle")
                ])
            ]
        )
        
        let rendered = MarkdownRenderer().render(doc)
        // It handles nesting even!
        XCTAssertEqual(rendered, "*sup _nah_*\n#title\n##subtitle\n")
    }

    func testRenderHandlesProblemDoc() throws {
        let raw = """
{\"atoms\":[],\"cards\":[[\"card-markdown\",{\"cardName\":\"card-markdown\",\"markdown\":\"Sometimes the answer to your programming problem is \\\"use more types\\\". I spoke at [Mobilization 8]() this past weekend and I discussed a particular programming issue with someone. Here is a version of that problem (with the details changed to protect the innocent).\\n\\n# The Setup\\n\\nLet\'s say you have a struct like so:\\n\\n```\\nstruct CreditCard {\\n  let number: String\\n  let expiration: Date\\n}\\n```\\n\\nNow let\'s also say that whenever you display the number in your app, you need to mask part of the number. Rather than display `4242 4242 4242 4242` on the screen, you want to only display `xxxx xxxx xxxx 4242`. The person I spoke with had a project where they accomplished this goal by adding to their general `CreditCardUtils` struct.\\n\\n```\\nstruct CreditCardUtils {\\n\\/\\/\\/ various other methods here, at least 100 lines of code, some that depend on system objects.\\n\\n  static func mask(number: String) -> String {\\n  }\\n}\\n\\nextension CreditCard {\\n  var maskedNumber: String {\\n    return CreditCardUtils.mask(number: number)\\n  }\\n}\\n\\n```\\n\\nThis way technically worked. Any time you needed to display the number on the screen, you could ask a card for the masked version. However, when he tried to write tests for it, he ran into a problem. This masking method was a static function of a struct which could not be created without access to system objects. Even if you did go through the effort to create one, it did not matter because you could not replace the call with your fake in a `CreditCard`.\\n\\nAfter some discussion, here\'s what I came up with:\\n\\n# The Fix\\n\\n## A New Type\\n\\nReplace the super-generic type `String` with a new custom type `CreditCardNumber` there are two ways to do that depending on what else you need to do.\\n\\n```\\nstruct CreditCardNumber {\\n  let number: String\\n}\\n\\n\\/\\/\\/ or\\n\\ntypealias CreditCardNumber = String\\n```\\n\\n## Move The Behavior To The Type\\n\\n```\\nextension CreditCardNumber {\\n  var masked: String {\\n  }\\n}\\n```\\n\\nRather than depending on some generic Util type to do the work, we move that behavior onto the object that *has* this behavior. A card number can create a masked representation. This is easily testable and no longer requires elaborate gymnastics in your tests. Make a card number with a value, verify the masked version it generates looks correct, move on to your next task. This *does* have the consequence of making your code a bit more verbose though:\\n\\n```\\nlet card = CreditCard(number: CreditCardNumber(number: \\\"4242 4242 4242 4242\\\"), expiry: Date())\\n```\\n\\nSlightly more messy looking, but if you really want to fix that you can! If you make the new type conform to `ExpressibleByStringLiteral`, you can create cards in much the same way as you would before.\\n\\n\\n```\\nstruct CreditCardNumber: ExpressibleByStringLiteral {\\n    typealias StringLiteralType = String\\n    \\n    let rawValue: String\\n    \\n    init(stringLiteral: String) {\\n        self.rawValue = stringLiteral\\n    }\\n}\\n\\nlet number: CreditCardNumber = \\\"4242 4242 4242 4242\\\"\\n```\\n\\nNow that you can create card numbers with string literals, creating new cards looks like it did originally:\\n\\n```\\nlet card = CreditCard(number: \\\"4242 4242 4242 4242\\\", expiry: Date())\\n```\\n\\nI don\'t personally think this step is necessary, but I\'ve seen projects where they avoid creating the necessary types to represent their information nicely because their inits look messier. If you\'re one of those people, this trick can help.\\n\\n## Use A Formatter\\n\\nAfter thinking about this some more, I realized that maybe this masked value should not be computed by the `CreditCardNumber`. We are trying to format data for display on the screen, so we should use a formatter, just like we would if we wished to display dates, currencies, or weights.\\n\\n```\\nclass CreditCardNumberFormatter: Formatter {\\n}\\n```\\n\\nA formatter is a fairly small object with no dependencies so it is still easy to test. Using a `Formatter` subclass also allows you to use the same logic in your Mac app with Cocoa Bindings and such. Generally any time you need to format your data to display on the screen, there\'s likely an associated formatter. If one does not exist, like in this example with credit card numbers, perhaps you should make one. There are quite a few already:\\n\\n- DateFormatter\\n- PersonNameComponentsFormatter (because in some languages, the last name comes first and such)\\n- MassFormatter\\n- EnergyFormatter (for joules and calories and such)\\n- LengthFormatter\\n- NumberFormatter\\n- MeasurementFormatter\\n- ByteCountFormatter\\n- ISO6801DateFormatter\\n- DateIntervalFormatter\\n\\nThese formatters consider units, different use cases, as well as language. All testable in a fairly neat package.\\n\\n# Fin\\n\\nSo now maybe you\'re armed with a bit more knowledge and you can go forth and test your things. Enjoy!\\n\"}]],\"markups\":[],\"sections\":[[10,0]],\"version\":\"0.3.1\"}
""".data(using: .utf8)
        
        let doc = try JSONDecoder().decode(Mobiledoc.self, from: raw!)
        let renderer = MarkdownRenderer()
        let rendered = renderer.render(doc).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(rendered.isEmpty)
    }

}
