
print("Map Helper")

var objs:[Any] = ["OpenAI", "Grok", "Claude", "Gemini", "Perplexity", "Copilot"]

let result = objs[of: 0]

if (result == nil) {
    print("Invalid Navigator")
} else {
    print(result as! String)
}

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
