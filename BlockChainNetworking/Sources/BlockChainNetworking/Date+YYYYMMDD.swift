//
//  File.swift
//  
//
//  Created by Nicky Taylor on 4/9/24.
//

import Foundation

extension Date {
    
    static func createDate(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        let calendar = Calendar.current
        return calendar.date(from: dateComponents) ?? Date()
    }
    
}
