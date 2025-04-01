import XCTest
@testable import Source

final class QueryEngineTests: XCTestCase {

    func testQueryWithKeys() {

        let objs = ["OpenAI", "Grok", "Claude"]
        let engine = QueryEngine()
        let results = engine.execute(objects: objs, query: "?(@=Grok)")
        
        XCTAssertTrue(results.count > 0 && results[0] as! String == "Grok")        
    }
    
}