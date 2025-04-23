
# QueryEngine

**QueryEngine** is a lightweight utility that enables filtering of structured data (e.g. arrays of dictionaries or strings) using an XPath/Predicate-inspired query syntax.

## 🧠 Example Usage

```swift
let objs = [ 
    ["name": "John", "age": 19, "mark": 2.4],
    ["name": "Tako", "age": 10, "mark": 9.3]         
]
let engine = QueryEngine()
let results = engine.execute(objects: objs, query: """
        ?(
            @.name = Tako
        )
    """)

print(results == nil ? "Invalid Query" : results!)
```

<br/>

# MapHelper

Simplify working with nested Arrays and Dictionaries using clean, intuitive subscript syntax. Say goodbye to complex indexing and key lookups!

```swift
var myDict = [
    "books": [
        ["title": "Alice"],
        ["title": "Red"],
        ["title": "Dark"]
    ]
]
myDict[of: "books",0] = ["title": "Adventure", "color": "red"]

myDict[selector: "books[0]/title"] = "Bingo"

let str = MapHelper.anyToJSONString(myDict) ?? ""

print(str)
```

<br/>

# License

None


