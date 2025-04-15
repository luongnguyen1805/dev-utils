import XCTest
@testable import Source

final class QueryEngineTests: XCTestCase {

    func test_string() throws {

        let engine = QueryEngine()

        let objs = ["OpenAI", "Grok", "Claude"]
        var results = engine.execute(objects: objs, query: "?(@=Grok)")?.filtered
        XCTAssertTrue(results != nil && results!.count > 0 && results![0] == "Grok")

        results = engine.execute(objects: objs, query: "?(@=~OpenA.)")?.filtered
        XCTAssertTrue(results != nil && results!.count > 0 && results![0] == "OpenAI")

        let objs2 = [ 
            ["name": "John", "isStudent": true],
            ["name": "Tako", "isStudent": false]         
        ]
        var results2 = engine.execute(objects: objs2, query: "?(@.name=John)")?.filtered
        XCTAssertTrue(results2 != nil && results2!.count > 0 && results2![0]["name"] as! String == "John")

        results2 = engine.execute(objects: objs2, query: "?(@.name=~.ak.)")?.filtered
        XCTAssertTrue(results2 != nil && results2!.count > 0 && results2![0]["name"] as! String == "Tako")
    }
    
    func test_bool() throws {
        let objs = [ 
            ["name": "John", "isStudent": true],
            ["name": "Tako", "isStudent": false]         
        ]

        let engine = QueryEngine()

        let results = engine.execute(objects: objs, query: "?(@.isStudent=true)")?.filtered
        XCTAssertTrue(results != nil && results!.count > 0 && results![0]["name"] as! String == "John")
    }

    func test_number() throws {
        let objs = [ 
            ["name": "John", "age": 19, "mark": 2.4],
            ["name": "Tako", "age": 10, "mark": 9.3]         
        ]

        let engine = QueryEngine()

        let results = engine.execute(objects: objs, query: "?((@.age>12)&(@.mark<5.5))")?.filtered
        XCTAssertTrue(results != nil && results!.count > 0 && results![0]["name"] as! String == "John")
    }

    func test_range() throws {

        let objs = [ 
            ["name": "John", "age": 19, "mark": 2.4],
            ["name": "Tako", "age": 10, "mark": 9.3],
            ["name": "Alex", "age": 14, "mark": 6.3]         
        ]

        let engine = QueryEngine()
        let results = engine.execute(objects: objs, query: "..2")?.filtered
        XCTAssertTrue(results != nil && results!.count == 2 && results![1]["name"] as! String == "Tako")

        let objs2 = ["OpenAI", "Grok", "Claude", "Gemini", "Perplexity", "Copilot"]
        let results2 = engine.execute(objects: objs2, query: "..-1")?.filtered
        XCTAssertTrue(results2 != nil && results2!.count > 0 && results2![0] == "Copilot")  
      
    }
    
}
