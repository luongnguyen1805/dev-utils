
print("XPath/JSONPath Query Engine")

let objs = ["OpenAI", "Grok", "Claude"]
let engine = QueryEngine()
let results = engine.execute(objects: objs, query: "?((@=Grok)|(@=OpenAI))")

print(results)