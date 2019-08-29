// swiftlint:disable all
//
//  Created by Manuel Vrhovac on 06/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation

let backtick = "   `   " // `

func delayIf(
    _ condition: Bool,
    backgroundIf: Bool = false,
    _ seconds: Double,
    _ completion: @escaping () -> Void
    ) {
    delay(if: condition, backgroundIf: backgroundIf, seconds, completion)
}

func delayBackground(
    if condition: Bool = true,
    _ seconds: Double,
    _ completion: @escaping () -> Void
    ) {
    delay(if: condition, backgroundIf: true, seconds, completion)
}

func delay(
    if condition: Bool = true,
    backgroundIf: Bool = false,
    _ seconds: Double,
    _ completion: @escaping () -> Void
    ) {
    guard condition else { return }
    guard seconds > 0 else { return completion() }
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        if backgroundIf {
            backgroundThread {
                completion()
            }
        } else {
            mainThread {
                completion()
            }
        }
        
    }
}

func mainThread(if condition: Bool = true, closure: @escaping () -> Void) {
    guard condition else { return }
    DispatchQueue.main.async {
        closure()
    }
}

/// Executes block in background - global(qos: .background).async.
func backgroundThread(if condition: Bool = true, closure:@escaping () -> Void) {
    guard condition else { return }
    DispatchQueue.global(qos: .background).async {
        closure()
    }
}


/// Executes on background thread if flag set to true. Otherwise just calls the closure synchronously.
func thread(background: Bool, closure: @escaping () -> Void) {
    if background {
        backgroundThread(closure: closure)
    } else {
        closure()
    }
}

/// Executes on main thread if flag set to true. Otherwise just calls the closure synchronously.
func thread(main: Bool, closure: @escaping () -> Void) {
    if main {
        mainThread(closure: closure)
    } else {
        closure()
    }
}

extension Bool {
    
    static var random: Bool {
        return arc4random() % 2 == 0
    }
}

extension Double {
    
    /// Returns a random double between two specified numbers (irregardless > or <)
    static func randomBetween(_ d1: Double, until d2: Double) -> Double {
        return d2 > d1
            ? d1 + (d2 - d1) * random1
            : d2 + (d1 - d2) * random1
    }
    
    /// Returns a random doubel between self and d1 (irregardless > or <)
    func randomBetween(_ d1: Double) -> Double {
        return Double.randomBetween(d1, until: self)
    }
    
    /// Returns a random number between 0.0 and 1.0
    static var random1: Double {
        return Double(arc4random()) / Double(UINT32_MAX)
    }
    
    var strRounded2: String {
        return .init(format: "%.2f", self)
    }
    
    var strRounded1: String {
        return .init(format: "%.1f", self)
    }
}

extension Int {
    
    static var random: Int {
        return Int(arc4random() % UInt32.max)
    }
    
    /// Limits the number by some array count
    func overflow(byArray array: [Any]) -> Int? {
        return fixOverflow(count: array.count)
    }
    
    /// If count is 30 it will return: 5 for 5, 0 for 30, 1 for 31, 29 for -1, 0 16 for -14 etc...
    func fixOverflow(count: Int) -> Int {
        return self >= 0 ? (self < count ? self : self % count) : count - abs(self) % count
    }
    
    /// Returns yes if negative or equal/bigger than count.
    func isOverflown(count: Int) -> Bool {
        return self < 0 || self >= count
    }
    
    var strBar: String {
        if self == 0 { return "" }
        return "" + Array(repeating: "■", count: self).joined()
    }
    
    /// padded to 2 characters (extra is cut)
    var str2: String {
        return strPadded(places: 2)
    }
    
    /// padded to 3 characters (extra is cut)
    var str3: String {
        return strPadded(places: 2)
    }
    
    /// padded to 4 characters (extra is cut)
    var str4: String {
        return strPadded(places: 2)
    }
    
    /// padded to X characters (extra is cut)
    func strPadded(places: Int) -> String {
        return "\(self)".padded(places)
        //return String(format: "%0\(places)d", self).until(places)
    }
    
}

extension Array where Element == String {
    // MARK: String
    var joinedWithNewline: String {
        return self.joined(separator: "\n")
    }
}

extension Array {
    
    mutating func shuffle() {
        for _ in 0 ..< ((!isEmpty) ? (count - 1) : 0) {
            sort { (_, _) in arc4random() < arc4random() }
        }
    }
    
