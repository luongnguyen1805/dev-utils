
print("Query Engine")

let objs = ["OpenAI", "Grok", "Claude", "Gemini", "Perplexity", "Copilot"]
let engine = QueryEngine()
var results = engine.execute(objects: objs, query: "?(@=~^.e)")        

print(results == nil ? "Invalid Query" : results!)

