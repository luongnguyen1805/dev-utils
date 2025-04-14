
import XCTest
@testable import Source

final class MapHelperTests: XCTestCase {

    func test_getValue() throws {

        let obj:[Any] = [
            ["name": "John", "age": 13],
            ["name": "Alex", "age": 12],
        ]

        var final = obj[of: "students", 0, "name"]
        XCTAssertTrue(final == nil)
        
        final = obj[of: 1, "name"]
        XCTAssertTrue(final as? String == "Alex")
        
        final = obj[of: 1, "name", "age"]
        XCTAssertTrue(final == nil)
    }

    func test_array() throws {
        
        var obj:[Any] = [
            ["name": "John", "age": 13],
            ["name": "Alex", "age": 12],
        ]
        
        obj[of: 0, "name"] = "Tony"        
     
        let arr = obj as? [[String:Any]]
        if let arr = arr {
            let ele = arr[0]
            XCTAssertTrue(ele["name"] as? String == "Tony")
        }
        else {
            XCTFail()
        }
    }

    func test_dict() throws {

        var obj:[String: Any] = [
            "students": [
                ["name": "John", "age": 13],
                ["name": "Alex", "age": 12]
            ],
            "address": "NewYork"
        ]
     
        obj[of: "students", 0, "name"] = "Tony"
     
        let final = obj[of: "students", 0, "name"]
        
        XCTAssertTrue(final != nil && final as! String == "Tony")
    }

}