    var shuffled: Array {
        var a = self
        a.shuffle()
        return a
    }
    
    var nextToLast: Element? {
        if self.count < 2 { return nil }
        return self[self.count - 2]
    }
    
    var random: Element? {
        if isEmpty { return nil }
        return self[Int.random % count]
    }
    
    subscript (overflow index: Int) -> Element? {
        let i = index.fixOverflow(count: self.count)
        return self[safe: i]
    }
    
    @discardableResult
    mutating func removeFirstIfExists() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
    
    @discardableResult
    mutating func removeLastIfExists() -> Element? {
        guard !isEmpty else { return nil }
        return removeLast()
    }
    
    func removingFirst() -> [Element] {
        var array = self
        array.removeFirstIfExists()
        return array
    }
    
    func removingLast() -> [Element] {
        var array = self
        array.removeLastIfExists()
        return array
    }
    
    /// Enumerates array and returns a dictionary with indexes as keys. Like: [0: array[0], 1: array[1]...]
    var enumeratedDic: [Int: Element] {
        return self.enumerated().map { $0 }.mapDic { ($0, $1) }
    }
    
    /// Returns array with elements successfully typecasted to specified type
    func compactMapAs<T: AnyObject>(_ type: T.Type) -> [T] {
        return compactMap { $0 as? T }
    }
    
    /// Converts array to dictionary using transform closure which should take each array element and return a (key,value) tuple. Value can be nil (optional).
    func mapDic<Key: Hashable, Value>(transform: (Element) -> (Key, Value?)) -> [Key: Value] {
        var dic: [Key: Value] = [:]
        for element in self {
            let (key, value) = transform(element)
            guard value != nil else { continue }
            dic[key] = value
        }
        return dic
    }
    
    /// Converts array to dictionary using transform closure which should take each array element and return a value. Array element are used as the key. Value can be nil (optional).
    func selfMapDic<U>( transform: (Element) -> (U?)) -> [Element: U] {
        return mapDic { ($0, transform($0)) }
    }
}

extension Array where Element: Equatable {
    
    func removingDuplicates() -> [Element] {
        var newArray = [Element]()
        for value in self {
            if newArray.contains(value) == false {
                newArray.append(value)
            }
        }
        return newArray
    }
}

extension Dictionary where Key == String {
    /*var niceSimplePrint: String {
     let maxL = keys.map{$0.count}.max() ?? 20
     return "[\n" + map { " \($0.key.padded(maxL+3)): \($0.value)" }.joinedNewline + "\n]"
     }*/
}




extension Dictionary {
    
    var valuesArray: [Value] {
        return map { $0.value }
    }
    
    
    
    func valuesAs<T>(_ type: T.Type) -> [T] {
        return valuesArray.compactMap { $0 as? T }
    }
    
    /// Returns a new dictionary by converting it with transform closure that gives a (key,value) tuple and expects a new (key,value) tuple.
    func mapDic<T: Hashable, U>( transform: (Key, Value) -> (T, U)) -> [T: U] {
        var result: [T: U] = [:]
        for (key, value) in self {
            let (transformedKey, transformedValue) = transform(key, value)
            result[transformedKey] = transformedValue
        }
        return result
    }
    
    
    /// Returns a new filtered dictionary using 'test' closure that gives a (key,value) tuple and expects a Bool.
    func filterDic( test: (Key, Value) -> (Bool)) -> [Key: Value] {
        var result: [Key: Value] = [:]
        for (key, value) in self where test(key, value) == true {
            result[key] = value
        }
        return result
    }
    
    subscript(optional optKey: Key?) -> Value? {
        return optKey.flatMap { self[$0] }
    }
    
    
    func mapDicThrow<T: Hashable, U>( transform: (Key, Value) throws -> (T, U)) rethrows -> [T: U] {
        var result: [T: U] = [:]
        for (key, value) in self {
            let (transformedKey, transformedValue) = try transform(key, value)
            result[transformedKey] = transformedValue
        }
        return result
    }
}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}

extension Character {
    
    var isUpperCase: Bool {
        return String(self) == String(self).uppercased()
    }
    
    var isNumber: Bool {
        return self >= "0" && self <= "9"
    }
    
    var isLetter: Bool {
        return self >= "A" && self <= "z"
    }
    
    var isAlphaNumeric: Bool {
        return isNumber || isLetter
    }
    
}

extension NSString {
    
    var s: String { return self as String }
}

extension Optional where Wrapped == String {
    
