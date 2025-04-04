
print("Query Engine")

// let objs = [ 
//     ["name": "John", "isStudent": true],
//     ["name": "Tako", "isStudent": false]         
// ]
// let engine = QueryEngine()
// let results = engine.execute(objects: objs, query: "?(@.isStudent=true)")        

// let objs = ["OpenAI", "Grok", "Claude"]
// let engine = QueryEngine()
// var results = engine.execute(objects: objs, query: "?(@=Grok)")        

let objs = [ 
    ["name": "John", "age": 19, "mark": 2.4],
    ["name": "Tako", "age": 10, "mark": 9.3]         
]
let engine = QueryEngine()
// let results = engine.execute(objects: objs, query: """
//         ?(  
//             (@.name = ~.+) 
//                 & ((@.age > 10) | (@.mark < 5))
//         )
//     """)     

let results = engine.execute(objects: objs, query: """
        ?{  
            name == 'Tako'
        }
    """)     

print(results == nil ? "Invalid Query" : results!)

