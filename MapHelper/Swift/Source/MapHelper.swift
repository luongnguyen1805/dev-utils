import Foundation

//MARK: ARRAY EXTENSION
extension Array {
    subscript(of nav: Any...) -> Any? {
        get {
            if let params = nav as? [String] {
                let sel = params[0]
                if sel.starts(with: "$") {
                    let selector = String(sel.dropFirst())
                    
                    let results = MapHelper.executeSelector(self, selector)
                    
                    return results.map { result in
                        let navigator = result.navigator
                        return self[of: navigator]
                    }
                }
            }

            return MapHelper.getValue(of: self, navigator: nav)
        }
        set(newValue) {
            if (newValue == nil) {
                return
            }
            
            if let params = nav as? [String] {
                let sel = params[0]
                if sel.starts(with: "$") {
                    let selector = String(sel.dropFirst())
                                      
                    let results = MapHelper.executeSelector(self, selector)
                    
                    results.forEach {result in
                        let navigator = result.navigator
                        self[of: navigator] = newValue
                    }

                    return
                }
            }

            MapHelper.applyChangeArray(to: &self, navigator: nav, targetValue: MapHelper.TargetValue(mode: .setValue, key: nil, value: newValue!))
        }
    }
}

//MARK: DICTIONARY EXTENSION
extension Dictionary {
    subscript(of nav: Any...) -> Any? {
        get {
            
            if let params = nav as? [String] {
                let sel = params[0]
                if sel.starts(with: "$") {
                    let selector = String(sel.dropFirst())
                    
                    let results = MapHelper.executeSelector(self, selector)
                    
                    return results.map { result in
                        let navigator = result.navigator
                        return self[of: navigator]
                    }
                }
            }
            
            return MapHelper.getValue(of: self, navigator: nav)
        }
        set(newValue) {
            if (newValue == nil) {
                return
            }
            
            if let params = nav as? [String] {
                let sel = params[0]
                if sel.starts(with: "$") {
                    let selector = String(sel.dropFirst())
                                      
                    let results = MapHelper.executeSelector(self, selector)
                    
                    results.forEach {result in
                        let navigator = result.navigator
                        self[of: navigator] = newValue
                    }

                    return
                }
            }
            
            MapHelper.applyChangeDictionary(to: &self, navigator: nav, targetValue: MapHelper.TargetValue(mode: .setValue, key: nil, value: newValue!))
        }
    }
}

//MARK: MAPHELPER
class MapHelper {

    struct Filter {
        var key: String?
        var keySelector: String?

        var index: String?
        var indexSelector: String?
        var indexRangeSelector: String?
    }
    
    struct FilteredRecord {
        var navigator:[Any] = []
        var source: Any?
    }

    struct TargetValue {
        enum Mode {
            case setValue
            case appendValue
            case setKeyValue
        }
        let mode: Mode
        let key: String?
        let value: Any
    }
        
    static func getValue(of obj: Any, navigator: [Any]) -> Any? {
        
        guard !navigator.isEmpty else {
            return nil
        }

        let currentKeyOrIndex = navigator[0]
        let remainingNavigator = Array(navigator.dropFirst())

        if let dict = obj as? [String: Any] {
            if let key = currentKeyOrIndex as? String {
                if remainingNavigator.isEmpty {
                    return dict[key]
                } else if let nextLevel = dict[key] {
                    return getValue(of: nextLevel, navigator: remainingNavigator)
                }
            }
        } else if let array = obj as? [Any] {
            if let index = currentKeyOrIndex as? Int {
                if index >= 0 && index < array.count {
                    if remainingNavigator.isEmpty {
                        return array[index]
                    } else {
                        let nextLevel = array[index]
                        return getValue(of: nextLevel, navigator: remainingNavigator)
                    }
                }
            }
        }
        
        return nil
    }
    
    static func applyChangeArray<Element>(to obj: inout [Element], navigator: [Any], targetValue: TargetValue) {
        var ref: Any = obj
        applyChange(to: &ref, navigator: navigator, targetValue: targetValue)
        if let result = ref as? [Element] {
            obj = result
        } else {
            print("Change not applicable")
        }
    }

    static func applyChangeDictionary<Key,Value>(to obj: inout [Key:Value], navigator: [Any], targetValue: TargetValue) {
        var ref: Any = obj
        applyChange(to: &ref, navigator: navigator, targetValue: targetValue)
        if let result = ref as? [Key:Value] {
            obj = result
        } else {
            print("Change not applicable")
        }
    }