    var isNilOrEmpty: Bool { return self == nil ? true : self!.isEmpty ? true : false }
}

extension CaseIterable {
    
    static var random: Self? {
        return Array(allCases).random
    }
}

extension Date {
    
    var getHour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    var getMinute: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    var getSecond: Int {
        return Calendar.current.component(.second, from: self)
    }
    
    /// Returns day of month, for example 2019/05/27 returns 27.
    var getDay: Int {
        return Calendar.current.ordinality(of: .day, in: .month, for: self)!
    }
    
    /// Returns day of month, for example 2019/05/27 returns 27.
    var getDayOfMonth: Int {
        return Calendar.current.ordinality(of: .day, in: .month, for: self)!
    }
    
    /// Returns weekday index (Mon=1, Tue=2...).
    var getDayOfWeek: Int {
        let wd = Calendar.current.component(.weekday, from: self)
        return wd == 1 ? 7 : wd - 1
    }
    
    var getDayOfYear: Int {
        return Calendar.current.ordinality(of: .day, in: .year, for: self)!
    }
    
    var getWeekOfYear: Int {
        return Calendar.current.component(.weekOfYear, from: self)
    }
    
    /// Jan=1, Feb=2...
    var getMonth: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    var getYear: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /// Removes hours/minutes/seconds from a date leaving it at exactly midnight (00:00:00)
    var getPureDate: Date {
        return Date.from(year: self.getYear, month: self.getMonth, day: self.getDayOfMonth)
    }
    
    var getSecondsInDay: Int {
        return self.getHour * 60 * 60 + self.getMinute * 60 + self.getSecond
    }
    
    func msSince(_ date: Date) -> Int {
        return Int(self.timeIntervalSince(date) * 1000)
    }
    
    
    static func from(year: Int, month: Int, day: Int) -> Date {
        return Date(year: year, month: month, day: day)
    }
    
    init!(year: Int, month: Int, day: Int) {
        guard let date = Date(Y: year, M: month, D: day, h: 0, m: 0, s: 0) else {
            return nil
        }
        self = date
    }
    
    init!(Y: Int, M: Int, D: Int, h: Int, m: Int, s: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = Y
        dateComponents.month = M
        dateComponents.day = D
        dateComponents.hour = h
        dateComponents.minute = m
        dateComponents.second = s
        let calendar = NSCalendar(calendarIdentifier: .gregorian)
        guard let date = calendar?.date(from: dateComponents), D == date.getDay else {
            return nil
        }
        self = date
    }
    
    
    init?(string: String?, format: String) {
        guard let string = string else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        guard let date = dateFormatter.date(from: string) else {
            return nil
        }
        self = date
    }
    
    init?(string: String?, formatter: DateFormatter, timeZone: TimeZone = .current) {
        formatter.timeZone = timeZone
        guard let string = string, let date = formatter.date(from: string) else { return nil }
        self = date
    }
    
    /// Format like 2019:05:27 03:20:48+02:00 (FileModifyDate), 2010:06:24 14:17:04 (CreateDate), or 2010:06:24 10:17:21Z (GPSDateTime)
    init?(metadataString: String?, defaultTimeZone: TimeZone = .current) {
        guard let string = metadataString else { return nil }
        let count = string.count
        //Fri Feb 03 11:52:46 2006
        if count == 24, let date = Date(string: string, formatter: .flvMetadata) {
            self = date
            return
        }
        if string.containsAny("PM", "AM") && string.contains("/") {
            if let date = Date(string: string, formatter: .usaMDYHMa) {
                self = date
                return
            }
        }
        guard count >= 19 && count < 30 else { return nil }
        let zone = string.from(19).nilIfEmpty
        //let hasZone = zone != nil
        let dateAndTime = string.until(19).replacing("-", with: ":").replacing("T", with: " ")
        let dateStr = dateAndTime + (zone ?? "Z")
        guard let date = Date(string: dateStr, formatter: .exifDateTimeOriginalZoned) else {
            return nil
        }
        self = date
    }
    
