//
//  Members.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/3/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

/// this class should be named as "Shift"
/// however, since I used "Member" at the beginning, I kept using it all the time, even though it really means "Shift" instead of "Member"
/// change this name will cause error when the iPad is reading history data. The only way to fix the error is to delete the APP on iPad and restall it again. By doing so, all the historical records are gone.
class Member: NSObject, NSCoding, Element{
    let id:String
    let identifier: String
    let name: String
    let deposit: Int
    let room: String
    
    let role: String
    let shiftType: String // Regular, Temp, Credit
    let startTime: Date
    let endTime: Date

    let source: String
    
    var status: Status = Status(signed: false)
    
    var notes = ""
    
    var color: UIColor = .black
    var breakTimeLimit = 20
    var yellowFlagRemoved = false
    
    init(identifier: String,
         name: String,
         deposit: Int,
         room: String,
         role: String,
         shiftType: String,
         startTime: Date,
         endTime: Date,
         status: Status,
         source: String = "AMO"){
        self.identifier = identifier
        self.id = identifier
        self.name = name
        self.deposit = deposit
        self.room = room
        self.role = role
        self.shiftType = shiftType
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.source = source
        super.init()
        self.config()
    }
    
    
    public func addNotes(note: String){
        if note.replacingOccurrences(of: " ", with: "").isEmpty{
            return
        }
        
        if notes != ""{
            notes += ";"
        }
        notes += note.replacingOccurrences(of: ",", with: ".")
    }
    
    public func setNotes(note: String){
        notes = note
    }
    
    public func updateStatus(newStatus: Status){
        status = newStatus
        config()
    }
    
    
    public func toString() -> String{
        var res = ""
        res += self.identifier + ","
        res += self.name + ","
        res += String(self.deposit) + ","
        res += self.room + ","
        res += self.role + ","
        res += self.shiftType + ","
        res += self.source + ","
        
        res += DateManager.hourFormatter.string(from: self.startTime) + ","
        res += DateManager.hourFormatter.string(from: self.endTime) + ","
        res += self.status.toString() + ","
        res += self.notes.replacingOccurrences(of: "\n", with: "; ")
        return res
    }
    
    public func exportRecord(item: String, uniqueID: String, description: String, rate: Double, money: Double = 0)->String{
        var record = "\(deposit),"
        record += "\(name),"
        
        let formmater = DateManager.dateFormatter
        formmater.dateFormat = "MM/dd/yyyy"
        record += "\(formmater.string(from: startTime)),"
        
        record += "\(uniqueID),"
        
        formmater.dateFormat = "hh:mma"
        record += "\(item),"
        let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: startTime, to: endTime)
        var noShowTime: Double = Double(diffComponents.hour ?? 0)  + Double(diffComponents.minute ?? 0) / 60
        if noShowTime < 0 {
            noShowTime += 24
        }
        
        let totalMoney = noShowTime * rate + money
        
