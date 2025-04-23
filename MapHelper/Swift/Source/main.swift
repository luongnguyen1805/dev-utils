
print("Map Helper")

var objs:[Any] = ["OpenAI", "Grok", "Claude", "Gemini", "Perplexity", "Copilot"]

let result = objs[of: 0]

if (result == nil) {
    print("Invalid Navigator")
} else {
    print(result as! String)
}

var myDict = [
    "books": [
        ["title": "Alice"],
        ["title": "Red"],
        ["title": "Dark"]
    ]
]
myDict[of: "books",0] = ["title": "Adventure", "color": "red"]

myDict[selector: "books[?(@.title=Red)]/title"] = "Bingo"

let str = MapHelper.anyToJSONString(myDict) ?? ""

print(str)