    /// Returns (dateTimeOriginal: "2019:12:31 23:59:59", offset: "+01:00") for NYE in Paris. See description for more!
    ///
    /// Supply any date string found in metadata and gps stamp if available. If you suspect the string won't contain utc offset (like +02:00) and no gps, then define default time zone (optionally) to avoid getting nil for utc offset.
    ///
    /// - string can contain utc offset like "2019-12-31T23:59:59+02:00"
    /// - In case string doesn't have offset (normally DateTimeOriginal in exif never does), gps date and time stamp could help to determine the offset. Time difference will be calculated and rounded by 15 min (like +02:00 or +07:45).
    /// - In case gps is not available, a specific timeZone can be set. In this case, offset is guaranteed to be returned.
    /// - When no gps or timzone defined, nil will be returned as offset.
    ///
    /// **Other supported date formats**:
    /// - 2019-12-31T23:59:59+02:00
    /// - Fri Feb 03 11:52:46 2006
    /// - 8/16/17 12:24 PM
    
    static func getDTOAndOffset(
        string: String?,
        gpsDateStamp: String? = nil,
        gpsTimeStamp: String? = nil,
        timeZone: TimeZone?
        ) -> (dateTimeOriginal: String, offset: String?)? {
        guard let string = string else { return nil }
        let count = string.count
        if count == 24, let date = Date(string: string, formatter: .flvMetadata) {
            //Fri Feb 03 11:52:46 2006
            return (date.exifDateTimeOriginal, nil)
        }
        if string.containsAny("PM", "AM") && string.contains("/") {
            if let date = Date(string: string, formatter: .usaMDYHMa) {
                return (date.exifDateTimeOriginal, nil)
            }
        }
        guard count >= 19 && count < 30 else { return nil }
        let dateTimeOriginal = string.until(19).replacing("-", with: ":").replacing("T", with: " ")
        guard let date = Date(string: dateTimeOriginal, formatter: .exifDateTimeOriginal, timeZone: .utc) else {
            return nil
        }
        if let offset = string.from(19).nilIfEmpty, offset.count == 6 && offset.containsAny("+", "-") && offset.contains(":") {
            return (date.exifDateTimeOriginal, offset)
        }
        var minDif: Int!
        if let gpsdate = gpsDateStamp?.replacing(":", with: "-"), let gpstime = gpsTimeStamp?.until(".") {
            let gpsIsoString = gpsdate + "T" + gpstime + "Z"
            if let utcDate = Date(string: gpsIsoString, formatter: .iso8601zoned) {
                // gps may be few minutes different. But the timezones are either 1h, 30min or very rare 15 min.
                // let's say 44 min ahead, that would be time zone with 45 min offset! (rare)
                minDif = Int(date.timeIntervalSince(utcDate)/60)
                // 44 to double -> 44.0 / 15 -> 2.93 -> 3.0 to int -> 3 * 15 -> 45
                minDif = Int((Double(minDif)/15.0).rounded()) * 15
            }
        }
        if minDif == nil, let timeZone = timeZone {
            minDif = timeZone.secondsFromGMT(for: date) / 60
        }
        if let dif = minDif {
            let plusMinus = minDif > 0 ? "+" : "-"
            let offset = plusMinus + String(format: "%02d:%02d", dif / 60, dif % 60)
            return (dateTimeOriginal, offset)
        }
        return (date.exifDateTimeOriginal, nil)
    }
    
    /// Adds x * 60 seconds
    func addingMinutes(_ m: Double) -> Date {
        return self.addingTimeInterval(m * 60)
    }
    
    /// Adds x * 60 seconds
    func addingMinutes(_ m: Int) -> Date {
        return addingMinutes(Double(m))
    }
    
    /// Adds x * 60 seconds
    func addingMinutes(_ m: Float) -> Date {
        return addingMinutes(Double(m))
    }
    
    /// Adds x * 86400 seconds
    func addingDays(_ d: Double) -> Date {
        return self.addingTimeInterval(d * 86_400.0)
    }
    
    /// Adds x * 86400 seconds
    func addingDays(_ d: Float) -> Date {
        return addingDays(Double(d))
    }
    
    /// Adds x * 86400 seconds
    func addingDays(_ d: Int) -> Date {
        return addingDays(Double(d))
    }
    
    /// Changes the day value in calendar, taking leap seconds into account.
    func addingCalendarDays(_ d: Int) -> Date {
        let cal = Calendar(identifier: .gregorian)
        return cal.date(byAdding: .day, value: d, to: self, wrappingComponents: true)!
    }
    
    /// Changes the day value in calendar, taking leap seconds into account.
    func addingCalendarYears(_ d: Int) -> Date {
        let cal = Calendar(identifier: .gregorian)
        return cal.date(byAdding: .year, value: d, to: self, wrappingComponents: true)!
    }
    
