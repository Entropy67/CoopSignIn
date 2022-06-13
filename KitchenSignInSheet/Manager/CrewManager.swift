//
//  File.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class CrewManager: Manager{
    
    var CREW_NAME = "Kitchen"
    var CREW_CODE = "KI"
    var Debit_rate: Double = 16.0
    var Credit_rate: Double = 13.0
    
    
    var regularCapacity = [
        [10, 7, 7, 12, 10], // weekday
        [9, 7, 5, 5, 10] // weekend
    ]
    
    override func config(){
        key = "crewList"
        
        let compactMode = UserDefaults.standard.bool(forKey: SettingBundleKeys.CompactModeKey)
        if compactMode{
            regularCapacity = [[4, 4], [4, 4]]
        }
        
        super.config()
    }
    
    
    public func initCrewList(){
        guard !isKeyPresentInUserDefaults(key: key) else{
            return
        }
        
        let regularCrew = Crew(name: "Regular", crewID: "KI", hours: 4.0, debitRate: Debit_rate, creditRate: Credit_rate, color: .black, capacity: 40)

        add(newElement: regularCrew){ error in
            if let err = error{
                LogManager.writeLog(info: "Init crew manager failed. Error: \(err)")
            }else{
                LogManager.writeLog(info: "Init crew manager success!")
            }
        }
    }
    
    
    override public func save(completion: ((Bool) -> Void)? = nil){
        super.save(){ [weak self] success in
            guard let strongSelf = self else{
                completion?(false)
                return
            }
            do{
                let encodedCapacityData = try NSKeyedArchiver.archivedData(withRootObject: strongSelf.regularCapacity, requiringSecureCoding: false)
                UserDefaults.standard.set(encodedCapacityData, forKey: strongSelf.key + "_capacity")
                UserDefaults.standard.synchronize()
                completion?(success && true)
            }catch{
                LogManager.writeLog(info: "save regular capacity error. \(error). Crew capacity is not saved")
                completion?(false)
            }
        }
    }
    
    override public func load(completion: ((Bool) -> Void)? = nil) {
        super.load(){ [weak self] success in
            guard let strongSelf = self else{
                completion?(false)
                return
            }
            
            guard let encodedCapacityData = UserDefaults.standard.data(forKey: strongSelf.key+"_capacity") else{
                completion?(false)
                return
            }
            
            do{
                strongSelf.regularCapacity = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(encodedCapacityData) as! [[Int]]
                completion?(true)
            }catch{
                LogManager.writeLog(info: "load regular capacity error \(error)")
                completion?(false)
            }
        }
    }
    
    
    public func getCrew(at: Int) -> Crew?{
        if at >= 0, at < count{
            if let crew = allElements[at] as? Crew{
                return crew
            }
        }
        return nil
    }
    
    public func getCrew(crewName: String) -> Crew?{
        if let crew = find(id: crewName) as? Crew{
            return crew
        }
        return nil
    }
    
    public func getCrewList() -> [Crew]{
        if let crewList = allElements as? [Crew]{
            return crewList
        }
        return []
    }
    
    public func getCrewColor(crewName: String) -> UIColor{
        if let crew = find(id: crewName) as? Crew{
            return crew.color
        }
        return .black
    }
    
    public func getCrewHours(crewName: String) -> Float{
        if let crew = find(id: crewName) as? Crew{
            return crew.hours
        }
        return 4.0
    }
    
    public func getCrewMinutes(crewName: String) -> Int{
        if let crew = find(id: crewName) as? Crew{
            let hours = Int(crew.hours)
            let diff = (crew.hours) - Float(hours)
            let minutes = Int( diff * 60 )
            return  minutes
        }
        return 0
    }
    
}
