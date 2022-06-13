//
//  Chore.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 5/7/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class Chore:NSObject, NSCoding, Element{
    
    func toString() -> String {
        return "id:\(id); member:\(member.name);role:\(role.name); date:\(date);startTime:\(startTime);endTime;\(endTime)"
    }
    var name: String
    var id: String
    var date: String
    var member: Person
    var startTime: String
    var endTime: String
    var role: Crew
    
    init(id: String, date: String, startTime: String, endTime: String, member: Person, role: Crew){
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.member = member
        self.role = role
        self.name = member.name
    }

    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(date, forKey: "date")
        coder.encode(member, forKey: "member")
        coder.encode(startTime, forKey: "startTime")
        coder.encode(endTime, forKey: "endTime")
        coder.encode(role, forKey: "role")
    }
    
    required convenience init?(coder: NSCoder) {
        let choreId = coder.decodeObject(forKey: "id") as! String
        let choreDate = coder.decodeObject(forKey: "date") as! String
        let choreMember = coder.decodeObject(forKey: "member") as! Person
        let chorestartTime = coder.decodeObject(forKey: "startTime") as! String
        let choreendTime = coder.decodeObject(forKey: "endTime") as! String
        let choreRole = coder.decodeObject(forKey: "role") as! Crew
        
        self.init(id: choreId,
                  date: choreDate,
                  startTime: chorestartTime,
                  endTime: choreendTime,
                  member: choreMember,
                  role:choreRole
        )
    }
    
    
}
