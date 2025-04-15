import Foundation
import MixedObjC

class QueryEngine {
    
    //MARK: TYPES
    enum QueryOperator: String {
        case equal = "="
        case notEqual = "!="
        case greaterThan = ">"
        case greaterThanOrEqual = ">="
        case lessThan = "<"
        case lessThanOrEqual = "<="
        case regexMatch = "=~"
    }

    enum ConditionOperator: String {
        case and = "&"
        case or = "|"
    }

    struct QueryCondition {
        let propertyName: String?
        let op: QueryOperator
        let expectedValue: QueryValue
    }

    enum QueryValue: Equatable {
        case string(String)
        case float(Float)
        case bool(Bool)

        static func from(_ value: String) -> QueryValue {
            if let floatValue = Float(value) {
                return .float(floatValue)
            } else if value.lowercased() == "true" || value.lowercased() == "false" {
                return .bool(value.lowercased() == "true")
            }
            return .string(value)
        }
    }

    enum QueryNode {
        case condition(QueryCondition)
        case group([QueryNode], ConditionOperator)
        case range(start: Int?, end: Int?)
    }

    enum QueryError: Error {
        case invalidQueryFormat
        case invalidCondition
        case parsingFailed(String)
        case invalidRange(String)
        case unsupportedType
    }
    
    struct QueryResult<T> {
        var filtered: [T]?
        var indices: [Int]?
    }

    //MARK: MAIN
    func execute(objects: [String], query: String) -> QueryResult<String>? {
        return doExecute(objects, query)
    }

    func execute(objects: [[String:Any]], query: String) -> QueryResult<[String:Any]>? {
        return doExecute(objects, query)
    }
    
    //MARK: PRIVATE
    private var foundIndices: [Int]?

    private func doExecute<T>(_ objects: [T],_ query: String) -> QueryResult<T>? {
        
        foundIndices = []
        
        do {
            let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedQuery.hasPrefix("?{") {
                let predicateString = String(cleanedQuery.dropFirst(2).dropLast(1))

                let predicate = safePredicate(predicateString)

                if (predicate == nil) {
                    return nil
                }
                
                var filtered: [T] = []
                for i in objects.indices {
                    let obj = objects[i]
                    let isFilterValid = predicate!.evaluate(with: obj)
                    if isFilterValid == true {
                        filtered.append(obj)
                        foundIndices?.append(i)
                    }
                }
                
                return QueryResult(filtered: filtered, indices: foundIndices)
            }
            else if cleanedQuery.hasPrefix("?(") && cleanedQuery.hasSuffix(")") {
                let innerQuery = String(cleanedQuery.dropFirst(2).dropLast(1))
                guard let queryNode = try parseQuery(innerQuery) else {
                    throw QueryError.invalidQueryFormat
                }
                return try applyQueryNode(queryNode, to: objects)
            } else {
                guard let rangeNode = try parseRangeQuery(cleanedQuery) else {
                    throw QueryError.invalidRange("Invalid range format: \(cleanedQuery)")
                }
                return applyRange(rangeNode, to: objects)
            }
        } 
        catch {
            return nil
        }
    }    
    
    private func parseQuery(_ query: String) throws -> QueryNode? {
        try parseExpression(query)
    }

    private func parseExpression(_ query: String) throws -> QueryNode {
        var nodes: [QueryNode] = []
        var operators: [ConditionOperator] = []
        var currentExpr = ""

        var i = 0
        let queryCount = query.count
        while i < queryCount {
            let index = query.index(query.startIndex, offsetBy: i)
            let char = query[index]
            if (char == " " || char == "\n" || char == "\t") {
                i += 1
                continue
            }

            if char == "(" {
                let (nestedNode, endIndex) = try parseNestedGroup(query, startingAt: i)
                nodes.append(nestedNode)
                i = endIndex
            } else if char == "&" || char == "|" {
                if !currentExpr.isEmpty {
                    nodes.append(try parseCondition(currentExpr))
                    currentExpr = ""
                }
                operators.append(char == "&" ? .and : .or)
            } else {
                currentExpr.append(char)
            }
            i += 1
        }

        if !currentExpr.isEmpty {
            nodes.append(try parseCondition(currentExpr))
        }

        return buildGroup(nodes: nodes, operators: operators)
    }

    private func parseNestedGroup(_ query: String, startingAt start: Int) throws -> (QueryNode, Int) {
        var nestedLevel = 1
        var j = start + 1
        while j < query.count {
            let char = query[query.index(query.startIndex, offsetBy: j)]
            if (char == " " || char == "\n" || char == "\t") {
                j += 1
                continue
            }

            if char == "(" { nestedLevel += 1 }
            if char == ")" { nestedLevel -= 1 }
            if nestedLevel == 0 { break }
            j += 1
        }
        guard j < query.count else { throw QueryError.parsingFailed("Unmatched parentheses") }
        let nestedQuery = String(query[query.index(query.startIndex, offsetBy: start + 1)..<query.index(query.startIndex, offsetBy: j)])
        let node = try parseExpression(nestedQuery)
        return (node, j)
    }

    private func parseCondition(_ conditionStr: String) throws -> QueryNode {
        let regex = "\\s*(@(?:\\.[\\w]+)?)\\s*(!=|>|>=|<|<=|=~|=)\\s*(.+)\\s*"

        let components = getRegexMatchGroups(for: conditionStr, pattern: regex)
        
        guard components.count >= 3 else {
            throw QueryError.invalidCondition
        }

        let propertyName = components[0].hasPrefix("@.") ? String(components[0].dropFirst(2)) : nil

        guard let op = QueryOperator(rawValue: components[1]) else {
            throw QueryError.parsingFailed("Invalid operator: \(components[1])")
        }
        let expectedValue = QueryValue.from(components[2].trimmingCharacters(in: .whitespaces))
        
        return .condition(QueryCondition(propertyName: propertyName, op: op, expectedValue: expectedValue))
    }

