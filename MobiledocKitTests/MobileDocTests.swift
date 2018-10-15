////
//  MobiledocKit
//

import XCTest
@testable import MobiledocKit

class MobileDocTests: XCTestCase {
    lazy var dummyBundle: Bundle = {
        return Bundle(for: self.classForCoder)
    }()
    
    func testCreatingMobileDocFromJSON()  {
        let url =  dummyBundle.url(forResource: "mobiledoccard", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        let card = try? decoder.decode([MarkdownCard].self, from: data)
        XCTAssertNotNil(card)
        
        let notacard =  try? decoder.decode([MarkdownCard].self, from: "[{\"title\":\"sup\"]".data(using: .utf8)!)
        XCTAssertNil(notacard)
    }
    
    func testMobileMarkdownCardDecoding() {
        let url = dummyBundle.url(forResource: "markdowncard", withExtension: "json")!
        let decoder = JSONDecoder()
        do {
            let rawCard = try Data(contentsOf: url)
            let _ = try decoder.decode(MarkdownCard.self, from: rawCard)
        } catch{
            XCTFail(String(describing: error))
        }
    }
    
    func testInvalidMobileMarkdownCardDecoding() {
        let url = dummyBundle.url(forResource: "invalidtitlemarkdowncard", withExtension: "json")!
        let decoder = JSONDecoder()
        let rawCard = try! Data(contentsOf: url)
        XCTAssertThrowsError(try decoder.decode(MarkdownCard.self, from: rawCard))
    }
    
    func testDecodingSections() {
        let raw = "{\"version\":\"0.3.1\",\"atoms\":[],\"cards\":[],\"markups\":[],\"sections\":[[1,\"p\",[[0,[],0,\"Hmmm\"]]]]}"
        let mobiledoc = try! JSONDecoder().decode(Mobiledoc.self, from: raw.data(using: .utf8)!)
        
        guard let section = mobiledoc.sections[0] as? MarkerSection else {
            XCTFail("Incorrect section parsed")
            return
        }
        
        XCTAssertEqual(section.markers.first?.value, "Hmmm")
    }
    
    func testDecodingProblemPost() {
        let raw = "{\"version\":\"0.3.1\",\"atoms\":[],\"cards\":[[\"markdown\",{\"markdown\":\"Non-markdowned stuff\"}]],\"markups\":[],\"sections\":[[10,0],[1,\"p\",[[0,[],0,\"This is regular text\"]]]]}"
        let mobiledoc = try! JSONDecoder().decode(Mobiledoc.self, from: raw.data(using: .utf8)!)
        XCTAssertEqual(render(mobiledoc), "Non-markdowned stuff\nThis is regular text")
    }
}