    /// Adds 86400 seconds
    var addingOneDay: Date {
        return self.addingTimeInterval(60.0 * 60.0 * 24.0)
    }
    
    
    /// Sets the miliseconds (if any) to 0.
    var strippingMilis: Date {
        let ti = self.timeIntervalSince1970
        return Date(timeIntervalSince1970: ti - ti.truncatingRemainder(dividingBy: 1.0))
    }
    
    /// Returns string in format "YYYY-MM-dd HH:mm:ss"
    var YYYYMMDDHHMMSS: String {
        return DateFormatter.yyyymmdd_hhmmss.string(from: self)
    }
    
    /// Returns string in format "YYYY-MM-dd"
    var YYYYMMDD: String {
        return DateFormatter.yyyymmdd.string(from: self)
    }
    
    var HHMM: String {
        return DateFormatter.hhmm.string(from: self)
    }
    
    var HHMMSS: String {
        return DateFormatter.hhmmss.string(from: self)
    }
    
    /// "yyyy-MM-dd'T'HH:mm:ssZ"
    var iso8601Zoned: String {
        return DateFormatter.iso8601zoned.string(from: self)
    }
    
    /// "yyyy-MM-dd'T'HH:mm:ss"
    var iso8601: String {
        return DateFormatter.iso8601.string(from: self)
    }
    
    /// "YYYY:MM:dd HH:mm:ss"
    var exifDateTimeOriginal: String {
        return DateFormatter.exifDateTimeOriginal.string(from: self)
    }
    
}

extension TimeZone {
    
    static let utc = TimeZone(abbreviation: "UTC")!
}

extension DateFormatter {
    
    convenience init(df: String) {
        self.init()
        dateFormat = df
    }
    
    /// "YYYY-MM-dd"
    static let yyyymmdd: DateFormatter = .init(df: "YYYY-MM-dd")
    
    /// "HH:mm"
    static let hhmm: DateFormatter = .init(df: "HH:mm")
    static let hhmmss: DateFormatter = .init(df: "HH:mm:ss")
    
    /// "YYYY-MM-dd HH:mm:ss"
    static let yyyymmdd_hhmmss: DateFormatter = .init(df: "YYYY-MM-dd HH:mm:ss")
    
    /// "YYYY:MM:dd HH:mm:ss"
    static let exifDateTimeOriginal: DateFormatter = .init(df: "YYYY:MM:dd HH:mm:ss")
    
    static let exifDateTimeOriginalZoned: DateFormatter = .init(df: "YYYY:MM:dd HH:mm:ssZ")
    
    /// "yyyy-MM-dd'T'HH:mm:ssZ"
    static let iso8601: DateFormatter = .init(df: "yyyy-MM-dd'T'HH:mm:ssZ")
    
    static let urlSafeYMDHSM: DateFormatter = .init(df: "yyyy-MM-dd-HH-mm-ss-SSSS")
    
    /// "2019-12-31T23:59:59+02:00"
    static let iso8601zoned: DateFormatter = .init(df: "yyyy-MM-dd'T'HH:mm:ssZ")
    
    static let exifRenamer: DateFormatter = .init(df: "yyyy-MM-dd_HH-mm-ss")
    static let exifRenamerNew: DateFormatter = .init(df: "yyyy_MM_dd HH-mm-ss")
    
    static let debugging: DateFormatter = .init(df: "yyyy-MM-dd HH:mm:ssZ")
    
    static let flvMetadata: DateFormatter = .init(df: "EEE MMM dd HH:mm:ss YYYY")
    
    /// 8/16/17 12:24 PM
    static let usaMDYHMa: DateFormatter = .init(df: "M/d/YY HH:mm a")
    
    /// 8/16/17 12:24:59 PM
    static let usaMDYHMSa: DateFormatter = .init(df: "M/d/YY HH:mm:ss a")
    
    
    
    
}


final class ControlAction: NSObject {
    
    private let _action: () -> Void
    init(action: @escaping () -> Void) {
        _action = action
        super.init()
    }
    @objc
    func action() {
        _action()
    }
}

class Stopwatch {
    
    var startTime = Date()
    var counter = 0
    
    var elapsedMS: Int {
        return Int(Date().timeIntervalSince(startTime) * 1000)
    }
    
    func lap() {
        print("⏱\(counter) \(elapsedMS) ms")
        counter += 1
    }
    
    func r() {
        startTime = .init()
        counter = 0
    }
    
    func since() {
        lap()
        r()
    }
    
    init() {
        
    }
}