    private func parseRangeQuery(_ query: String) throws -> QueryNode? {

        let trimmed = query.trimmingCharacters(in: .whitespaces)

        let parts = trimmed.components(separatedBy: "..")
        var first:Int? = nil
        var second = 0

        switch parts.count {
            case 1:
                if let value = Int(parts[0]) {
                    first = value
                    second = value
                }
            case 2:
                if let firstValue = Int(parts[0]), !parts[0].isEmpty {
                    first = firstValue
                }
                if let secondValue = Int(parts[1]) {
                    second = secondValue
                }
            default:
                throw QueryError.invalidRange("Invalid range syntax: \(query)")
        }

        return .range(start: first, end: second)
    }

    private func buildGroup(nodes: [QueryNode], operators: [ConditionOperator]) -> QueryNode {
        guard !nodes.isEmpty else { return .condition(QueryCondition(propertyName: nil, op: .equal, expectedValue: .bool(false))) }
        if nodes.count == 1 { return nodes[0] }
        return .group(nodes, operators.first ?? .and)
    }

    private func applyQueryNode<T>(_ node: QueryNode, to objects: [T]) throws -> QueryResult<T> {
        switch node {
            case .condition, .group:
                
                var filtered: [T] = []
                for i in objects.indices {
                    let obj = objects[i]
                    let isFilterValid = try evaluateQuery(object: obj, node: node)
                    if isFilterValid == true {
                        filtered.append(obj)
                        foundIndices?.append(i)
                    }
                }
            
                return QueryResult(filtered: filtered, indices: foundIndices)
            
            case .range(let start, let end):
                return applyRange(.range(start: start, end: end), to: objects)
        }
    }

    private func evaluateQuery<T>(object: T, node: QueryNode) throws -> Bool {
        switch node {
            case .condition(let condition):
                return try evaluateCondition(object: object, condition: condition)
            case .group(let nodes, let op):
                let initial = try evaluateQuery(object: object, node: nodes[0])
                return try nodes.dropFirst().reduce(initial) { result, node in
                    let nextResult = try evaluateQuery(object: object, node: node)
                    return op == .and ? result && nextResult : result || nextResult
                }
            case .range:
                fatalError("Range nodes should not reach evaluateQuery")
        }
    }

    private func evaluateCondition<T>(object: T, condition: QueryCondition) throws -> Bool {
        if let string = object as? String {
            guard condition.propertyName == nil else { return false }

            switch condition.expectedValue {
                case .string(let expected):
                    switch condition.op {
                        case .equal: return string == expected
                        case .notEqual: return string != expected
                        case .regexMatch: return string.range(of: expected, options: .regularExpression) != nil
                        default: return false
                    }
                default:
                    return false
            }
        } else if let dict = object as? [String: Any], let key = condition.propertyName, let value = dict[key] {
            
            let valueFloat = castToFloat(value)
            let valueFinal = valueFloat != nil ? valueFloat! : value

            switch (condition.expectedValue, valueFinal) {
                case (.string(let expected), let actual as String):
                    switch condition.op {
                        case .equal: return actual == expected
                        case .notEqual: return actual != expected
                        case .regexMatch: return actual.range(of: expected, options: .regularExpression) != nil
                        default: return false
                    }
                case (.float(let expected), let actual as Float):                
                    switch condition.op {
                        case .equal: return actual == expected
                        case .notEqual: return actual != expected
                        case .greaterThan: return actual > expected
                        case .greaterThanOrEqual: return actual >= expected
                        case .lessThan: return actual < expected
                        case .lessThanOrEqual: return actual <= expected
                        default: return false
                    }
                case (.bool(let expected), let actual as Bool):
                    return condition.op == .equal ? actual == expected : actual != expected
                default:
                    return false
            }
        } else {
            throw QueryError.unsupportedType
        }
    }

    private func applyRange<T>(_ node: QueryNode, to objects: [T]) -> QueryResult<T> {
        
        guard case .range(let start, let end) = node else {
            return QueryResult(filtered: objects, indices: nil)
        }
        let count = objects.count

        let resolvedStart: Int
        let resolvedEnd: Int

        if let start = start, let end = end {
            resolvedStart = max(0, start)
            resolvedEnd = min(count, end)
        } else if let end = end, start == nil {
            if end >= 0 {
                resolvedStart = 0
                resolvedEnd = min(end, count) - 1
            } else {
                resolvedStart = max(0, count + end)
                resolvedEnd = count - 1
            }
        } else if let start = start, end == nil {
            resolvedStart = max(0, start)
            resolvedEnd = count
        } else {
            return QueryResult(filtered: objects, indices: nil)
        }

        guard resolvedStart <= resolvedEnd else {
            return QueryResult(filtered: [], indices: nil)
        }
        
        let filtered = Array(objects[resolvedStart...min(resolvedEnd, count)])
        
        return QueryResult(filtered: filtered, indices: nil)
    }

    private func getRegexMatchGroups(for input: String, pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            guard let match = regex.firstMatch(in: input, range: range) else { return [] }
            return (1..<match.numberOfRanges).compactMap { i in
                guard let range = Range(match.range(at: i), in: input) else { return nil }
                return String(input[range])
            }
        } catch {
            return []
        }
    }

    private func castToFloat(_ value: Any) -> Float? {
        if let floatValue = value as? Float {
            return floatValue
        } else if let doubleValue = value as? Double {
            return Float(doubleValue)
        } else if let intValue = value as? Int {
            return Float(intValue)
        }
        return nil
    }

}
