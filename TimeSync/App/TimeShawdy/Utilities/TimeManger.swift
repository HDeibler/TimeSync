//
//  TimeManger.swift
//  TimeShawdy
//
//  Created by Hunter Deibler on 4/2/24.
//

import Foundation
import SwiftUI



func utcDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}


func localDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    formatter.timeZone = TimeZone.current
    return formatter
}


func convertToDueDate(_ dueAtString: String) -> Date? {
    return utcDateFormatter().date(from: dueAtString)
}



func displayDueDate(_ dueDate: Date) -> String {
    return localDateFormatter().string(from: dueDate)
}

