import Foundation

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
        let expectedValue: Any
    }

    enum QueryNode {
        case condition(QueryCondition)
        case group([QueryNode], ConditionOperator)
    }

    //MARK: MAIN
    func execute(objects: [Any], query: String) -> [Any] {
        guard let queryNode = parseQuery(query) else { 
            return [] 
        }
        return objects.filter { evaluateQuery(object: $0, node: queryNode) }
    }

    //MARK: PRIVATE
    private func parseQuery(_ query: String) -> QueryNode? {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedQuery.hasPrefix("?(") && cleanedQuery.hasSuffix(")") else { return nil }
        let innerQuery = String(cleanedQuery.dropFirst(2).dropLast(1))

        let parsed = parseExpression(innerQuery)
        return parsed
    }

    private func parseExpression(_ query: String) -> QueryNode? {
        var stack: [QueryNode] = []
        var operators: [ConditionOperator] = []
        var currentExpr = ""
        
        var i = 0
        while i < query.count {
            let char = query[query.index(query.startIndex, offsetBy: i)]
            
            if char == "(" {
                var nestedLevel = 1
                var j = i + 1
                while j < query.count {
                    let nestedChar = query[query.index(query.startIndex, offsetBy: j)]
                    if nestedChar == "(" { nestedLevel += 1 }
                    if nestedChar == ")" { nestedLevel -= 1 }
                    if nestedLevel == 0 { break }
                    j += 1
                }
                if let nestedGroup = parseExpression(String(query[query.index(query.startIndex, offsetBy: i + 1)..<query.index(query.startIndex, offsetBy: j)])) {
                    stack.append(nestedGroup)
                }
                i = j
            } else if char == "&" || char == "|" {
                if !currentExpr.isEmpty {
                    if let condition = parseCondition(currentExpr) {
                        stack.append(.condition(condition))
                    }
                    currentExpr = ""
                }
                let op = (char == "&") ? ConditionOperator.and : ConditionOperator.or
                operators.append(op)
            } else {
                currentExpr.append(char)
            }
            i += 1
        }
                
        if !currentExpr.isEmpty, let condition = parseCondition(currentExpr) {
            stack.append(.condition(condition))
        }
        
        return buildGroup(stack, operators)
    }

    private func parseCondition(_ conditionStr: String) -> QueryCondition? {
        let regex = "@\\.?([\\w]+)?\\s*(=|!=|>|>=|<|<=|=~)\\s*(.+)"
        let components = getRegexMatchGroups(for: conditionStr, pattern: regex)

        if (components.count == 0) {
            return nil
        }

        let propertyName = components[0].hasPrefix("@.") ? String(components[0].dropFirst(2)) : nil
        let op = QueryOperator(rawValue: String(components[1]))!
        var expectedValue: Any = components[2]           
        if let intValue = Int(expectedValue as! String) {
            expectedValue = intValue
        }
        else {
            expectedValue = expectedValue as! String
        }

        return QueryCondition(propertyName: propertyName, op: op, expectedValue: expectedValue)
    }

    private func buildGroup(_ nodes: [QueryNode], _ operators: [ConditionOperator]) -> QueryNode? {
        if nodes.isEmpty { return nil }
        if nodes.count == 1 { return nodes.first }
        
        var combined: [QueryNode] = [nodes[0]]
        for i in 1..<nodes.count {
            combined.append(nodes[i])
        }
        
        return .group(combined, operators.first ?? .and)
    }

    private func evaluateQuery(object: Any, node: QueryNode) -> Bool {
        switch node {
        case .condition(let condition):
            return evaluateCondition(object: object, condition: condition)
        case .group(let nodes, let conditionOperator):
            var result = evaluateQuery(object: object, node: nodes[0])
            for i in 1..<nodes.count {
                let currentResult = evaluateQuery(object: object, node: nodes[i])
                result = (conditionOperator == .and) ? (result && currentResult) : (result || currentResult)
            }
            return result
        }
    }

    private func evaluateCondition(object: Any, condition: QueryCondition) -> Bool {
        if let strObject = object as? String {
            return condition.propertyName == nil && strObject == (condition.expectedValue as? String)
        } else if let dictObject = object as? [String: Any], let key = condition.propertyName {
            if let value = dictObject[key] {
                if condition.op == .regexMatch, let stringValue = value as? String, let regexPattern = condition.expectedValue as? String {
                    return stringValue.range(of: regexPattern, options: .regularExpression) != nil
                }
                if let expected = condition.expectedValue as? String, let actual = value as? String {
                    return (condition.op == .equal) ? (actual == expected) : (actual != expected)
                }
                if let expected = condition.expectedValue as? Int, let actual = value as? Int {
                    switch condition.op {
                    case .equal: return actual == expected
                    case .notEqual: return actual != expected
                    case .greaterThan: return actual > expected
                    case .greaterThanOrEqual: return actual >= expected
                    case .lessThan: return actual < expected
                    case .lessThanOrEqual: return actual <= expected
                    default: return false
                    }
                }
            }
        }
        return false
    }

    func getRegexMatchGroups(for input: String, pattern: String) -> [String] {
        do {
            // Create the regular expression object
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            
            // Define the range of the input string
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            
            // Get the first match
            guard let match = regex.firstMatch(in: input, options: [], range: range) else {
                return []
            }
            
            // Extract all captured groups
            var groups: [String] = []
            for i in 0..<match.numberOfRanges {
                let range = match.range(at: i)
                if range.location != NSNotFound, let swiftRange = Range(range, in: input) {
                    groups.append(String(input[swiftRange]))
                }
            }
            
            return groups
        } catch {
            print("Invalid regex pattern: \(error)")
            return []
        }
    }   

}