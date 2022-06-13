//
//  Crew.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class Crew: NSObject , NSCoding, Element{
    var id: String
    var name: String
    var crewID: String
    var hours: Float
    var debitRate: Double
    var creditRate: Double
    var color: UIColor
    var deletable: Bool = true
    var capacity: Int
    
    var breakTime: Int
    
    init(name: String, crewID: String, hours: Float, debitRate: Double, creditRate: Double, color: UIColor, capacity: Int){
        self.id = name
        self.name = name
        self.hours = hours
        self.crewID = crewID
        self.debitRate = debitRate
        self.creditRate = creditRate
        self.color = color
        self.capacity = capacity
        self.breakTime = 20
        if hours < 3.9{
            self.breakTime = 0
        }
    }
    
    
    public func setCapacity(capacity: Int){
        self.capacity = capacity
    }
    
    public func setBreakTime(breakTime: Int){
        self.breakTime = breakTime
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "crewName")
        aCoder.encode(crewID, forKey: "crewID")
        aCoder.encode(hours, forKey: "crewHours")
        aCoder.encode(debitRate, forKey: "crewDebitRate")
        aCoder.encode(creditRate, forKey: "crewCreditRate")
        aCoder.encode(color, forKey: "crewColor")
        aCoder.encode(deletable, forKey: "crewDeletable")
        aCoder.encode(capacity, forKey: "capacity")
        aCoder.encode(breakTime, forKey: "breakTime")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: "crewName") as! String
        let crewID = aDecoder.decodeObject(forKey: "crewID") as! String
        let hours = aDecoder.decodeFloat(forKey: "crewHours")
        let debitRate = aDecoder.decodeDouble(forKey: "crewDebitRate")
        let creditRate = aDecoder.decodeDouble(forKey: "crewCreditRate")
        let color = aDecoder.decodeObject(forKey: "crewColor") as! UIColor
        let deletable = aDecoder.decodeBool(forKey: "crewDeletable")
        let crewCapacity = aDecoder.decodeInteger(forKey: "capacity")
        let breakTime = aDecoder.decodeInteger(forKey: "breakTime")
        self.init(name: name, crewID: crewID, hours: hours , debitRate: debitRate , creditRate: creditRate, color: color, capacity: crewCapacity)
        self.setBreakTime(breakTime: breakTime)
        self.deletable = deletable
    }
    
    public func toString() -> String {
        return "name:\(name); id:\(crewID); hour:\(hours); debit:\(debitRate); creidt:\(creditRate); capacity: \(capacity)"
    }
    
    
}