    static func applyChange(to obj: inout Any, navigator: [Any], targetValue: TargetValue) {
        guard !navigator.isEmpty else {
            return
        }

        let currentKeyOrIndex = navigator[0]
        let remainingNavigator = Array(navigator.dropFirst())

        if var dict = obj as? [String: Any] {
            if let key = currentKeyOrIndex as? String {
                if remainingNavigator.isEmpty {
                    switch targetValue.mode {
                    case .setValue:
                        
                        if let valueArray = targetValue.value as? [Any] {
                            if var arr = dict[key] as? [Any] {
                                arr.append(contentsOf: valueArray)
                                dict[key] = arr
                            }
                        }
                        else if let valueDict = targetValue.value as? [String:Any] {
                            if var childDict = dict[key] as? [String:Any] {
                                childDict.merge(valueDict) { _, newValue in
                                    newValue
                                }
                                dict[key] = childDict
                            }
                        }
                        else {
                            dict[key] = targetValue.value
                        }
                        
                    case .setKeyValue:
                        if var childDict = dict[key] as? [String:Any], let targetKey = targetValue.key {
                            childDict[targetKey] = targetValue.value
                            dict[key] = childDict
                        }
                    case .appendValue:
                        if var arr = dict[key] as? [Any] {
                            arr.append(targetValue.value)
                            dict[key] = arr
                        }
                    }
                    
                } else if var nextLevel = dict[key] {
                    applyChange(to: &nextLevel, navigator: remainingNavigator, targetValue: targetValue)
                    dict[key] = nextLevel
                }
                obj = dict
            }
        } else if var array = obj as? [Any] {
            if let index = currentKeyOrIndex as? Int {
                if index >= 0 && index < array.count {
                    if remainingNavigator.isEmpty {
                        
                        switch targetValue.mode {
                        case .setValue:
                            
                            if let valueArray = targetValue.value as? [Any] {
                                if var arr = array[index] as? [Any] {
                                    arr.append(contentsOf: valueArray)
                                    array[index] = arr
                                }
                            }
                            else if let valueDict = targetValue.value as? [String:Any] {
                                if var childDict = array[index] as? [String:Any] {
                                    childDict.merge(valueDict) { _, newValue in
                                        newValue
                                    }
                                    array[index] = childDict
                                }
                            }
                            else {
                                array[index] = targetValue.value
                            }
                                                    
                        case .setKeyValue:
                            if var dict = array[index] as? [String:Any], let targetKey = targetValue.key {
                                dict[targetKey] = targetValue.value
                                array[index] = dict
                            }
                        case .appendValue:
                            if var arr = array[index] as? [Any] {
                                arr.append(targetValue.value)
                                array[index] = arr
                            }
                        }

                    } else {
                        var nextLevel = array[index]
                        applyChange(to: &nextLevel, navigator: remainingNavigator, targetValue: targetValue)
                        array[index] = nextLevel
                    }
                    obj = array
                }
            }
        }
        
    }
    
    static func anyToJSONString(_ value: Any) -> String? {
        
        // Check if the value is a valid JSON object
        guard JSONSerialization.isValidJSONObject(value) else {
            print("Invalid JSON object")
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error serializing JSON: \(error)")
            return nil
        }
        
    }
    
    static func executeSelector(_ obj: Any, _ selector: String) -> [FilteredRecord] {
        
        let queryEngine = QueryEngine()
        var filters:[Filter] = []

        selector.split(separator: "/").forEach { comp in
            let str = String(comp)
            if str.lengthOfBytes(using: .utf8) < 1 {
                return
            }
            
            filters.append(contentsOf: parseFilters(from: str))
        }

        let currentSource = obj
        var results = [
            FilteredRecord(navigator: [], source: currentSource)
        ]
        
        for filter in filters {
            
            var tmp: [FilteredRecord] = []
            
            for record in results {
                
                if let key = filter.key, let dict = record.source as? [String:Any] {
                    
                    let source = dict[key]
                    var navigator = record.navigator
                    navigator.append(key)
                    tmp.append(FilteredRecord(navigator: navigator, source: source))
                    
                } else if let keySelector = filter.keySelector, let dict = record.source as? [String:Any] {
                    
                    let sourceArray = Array(dict.keys)
                    let queryResult = queryEngine.execute(objects: sourceArray, query: keySelector)
                    if let indices = queryResult?.indices {
                        for i in indices {
                            let source = sourceArray[i]
                            var navigator = record.navigator
                            navigator.append(sourceArray[i])
                            tmp.append(FilteredRecord(navigator: navigator, source: dict[source]))
                        }
                    }
                    
                }
                else if let index = Int(filter.index ?? ""), let array = record.source as? [Any] {
                    
                    let source = array[index]
                    var navigator = record.navigator
                    navigator.append(index)
                    tmp.append(FilteredRecord(navigator: navigator, source: source))

                }
                else if let indexSelector = filter.indexSelector ?? filter.indexRangeSelector, let array = record.source as? [Any] {
                    
                    let sourceArray = array
                    let queryResult = queryEngine.execute(objects: sourceArray, query: indexSelector)
                    if let indices = queryResult?.indices {
                        for i in indices {
                            let source = sourceArray[i]
                            var navigator = record.navigator
                            navigator.append(i)
                            tmp.append(FilteredRecord(navigator: navigator, source: source))
                        }
                    }

                }

            }
            
            results = tmp
        }
        
        return results
    }
    
    //MARK: PRIVATE
    private static func parseFilters(from: String) -> [Filter] {
        let regx = #/^((?<keySelector>\?[(\{][^\[\]]+[\}\)])|(?<key>[^\[\]]+))?(\[(?<indexRangeSelector>\d*\.\.-?\d+)\]|\[(?<indexSelector>\?[\(\{][^\[\]]+[\}\)])\]|\[(?<index>\d+)\])?$/#

        var filters: [Filter] = []
        
        if let match = from.firstMatch(of: regx) {
            if let key = match.key {
                filters.append(Filter(key: String(key) ))
            }
            else if let keySelector = match.keySelector {
                filters.append(Filter(keySelector: String(keySelector) ))
            }

            if let index = match.index {
                filters.append(Filter(index: String(index) ))
            }
            else if let indexSelector = match.indexSelector {
                filters.append(Filter(indexSelector: String(indexSelector) ))
            }
            else if let indexRangeSelector = match.indexRangeSelector {
                filters.append(Filter(indexRangeSelector: String(indexRangeSelector) ))
            }
        }
        
        return filters
    }
}
