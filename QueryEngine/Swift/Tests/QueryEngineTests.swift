import XCTest
@testable import Source

final class QueryEngineTests: XCTestCase {

    func test_string() throws {

        let engine = QueryEngine()

        let objs = ["OpenAI", "Grok", "Claude"]
        var results = engine.execute(objects: objs, query: "?(@=Grok)")        
        XCTAssertTrue(results != nil && results!.count > 0 && results![0] == "Grok")        

        results = engine.execute(objects: objs, query: "?(@=~OpenA.)")
        XCTAssertTrue(results != nil && results!.count > 0 && results![0] == "OpenAI")        

        let objs2 = [ 
            ["name": "John", "isStudent": true],
            ["name": "Tako", "isStudent": false]         
        ]
        var results2 = engine.execute(objects: objs2, query: "?(@.name=John)")        
        XCTAssertTrue(results2 != nil && results2!.count > 0 && results2![0]["name"] as! String == "John")        

        results2 = engine.execute(objects: objs2, query: "?(@.name=~.ak.)")
        XCTAssertTrue(results2 != nil && results2!.count > 0 && results2![0]["name"] as! String == "Tako")        
    }
    
    func test_bool() throws {
        let objs = [ 
            ["name": "John", "isStudent": true],
            ["name": "Tako", "isStudent": false]         
        ]

        let engine = QueryEngine()

        let results = engine.execute(objects: objs, query: "?(@.isStudent=true)")        
        XCTAssertTrue(results != nil && results!.count > 0 && results![0]["name"] as! String == "John")        
    }

    func test_number() throws {
        let objs = [ 
            ["name": "John", "age": 19, "mark": 2.4],
            ["name": "Tako", "age": 10, "mark": 9.3]         
        ]

        let engine = QueryEngine()

        let results = engine.execute(objects: objs, query: "?((@.age>12)&(@.mark<5.5))")     
        XCTAssertTrue(results != nil && results!.count > 0 && results![0]["name"] as! String == "John")        
    }
    
}