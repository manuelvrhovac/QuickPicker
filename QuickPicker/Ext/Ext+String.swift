// swiftlint:disable all
//  Created by Manuel Vrhovac on 06/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation

extension String {
    
    var ns: NSString {
        return self as NSString
    }
    
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
    
    func emptyIf(_ condition: Bool) -> String {
        return onlyIf(!condition)
    }
    
    func onlyIf(_ condition: Bool) -> String {
        return condition ? self : ""
    }
    
    func nilIfEquals(_ match: String) -> String? {
        return self == match ? nil : self
    }
    
    func nilIfContains(_ match: String) -> String? {
        return self.contains(match) ? nil : self
    }
    
    var length: Int { return self.count }
    
    var alphanumerics: (prefix: String, middle: String, suffix: String) {
        let i: [Int] = enumerated().compactMap { return $1.isAlphaNumeric ? $0 : nil }
        if i.isEmpty { return (self, "", "") }
        return(until(i.first!), from(i.first!, until: i.last!+1), from(i.last!+1))
    }
    
    /// Capitalizes only first character
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    /// Returns a string with first character capitalized
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    /// Returns true if string contains any of the strings
    func containsAny(_ strings: String...) -> Bool {
        var found = false
        strings.forEach { if self.contains($0) { found = true } }
        return found
    }
    
    /// Returns true if string equals any of the strings
    func equalsAny(_ strings: String...) -> Bool {
        return strings.contains(self)
    }
    
    /// Returns true only if string contains all passed strings
    func containsAll(_ strings: String...) -> Bool {
        var found = true
        strings.forEach { if !self.contains($0) { found = false } }
        return found
    }
    
    
    func replacingExt(with newExt: String) -> String {
        return self.fileRemovingExtension + "." + newExt.removingPrefix(".")
    }
    
    init!(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        guard let contents = try? String(contentsOf: url) else { return nil }
        self = contents
    }
    
    var lowerCamelCase: String {
        if isEmpty { return self }
        if count == 1 { return self.lowercased() }
        if until(2) == until(2).uppercased() {
            return self.removing(" ")
        }
        return (until(1).lowercased() + from(1)).removing(" ")
    }
    
    var fileLowercaseExtension: String {
        return URL(fileURLWithPath: self).pathExtension.lowercased()
    }
    
    /// File lowecase extension (without dot)
    var lowExt: String {
        return fileLowercaseExtension
    }
    
    var fileLastComponent: String {
        return URL(fileURLWithPath: self).lastPathComponent
    }
    
    var fileRemovingExtension: String {
        return URL(fileURLWithPath: self).deletingPathExtension().path
    }
    
    var fileFolderName: String {
        return URL(fileURLWithPath: self).deletingLastPathComponent().lastPathComponent
    }
    
    var addingQuotes: String {
        return "\""+self+"\""
    }
    
    
    var convertPlistToDictionary: [String: Any]? {
        guard let data = self.data(using: String.Encoding.utf8, allowLossyConversion: true) else { return nil }
        let opt = PropertyListSerialization.ReadOptions(rawValue: 0)
        let converted = try? PropertyListSerialization.propertyList(from: data, options: opt, format: nil)
        return converted as? [String: Any]
    }
    
    
}

// MARK: - Useful for parsing

extension String {
    
    
    /// Returns a string with removed passed occurences
    func removing(_ stringsToRemove: String...) -> String {
        var new = ""+self
        for toRemove in stringsToRemove {
            new = new.replacingOccurrences(of: toRemove, with: "")
        }
        return new
    }
    
    func replacing(strings: [String], with: String) -> String {
        var new = self
        for string in strings {
            new = new.replacingOccurrences(of: string, with: with)
        }
        return new
    }
    
    func replacing(_ string: String, with: String) -> String {
        return self.replacingOccurrences(of: string, with: with)
    }
    
    func removing(_ stringsToRemove: [String]) -> String {
        var new = ""+self
        for toRemove in stringsToRemove {
            new = new.replacingOccurrences(of: toRemove, with: "")
        }
        return new
    }
    
    
    func from(_ s: Int, until: Int) -> String {
        if self.length - 1 < s || until > self.length {
            print("wrong")
        }
        let range = NSRange(location: s, length: until - s)
        return (self as NSString).substring(with: range) as String
    }
    
    func from(_ s: Int) -> String {
        return (self as NSString).substring(from: s)
    }
    
