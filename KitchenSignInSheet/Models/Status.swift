//
//  Status.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/19/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit


/// this class depics the status of a shift
/// including all the timestamps
/// the current status
/// isnormal or not, etc.
class Status: NSObject, NSCoding{
    var signed: Bool = false
    var signIn: Date = DateManager.defaultDate
    var signOut: Date = DateManager.defaultDate
    var breakIn: Date = DateManager.defaultDate
    var breakOut: Date = DateManager.defaultDate
    var checked: Bool = false
    var deleted: Bool = false
    var duration = -1
    var fine: Double = 0
    var onBreak: Bool = false
    var noShow: Bool = false // late for 30mins
    var signedOut: Bool = false
    var isNormal: Bool = true // work hour > 3h 30min, breakout < 25 min, signIn late < 10 min
    var coveredBy: String = ""

    
    init(signed: Bool?, signIn: Date?, signOut: Date?, breakIn: Date?, breakOut: Date?) {
        self.signed = signed ?? false
        self.signIn = signIn ?? DateManager.defaultDate
        self.signOut = signOut ?? DateManager.defaultDate
        self.breakIn = breakIn ?? DateManager.defaultDate
        self.breakOut = breakOut ?? DateManager.defaultDate
    }

    public func toString() -> String{
        var res = ""
        res += String(self.signed) + ","
        
        res += DateManager.dateToString(date: self.signIn) + ","
        res += DateManager.dateToString(date: self.signOut) + ","
        res += DateManager.dateToString(date: self.breakOut) + ","
        res += DateManager.dateToString(date: self.breakIn) + ","
        if self.duration >= 0{
            res += String(self.duration) + ","
        }else{
            res += ","
        }
        res += String(self.checked) + ","
        if abs(self.fine) > 0.5{
            res += String(self.fine) + ","
        }else{
            res += ","
        }
        res += self.coveredBy
        return res
    }
    
    public func addFine(money: Double){
        self.fine += money
    }

    init(signed: Bool){
        self.signed = signed
    }
    
    public func setChecked(checked: Bool){
        self.checked = checked
    }
    
    public func delete(){
        self.deleted = true
    }
    
    public func setDuration(minutes: Int){
        self.duration = minutes
    }
    
    public func setCoveredBy(coveredBy: String){
        self.coveredBy = coveredBy
    }
    
    

    
    required convenience init(coder aDecoder: NSCoder) {
        let signed = aDecoder.decodeBool(forKey: "signed")
        let signIn = aDecoder.decodeObject(forKey: "signIn") as! Date
        let signOut = aDecoder.decodeObject(forKey: "signOut") as! Date
        let breakIn = aDecoder.decodeObject(forKey: "breakIn") as! Date
        let breakOut = aDecoder.decodeObject(forKey: "breakOut") as! Date
        let checked = aDecoder.decodeBool(forKey: "checked")
        let duration  = aDecoder.decodeInteger(forKey: "duration")
        let fines = aDecoder.decodeDouble(forKey: "fine")
        let onBreak = aDecoder.decodeBool(forKey: "onBreak")
        let name =  aDecoder.decodeObject(forKey: "coveredBy") as! String
        
        self.init(signed: signed, signIn: signIn, signOut: signOut, breakIn: breakIn, breakOut: breakOut)
        self.setDuration(minutes: duration)
        self.setChecked(checked: checked)
        self.fine = fines
        self.onBreak = onBreak
        self.coveredBy = name
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(signed, forKey: "signed")
        aCoder.encode(signIn, forKey: "signIn")
        aCoder.encode(signOut, forKey: "signOut")
        aCoder.encode(breakIn, forKey: "breakIn")
        aCoder.encode(breakOut, forKey: "breakOut")
        aCoder.encode(checked, forKey: "checked")
        aCoder.encode(duration, forKey: "duration")
        aCoder.encode(fine, forKey: "fine")
        aCoder.encode(onBreak, forKey: "onBreak")
        aCoder.encode(coveredBy, forKey: "coveredBy")
    }
}
