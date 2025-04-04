# QueryEngine

**QueryEngine** is a lightweight Swift utility that enables filtering of structured data (e.g. arrays of dictionaries or strings) using an XPath/Predicate-inspired query syntax.

---

## ✨ Features

- Query any list of `[Dictionary<String, Any>]` or `[String]`
- Support for structured, readable query syntax
- Expression-based filtering with logical operators
- String match, regex match, numeric comparison, boolean logic

---

## 🧠 Example Usage

```swift
let objs = [ 
    ["name": "John", "age": 19, "mark": 2.4],
    ["name": "Tako", "age": 10, "mark": 9.3]
]

let engine = QueryEngine()

let results = engine.execute(objects: objs, query: """
    ?{
        name == 'Tako'
    }
""")

print(results == nil ? "Invalid Query" : results!)
```

## 📜 License

MIT License. Free to use and modify.

---

## 🙌 Contributing

PRs and suggestions welcome! Please file an issue or open a discussion.

---