    func until(_ s: Int) -> String {
        return (self as NSString).substring(to: s)
    }
    
    func startsWith(_ s: String) -> Bool {
        if self.count < s.count { return false }
        return s == self.from(0, until: s.count)
    }
    
    func endsWith(_ s: String) -> Bool {
        if self.count < s.count { return false }
        return s == self.from(self.count - s.count, until: self.count)
    }
    
    func from(_ s: String, include: Bool = false) -> String {
        if !self.contains(s) { return self }
        let ns = self as NSString
        var r = ns.range(of: s).location
        if r == NSNotFound { r = -1 }
        return self.from(r ==  -1 ? 0 : include ? r : r + s.length)
    }
    
    func until(_ s: String, include: Bool = false) -> String {
        if !self.contains(s) { return self }
        let ns = self as NSString
        let r = ns.range(of: s).location
        return self.until(r == -1 ? 0 : include ? r + s.length : r)
    }
    
    func from(_ s: String, until: String, include: Bool = false) -> String {
        if !self.contains(s) { return self }
        if !self.contains(until) { return self }
        return self.from(s, include: include).until(until, include: include)
    }
    
    func takeBetween(_ start: String, end: String) -> [String] {
        guard !isEmpty else { return [] }
        return self.from(start).components(separatedBy: start)
            .filter { $0.contains(end) }
            .map { $0.until(end) }
    }
}

// MARK: - Other

extension String {
    
    /*
     func takeBetween(s1: String, s2: String) -> [String] {
     var strings = [String]()
     var work = self
     while !work.isEmpty {
     guard
     let loc1 = location(of: s1),
     let loc2 = location(of: s2)
     else { return strings }
     strings.append(work.from(loc1, until: loc2))
     work = work.from(loc2)
     }
     return strings
     }*/
    
    func range(of string: String) -> NSRange {
        return (self as NSString).range(of: string)
    }
    
    func location(of string: String) -> Int? {
        let loc = range(of: string).location
        return (loc == NSNotFound) ? nil : loc
    }
    
    
    func padded(_ length: Int) -> String {
        if self.length >= length { return self }
        let spaces = repeatElement(" ", count: length - self.length).joined()
        return self + spaces
    }
    
    func paddedBeginning(_ length: Int) -> String {
        if self.length >= length { return self }
        let spaces = repeatElement(" ", count: length - self.length).joined()
        return spaces + self
    }
    
    func paddedZeroes(_ length: Int) -> String {
        return self.padding(toLength: length, withPad: "0", startingAt: 0)
    }
    
    static func loadFromUrl(_ string: String) -> String {
        guard let url = URL(string: string) else { return "BAD URL" }
        let loaded = try? String(contentsOf: url)
        return loaded ?? "COULDN'T LOAD URL"
    }
    
    /// Removes suffix if exists. If failed, returns self.
    func removingSuffix(_ suffix: String) -> String {
        if self.isEmpty || suffix.isEmpty || !hasSuffix(suffix) { return self }
        return self.from(0, until: count - suffix.count)
    }
    
    /// Removes prefix if exists. If failed, returns self.
    func removingPrefix(_ prefix: String) -> String {
        if self.isEmpty || prefix.isEmpty || !hasPrefix(prefix) { return self }
        return self.from(prefix.count)
    }
    
    
    /// Replaces all dashes (-) and undescores (_) for capitalized next letter. Capitalizes first letter. Example: "My-date" -> "myDate"
    var camelCased: String {
        return self.replacingOccurrences(of: "-", with: "_")
            .components(separatedBy: "_")
            .enumerated()
            .map { index, key in index > 0 ? key.capitalized : key }
            .joined()
    }
    
    /// Replaces all capitalized next letters with spaces. Capitalizes each first letter. Example: "myDate" -> "My Date"
    var revertCamelCased: String {
        var s = self
        let indexes = self.enumerated().filter { $0.element.isUpperCase }.map { $0.offset }
        let components = indexes.map { (i) -> String in let part = s.until(i) ; s = s.until(i) ; return part }
        return components.filter { !$0.isEmpty }
            .map { $0.capitalizingFirstLetter() }
            .joined(separator: " ")
    }
    
    init(link: String) {
        if let contents = try? String(contentsOf: URL(string: link)!) {
            self = contents
        } else {
            fatalError("coulnd't download link")
        }
    }
    
    var urll: URL {
        return URL(string: self)!
    }
    
    var urlp: URL {
        return URL(fileURLWithPath: self)
    }
    
}
