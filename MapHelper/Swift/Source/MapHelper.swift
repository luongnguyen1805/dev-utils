import Foundation

extension Array {        
    subscript(of nav: Any...) -> Any? {
        get {
            return MapHelper.getValue(of: self, navigator: nav)
        }
        set(newValue) {
            if (newValue == nil) {
                return
            }
            MapHelper.applyChangeArray(to: &self, navigator: nav, targetValue: MapHelper.TargetValue(mode: .setValue, key: nil, value: newValue!))
        }
    }
}

extension Dictionary {
    subscript(of nav: Any...) -> Any? {
        get {
            return MapHelper.getValue(of: self, navigator: nav)
        }
        set(newValue) {
            if (newValue == nil) {
                return
            }
            MapHelper.applyChangeDictionary(to: &self, navigator: nav, targetValue: MapHelper.TargetValue(mode: .setValue, key: nil, value: newValue!))
        }
    }
}

class MapHelper {
    
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
            return obj
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
            if targetValue.mode == .setValue {
                obj = targetValue.value
            }
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
    
    static func prettyPrint<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(value)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            print("Pretty print failed: \(error)")
        }
    }
}
