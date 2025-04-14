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
            let targetValue = MapHelper.TargetValue(mode: .setValue, key: nil, value: newValue!)
            MapHelper.applyChangeArray(to: &self, navigator: nav, targetValue: targetValue)
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
            let targetValue = MapHelper.TargetValue(mode: .setValue, key: nil, value: newValue!)
            MapHelper.applyChangeDictionary(to: &self, navigator: nav, targetValue: targetValue)
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
        obj = ref as! [Element]
    }

    static func applyChangeDictionary<Key,Value>(to obj: inout [Key:Value], navigator: [Any], targetValue: TargetValue) {
        var ref: Any = obj
        applyChange(to: &ref, navigator: navigator, targetValue: targetValue)
        obj = ref as! [Key:Value]
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
                        dict[key] = targetValue.value
                    case .setKeyValue:
                        if let targetKey = targetValue.key {
                            dict[targetKey] = targetValue.value
                        }
                    default:
                        break // Ignore other modes at this level
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
                        if targetValue.mode == .appendValue {
                            array.append(targetValue.value)
                        } else if targetValue.mode == .setValue {
                            array[index] = targetValue.value
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
