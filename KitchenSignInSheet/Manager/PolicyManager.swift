//
//  PolicyManager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 4/8/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import Foundation

struct DefaultPolicy{
    static let maxBreakOutMinutes = 5 // min
    static let maxLateMinutes = 5 // min
    static let earlySignOutMinutes = 10 // min
    static let maxLateMinutesForNoShow = 10 // min
    static let allowMemberToCreateShift = 0 // 0: no, 1: yes
    static let creditShiftMustBeChecked = 1 // 0: no, 1: yes
}

final class PolicyManager{
    
    static let policyNames = ["max extra break minutes",
                              "max late minutes",
                              "max early sign out minutes",
                              "max late minutes for No-Show",
                              "allow members to create shift (0:no, 1:yes)",
                              "credit shift must be checked (0:no, 1:yes)"
    ]
    
    static let policyKeys = ["maxBreakOutMinutes",
                             "maxLateMinutes",
                             "earlySignOutMinutes",
                             "maxLateMinutesForNoShow",
                             "allowMemberToCreateShift",
                             "creditShiftMustBeChecked"
    ]

    public var policyList: [Int]
    
    init(){
        policyList = [DefaultPolicy.maxBreakOutMinutes,
                      DefaultPolicy.maxLateMinutes,
                      DefaultPolicy.earlySignOutMinutes,
                      DefaultPolicy.maxLateMinutesForNoShow,
                      DefaultPolicy.allowMemberToCreateShift,
                      DefaultPolicy.creditShiftMustBeChecked
        ]
    }
    
    public func setPolicy(index: Int, value: Int){
        guard index < policyList.count, index >= 0 else{
            LogManager.writeLog(info: "index out of range in get function of policyManager index=\(index)")
            return
        }
        UserDefaults.standard.set(value, forKey: PolicyManager.policyKeys[index])
    }
    
    public func getAllPolicy() -> [Int]{
        var allPolicy = [Int]()
        for i in 0..<policyList.count{
            allPolicy.append(getPolicy(index: i))
        }
        return allPolicy
    }
    
    public func getPolicy(index: Int) -> Int{
        guard index <=
                policyList.count, index >= 0 else{
            LogManager.writeLog(info: "index out of range in get function of policyManager index=\(index)")
            return 0
        }
        if isKeyPresentInUserDefaults(key: PolicyManager.policyKeys[index]){
            return UserDefaults.standard.integer(forKey: PolicyManager.policyKeys[index])
        }
        return policyList[index]
    }
    
    static func getMaxExtraBreakOutMinutes() -> Int{
        if UserDefaults.standard.object(forKey: "maxBreakOutMinutes") != nil{
            return UserDefaults.standard.integer(forKey: "maxBreakOutMinutes")
        }
        return DefaultPolicy.maxBreakOutMinutes
    }
    

    
    static func getMaxLateMinutes() -> Int{
        if UserDefaults.standard.object(forKey: "maxLateMinutes") != nil{
            return UserDefaults.standard.integer(forKey: "maxLateMinutes")
        }
        return DefaultPolicy.maxLateMinutes
    }
    
    
    
    static func getEarlySignOutMinutes() -> Int{
        if UserDefaults.standard.object(forKey: "earlySignOutMinutes") != nil{
            return UserDefaults.standard.integer(forKey: "earlySignOutMinutes")
        }
        return DefaultPolicy.earlySignOutMinutes
    }
    
    
    
    static func getMaxLateMinutesForNoShow() -> Int{
        if UserDefaults.standard.object(forKey: "maxLateMinutesForNoShow") != nil{
            return UserDefaults.standard.integer(forKey: "maxLateMinutesForNoShow")
        }
        return DefaultPolicy.maxLateMinutesForNoShow
    }
    
    static func allowMemberToCreateShift() -> Bool{
        if UserDefaults.standard.object(forKey: "allowMemberToCreateShift") != nil{
            return UserDefaults.standard.integer(forKey: "allowMemberToCreateShift") != 0
        }
        return (DefaultPolicy.allowMemberToCreateShift != 0)
    }
    
    static func creditShiftMustBeChecked() -> Bool{
        if UserDefaults.standard.object(forKey: "creditShiftMustBeChecked") != nil{
            return UserDefaults.standard.integer(forKey: "creditShiftMustBeChecked") != 0
        }
        return (DefaultPolicy.creditShiftMustBeChecked != 0)
    }
    
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    
}