        record += "\(item); From \(formmater.string(from: startTime)) - \(formmater.string(from: endTime)); \(description) in \(role); True Amount $\(abs(totalMoney)),"
        record += "\(totalMoney),"
        record += "\(noShowTime),"
        var imsAmount = 0.0
        if rate < 0{
            imsAmount = 10.0 * noShowTime
        }else if rate > 0{
            imsAmount = 13.0 * noShowTime
        }else{
            imsAmount = money
        }
        record += "\(imsAmount)"
        return record
    }
    
    public enum presentMode: String{
        case full
        case basic
        case medium
    }
    
    public func presentInfo(inView: UIViewController, mode: presentMode){
        var keys = ["name👤:",
                    "shift🍳:",
                    "time⏰:",
                    "sign in🕒:",
                    "breakout🕟:",
                    "breakin🕜:",
                    "sign out🕓:",
                    "covered🧑‍🍳:"]
        var values = [
            name,
            role + ", " + shiftType,
            "\(DateManager.dateToString(date: startTime, format: "hha")) - \(DateManager.dateToString(date: endTime, format: "hha"))",
            "\(DateManager.dateToString(date: status.signIn))",
            "\(DateManager.dateToString(date: status.breakOut))",
            "\(DateManager.dateToString(date: status.breakIn))",
            "\(DateManager.dateToString(date: status.signOut))",
            "\(status.coveredBy)"
        ]
        
        switch mode{
        case .medium:
            keys.append("deposit🆔:")
            values.append("\(deposit)")
            
            keys.append("notes📝:")
            values.append("")
        case .full:
            keys.append("deposit🆔:")
            values.append("\(deposit)")
            
            keys.append("fine💵:")
            if status.fine > 0.5{
                values.append("$\(status.fine)")
            }else{
                values.append(" ")
            }
            
            keys.append("notes📝:")
            values.append("\(notes)")
        default:
            keys.append("notes📝:")
            values.append("")
        }
        
        
        let vc = MemberInfoViewController(key: keys, value: values, title: "Information", inView: inView)
        inView.present(vc, animated: true)
    }
    
    public func getTimeStamps() -> String{
        var info = ""
        
        info += "• \(DateManager.dateToString(date: status.signIn)) sign in\n"
        info += "• \(DateManager.dateToString(date: status.breakOut)) break out\n"
        info += "• \(DateManager.dateToString(date: status.breakIn)) break in\n"
        info += "• \(DateManager.dateToString(date: status.signOut)) sign out"
        
        return info
    }
    
    public func removeYellowFlag(){
        LogManager.writeLog(info: "The yellow flag of \(name) has been removed.")
        yellowFlagRemoved = true
        status.isNormal = true
    }

    public func getYellowFlagInfo() -> String {
        var info = ""
        // check if late
        var lateMinutes = DateManager.getMinutesDiff(start: startTime, end: status.signIn)
        if DateManager.getSection(date: startTime) == 3{ // closing shift
            lateMinutes -= breakTimeLimit
        }
        if lateMinutes > PolicyManager.getMaxLateMinutes(){
            info += "⚠️ sign-in late for \(lateMinutes)min\n"
        }
        // check if break too long
        if status.duration - breakTimeLimit > PolicyManager.getMaxExtraBreakOutMinutes(){
            info += "⚠️ breakout too long (\(status.duration) min)\n"
        }
        // check if leave too early
        if status.signedOut{
            let absentDuration = DateManager.getMinutesDiff(start: status.signOut, end: endTime) - (breakTimeLimit - status.duration)
            if absentDuration > PolicyManager.getEarlySignOutMinutes(){
                info += "⚠️ sign out too early;"
            }
        }
        return info
    }
    
    
    
    public func calculateFine(completion: (String, Double)->Void){
        let reason = notes
        let money = status.fine
        completion(reason, money)
        return
    }
    
    
    public func config(){
        /// this function configure all the remaining properties of this class, i.e. isNormal, noShow etc.
        if status.duration < 0{
            if status.breakOut != DateManager.defaultDate && status.breakIn != DateManager.defaultDate{
                let newDuration = DateManager.getMinutesDiff(start: status.breakOut, end: status.breakIn)
                if newDuration > 0{
                    status.setDuration(minutes: newDuration)
                }
            }
        }
        
        if status.duration - breakTimeLimit > PolicyManager.getMaxExtraBreakOutMinutes(){
            // if the break out time is too long
            status.isNormal = false
        }
        
        if status.signed && status.signOut != DateManager.defaultDate{
            status.signedOut = true
        }
        
        if status.breakOut != DateManager.defaultDate && status.breakIn == DateManager.defaultDate && !status.signedOut{
            status.onBreak = true
        }else{
            status.onBreak = false
        }
        
        
        if status.signed{
            status.noShow = false
            let lateMinutes = DateManager.getMinutesDiff(start: startTime, end: status.signIn)
            if DateManager.getSection(date: startTime) == 3{ // closing shift
                if lateMinutes > breakTimeLimit + PolicyManager.getMaxExtraBreakOutMinutes(){
                    status.isNormal = false
                }
            }else{
                if lateMinutes > PolicyManager.getMaxLateMinutes() {
                    status.isNormal = false
                }
            }
            
        }else{
            let noShowMinutes = DateManager.getMinutesDiff(start: startTime, end: Date())
            if noShowMinutes > breakTimeLimit + PolicyManager.getMaxLateMinutesForNoShow(){
                status.noShow = true
            }else{
                status.noShow = false
            }
        }
        
        if status.signedOut{
            let absentDuration = DateManager.getMinutesDiff(start: status.signOut, end: endTime) - (breakTimeLimit - status.duration)
            if absentDuration > PolicyManager.getEarlySignOutMinutes() {
                status.isNormal = false
            }
        }
        
        if yellowFlagRemoved{
            status.isNormal = true
        }
        
    }
    
    
    
    
    
    required convenience init(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(forKey: "identifier") as! String
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let deposit = aDecoder.decodeInteger(forKey: "deposit")
        let room = aDecoder.decodeObject(forKey: "room") as! String
        let role = aDecoder.decodeObject(forKey: "role") as! String
        let shiftType = aDecoder.decodeObject(forKey: "shiftType") as! String
        let startTime = aDecoder.decodeObject(forKey: "startTime") as! Date
        let endTime = aDecoder.decodeObject(forKey: "endTime") as! Date
        let status = aDecoder.decodeObject(forKey: "status") as! Status
        let notes = aDecoder.decodeObject(forKey: "notes") as! String
        let source = aDecoder.decodeObject(forKey: "source") as! String
        
        self.init(identifier: id,
                  name: name,
                  deposit: deposit,
                  room: room,
                  role: role,
                  shiftType: shiftType,
                  startTime: startTime,
                  endTime: endTime,
                  status: status,
                  source: source)
        self.notes = notes
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(identifier, forKey: "identifier")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(deposit, forKey: "deposit")
        aCoder.encode(room, forKey: "room")
        aCoder.encode(role, forKey: "role")
        aCoder.encode(shiftType, forKey: "shiftType")
        aCoder.encode(startTime, forKey: "startTime")
        aCoder.encode(endTime, forKey: "endTime")
        aCoder.encode(status, forKey: "status")
        aCoder.encode(notes, forKey: "notes")
        aCoder.encode(source, forKey: "source")
    }
    
}



func stringToBool(string: String) -> Bool{
    switch string {
    case "y", "true", "yes", "True":
        return true
    case "f", "false", "no", "False":
        return false
    default:
        return false
    }
}

