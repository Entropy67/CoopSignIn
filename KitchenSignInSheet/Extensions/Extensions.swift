//
//  Extensions.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func height(constraintedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.text = self
        label.font = font
        label.sizeToFit()
        label.clipsToBounds = true
        label.lineBreakMode = .byWordWrapping
        return label.frame.height
    }
    
    var bool: Bool? {
        switch self.lowercased() {
        case "true", "t", "yes", "y":
            return true
        case "false", "f", "no", "n", "":
            return false
        default:
            return false
        }
    }
    
    func removeNewLineInQuotes() -> String{
        let regex = try! NSRegularExpression(pattern: "\"[^\"]*\"")
        //let regex = try! NSRegularExpression(pattern: "\"LoA.(...)\"")
        let range = NSMakeRange(0, self.count)
        //let modString = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: " ")
        
        var modString = self
        for result in regex.matches(in: self, range: range){
            let matchRange = result.range
            modString = modString.replacingOccurrences(of: "\n", with: "?n", options: [], range: Range(matchRange, in: modString))
        }
        return modString
    }
}


extension UIViewController {
    /**
     *  Height of status bar + navigation bar (if navigation bar exist)
     */
    var topbarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}


extension UIView{
    
    public var width: CGFloat{
        return self.frame.size.width
    }
    
    
    public var height: CGFloat{
        return self.frame.size.height
    }
    
    public var top: CGFloat{
        return self.frame.origin.y
    }
    
    public var bottom: CGFloat{
        return self.frame.size.height + self.frame.origin.y
    }
    
    
    public var left: CGFloat{
        return self.frame.origin.x
    }
    
    public var right: CGFloat{
        return self.frame.size.width + self.frame.origin.x
    }
    

}


extension UIColor {
    var name: String {
        switch self {
        case UIColor.black: return "black"
        case UIColor.darkGray: return "darkGray"
        case UIColor.lightGray: return "lightGray"
        case UIColor.white: return "white"
        case UIColor.gray: return "gray"
        case UIColor.red: return "red"
        case UIColor.green: return "green"
        case UIColor.blue: return "blue"
        case UIColor.cyan: return "cyan"
        case UIColor.yellow: return "yellow"
        case UIColor.magenta: return "magenta"
        case UIColor.orange: return "orange"
        case UIColor.purple: return "purple"
        case UIColor.brown: return "brown"
        default: return "unNamed"
        }
    }
}


extension Date
{

  func dateAt(hours: Int, minutes: Int) -> Date
  {
    let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!

    //get the month/day/year componentsfor today's date.


    var date_components = calendar.components(
      [NSCalendar.Unit.year,
       NSCalendar.Unit.month,
       NSCalendar.Unit.day],
      from: self)

    //Create an NSDate for the specified time today.
    date_components.hour = hours
    date_components.minute = minutes
    date_components.second = 0

    let newDate = calendar.date(from: date_components)!
    return newDate
  }
    
    var nearest30Min: Date {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        guard let hours = dateComponents.hour else {
            LogManager.writeLog(info : "date extension error: failed to get hour in nearest30Min")
            return self
            
        }

        switch dateComponents.minute ?? 0 {
        case 0...14:
            dateComponents.minute = 0
        case 15...44:
            dateComponents.minute = 30
        case 44...59:
            dateComponents.minute = 0
            dateComponents.hour = hours + 1
        default:
            break
        }
        if let date = Calendar.current.date(from: dateComponents){
            return date
        }else{
            LogManager.writeLog(info : "date extension error: failed to get date in nearest30Min")
            return self
        }
    }
    
    
}
