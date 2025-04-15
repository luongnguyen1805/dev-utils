
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

var myArray = [
    ["name": "John"],
    ["name": "David"]
]
myArray[of: 0, "name"] = "Alex"
MapHelper.prettyPrint(myArray)

var myDict = [
    "books": [
        ["title": "Alice"],
        ["title": "Red"],
        ["title": "Dark"]
    ]
]
myDict[of: "books", 2, "title"] = "Adventure"
MapHelper.prettyPrint(myDict)

```

<br/>

# License

None


