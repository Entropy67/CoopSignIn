//
//  DateManager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/19/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import Foundation


final class DateManager{
    
    public static let defaultDate = Date(timeIntervalSince1970: 0)
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()
    
    
    public static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static func dayStringToNumber(day: String) -> Int{
        switch day{
        case "SU", "Su", "su", "Sunday", "Sun":
            return 1
        case "MO", "Mo", "mo", "m", "M", "Monday", "Mon":
            return 2
        case "TU", "Tu", "tu", "Tuesday", "Tue":
            return 3
        case "WE", "We", "we", "w", "W", "Wednesday", "Wed":
            return 4
        case "TH", "Th", "th", "Thursday", "Thu", "Thur":
            return 5
        case "FR", "Fr", "fr", "f", "F", "Friday", "Fri":
            return 6
        case "SA", "Sa", "sa", "Saturday", "Sat":
            return 7
        default:
            return 8
        }
    }
    
    static func getWeekdayName(day: String) -> String?{
        let weekdayName = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let index = dayStringToNumber(day: day)
        if index < 8{
            return weekdayName[index - 1]
        }
        return nil
    }
    
    
    
    static func dateToString(date: Date, format: String = "HH:mm") -> String{
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = format
        if date != Date(timeIntervalSince1970: 0){
           return formatter.string(from: date)
        }
        return ""
    }

    static func stringToDate(string: String) -> Date{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH:mm"
        
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy-MM-dd-"
        
        let time = formatter2.string(from: Date()) + string
        if string != ""{
            //print("<<<< conver time: \(time)")
            return  formatter.date(from: time) ?? DateManager.defaultDate
        }
        return DateManager.defaultDate
    }
    
    static func isSameDay(date1: Date, date2: Date) -> Bool {
        //Here’s a quick function to check if two dates are from the same day:
        if NSCalendar.current.isDate(date1, inSameDayAs:date2) == true{
            return true
        }
        return false
    }
    
    static func getDayNumber(date: Date) -> Int{
        return Calendar.current.component(.weekday, from: date)
    }
    
    static func getYear(date: Date) -> Int{
        return Calendar.current.component(.year, from: date)
    }
    
    static func getWeekOfYear(date: Date) -> Int{
        return Calendar.current.component(.weekOfYear, from: date)
    }
    
    
    static func isWeekend(date: Date)->Bool{
        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 || weekday==7{
            return true
        }else{
            return false
        }
    }
    
    
    static func getHoursDiff(start: Date, end: Date)->Int{
        let diffComponents = Calendar.current.dateComponents([.day, .hour], from: start, to: end)
        
        let hours = diffComponents.hour ?? 0
        let day = diffComponents.day ?? 0
    
        return day * 24 + hours
    }
    
    
    static func getMinutesDiff(start: Date, end: Date) -> Int{
        
        let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: start, to: end)
        
        let hours = diffComponents.hour ?? 0
        let minutes = diffComponents.minute ?? 0
    
        return hours * 60 + minutes
    }
    
    static func getSection(date: Date, compactMode: Bool = false) -> Int{
        let hour = Calendar.current.component(.hour, from: date)
        
        if compactMode{
            if hour < 13{
                return 0
            }else{
                return 1
            }
        }
        
        // locate section according to date
        var section = 0
        
        var timePoints = [6, 10, 14, 17, 21]
        
        if DateManager.isWeekend(date: Date()){
            timePoints = [8, 12, 16, 17, 21]
        }
        
        
        if hour < 6 || hour >= 21{
            section = 5
        }else{
            while(hour >= timePoints[section]){
                section += 1
            }
        }
        return max(0, section - 1)
    }
    

}
