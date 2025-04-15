
print("Query Engine")

let objs = ["OpenAI", "Grok", "Claude", "Gemini", "Perplexity", "Copilot"]
let engine = QueryEngine()
var result = engine.execute(objects: objs, query: "?(@=~^.e)")

if (result == nil) {
    print("Invalid Query")
} else {
    print(result!.filtered!)
}

