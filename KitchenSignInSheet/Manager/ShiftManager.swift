//
//  ShiftManager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/19/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit


class ShiftManager{
    
    var shiftList = [[Member](),[Member](),[Member](),[Member](),[Member]()]
    var tempShiftList = [Member]() // store shift from sign in form temporarily before merge to shiftlist
    
    
    var crewManager: CrewManager? = nil
    var CREW_NAME = "Kitchen"
    var CREW_CODE = "KI"
    var compactMode = false
    
    var Debit_rate: Double = 16.0
    var Credit_rate: Double = 13.0
    var Default_hour: Float = 4.0
    static let Default_source = "AMO"
    static let Credit_shift = "Credit"
    

    public func config(){
        CREW_NAME = UserDefaults.standard.string(forKey: SettingBundleKeys.CrewNameKey) ?? "Kitchen"
        
        let endIndex = CREW_NAME.index(CREW_NAME.startIndex, offsetBy: 1)
        CREW_CODE = String(CREW_NAME[...endIndex]).uppercased()
        
        compactMode = UserDefaults.standard.bool(forKey: SettingBundleKeys.CompactModeKey)
        
        if compactMode{
            shiftList = [[], []]
        }
    }
    
    public func getShiftCount()->Int{
        var counts = 0
        for section in shiftList{
            counts += section.count
        }
        return counts
    }
    
    public func getShift(Id: String) -> Member?{
        for shiftSection in shiftList{
            for mem in shiftSection{
                if mem.identifier == Id{
                    return mem
                }
            }
        }
        return nil
    }
    
    public func getShift(section: Int, row: Int)-> Member? {
        if section >= 0, section < shiftList.count{
            if row >= 0, row < shiftList[section].count{
                return shiftList[section][row]
            }
        }
        return nil
    }
    
    public func deleteShift(section: Int, row: Int){
        if section >= 0, section < shiftList.count{
            if row >= 0, row < shiftList[section].count{
                shiftList[section].remove(at: row)
            }
        }
        return
    }
    
    public func clearShiftList(){
        for i in 0..<shiftList.count{
            shiftList[i].removeAll()
        }
    }
    
    public func refresh(){
        for sec in shiftList{
            for mem in sec{
                mem.config()
            }
        }
    }
    
    
    public func exportRecord(completion: ((String) -> ())?){
        var csvString = "\("identifier"),\("name"), \("deposit"),\("room"),\("role"),\("shiftType"),\("assigned by"), \("startTime"),\("endTime"),  \("signed?"),\("signInTime"),\("signOutTime"),\("breakoutTime"),\("breakInTime"),\("Duration"),\("checked?"),\("fine"),\("covered By"),\("notes")\n"
        
        let viewShiftList = shiftList.reduce([], + )
        
        for shift in viewShiftList {
            csvString = csvString.appending(shift.toString() + "\n")
        }
        completion?(csvString)
        return
    }
    
    public func exportDebitCreditFine(completion: ((String?) -> ())?){
        
        var hasRecords = false
        
        let viewShiftList = shiftList.reduce([], +)
        let formmater = DateManager.dateFormatter
        
        
        /// export credit info to string
        var creditString = "\("Type"),\("Deposit"),\("Name"),\("Transaction Date"),\("RefNumber"),\("Item name"),\("Description"),\("Price"),\("Hours"),\("IMS amount")\n"
        var credit_id = [String: Int]()
        
        for shift in viewShiftList {
            shift.config()
            formmater.dateFormat = "MMddyy"
            let uniqueID = "\(formmater.string(from: shift.startTime))"
            
            let checked = shift.status.checked || !PolicyManager.creditShiftMustBeChecked()
            
            if shift.shiftType == "Credit" && shift.status.signed && shift.status.signedOut && checked{
                var uniqueCreditID = uniqueID
                
                var rate = Credit_rate
                if let crew = crewManager?.find(id: shift.role) as? Crew{
                    uniqueCreditID  += "\(crew.crewID)C"
                    rate = crew.creditRate
                }
                
                if credit_id.keys.contains(shift.role), let last_id = credit_id[shift.role]{
                    credit_id[shift.role] = (last_id + 1) % 10
                    uniqueCreditID += "\( (last_id + 1) % 10)"
                }else{
                    credit_id[shift.role] = 1
                    uniqueCreditID += "1"
                }
                hasRecords = true
                creditString = creditString.appending(
                    "Credit," + shift.exportRecord(item: "CREDIT-\(self.CREW_NAME.uppercased())", uniqueID: uniqueCreditID, description: "", rate: -rate) + "\n"
                )
            }
        }
        
        
        /// export debit info to string
        var noShowString = "\n\("Type"),\("Deposit"),\("Name"),\("Transaction Date"),\("RefNumber"),\("Item name"),\("Description"),\("Price"),\("Hours"),\("IMS amount")\n"
        
        var no_show_id = [String: Int]()

        for shift in viewShiftList {
            shift.config()
            formmater.dateFormat = "MMddyy"
            let uniqueID = "\(formmater.string(from: shift.startTime))"
            if shift.status.noShow{
                var uniqueDebitID = uniqueID
                var rate = Debit_rate
                if let crew = crewManager?.find(id: shift.role) as? Crew{
                    uniqueDebitID  += "\(crew.crewID)D"
                    rate = crew.debitRate
                }
                
                if no_show_id.keys.contains(shift.role), let last_id = no_show_id[shift.role]{
                    no_show_id[shift.role] = (last_id + 1) % 10
                    uniqueDebitID += "\(last_id + 1)"
                }else{
                    no_show_id[shift.role] = 1
                    uniqueDebitID += "1"
                }
                hasRecords = true
                noShowString = noShowString.appending(
                    "Debit," + shift.exportRecord(item: "FINE-\(self.CREW_NAME.uppercased())", uniqueID: uniqueDebitID, description: "No-show", rate: rate) + "\n"
                )
            }
            
        }
        
        ///export fine info to string
        var fineString = "\n\("Type"),\("Deposit"),\("Name"),\("Transaction Date"),\("RefNumber"),\("Item name"),\("Description"),\("Price"),\("Hours"),\("IMS amount")\n"
        var fine_id = 0

        for shift in viewShiftList {
            shift.config()
            formmater.dateFormat = "MMddyy"
            let uniqueID = "\(formmater.string(from: shift.startTime))"
            shift.calculateFine(){ [weak self] (reason, money) in
                if let strongSelf = self, abs(money) > 0.5{
                    fine_id += 1
                    hasRecords = true
                    let uniqueFineID = uniqueID + "\(strongSelf.CREW_CODE)F\(fine_id)"
                    fineString  = fineString.appending( "Fine," +
                        shift.exportRecord(item: "FINE-\(strongSelf.CREW_NAME.uppercased())",
                                            uniqueID: uniqueFineID,
                                            description: "Fine " + reason,
                                            rate: 0, money: money) + "\n"
                    )
                }
                
            }
        }
        if hasRecords{
            completion?(creditString + noShowString + fineString)
        }else{
            completion?(nil)
        }
    }

}


// MARK: - Add shifts from different sources
extension ShiftManager{

    /// add shift to list
    private func addShiftToList(newShift: Member) -> Bool{
        let section = DateManager.getSection(date: newShift.startTime, compactMode: compactMode)
        if self.shiftList[section].firstIndex(where: {$0.identifier == newShift.identifier}) != nil{
            // if the shift has duplication, reject adding the shift
            return false
        }
        
        // if this shift overlap with another shift, reject
        if let index = self.shiftList[section].firstIndex(where: {$0.deposit == newShift.deposit}){
           if self.shiftList[section][index].endTime > newShift.startTime{
                return false
            }
        }
        
        if newShift.source != ShiftManager.Default_source,
           newShift.shiftType == ShiftManager.Credit_shift,
           !hasOpening(crewName: newShift.role, section: section){
            // if the shift is not assigned by AMO, and it is a credit shift, and the capacity is reached, reject the registrition
            return false
        }

        if let crew = crewManager?.find(id:newShift.role) as? Crew{
            newShift.color = crew.color
            newShift.breakTimeLimit = crew.breakTime
        }
        
        self.shiftList[section].append(newShift)
        
        self.shiftList[section].sort(by: { $0.startTime < $1.startTime})
        return true
    }
    
    /// add shift to temp list
    private func addShiftToTempList(newShift: Member) -> Bool{
        if self.tempShiftList.firstIndex(where: {$0.identifier == newShift.identifier}) != nil{
            return false
        }
        self.tempShiftList.append(newShift)
        return true
    }
    
    public func mergeTempMemList(){
        // add all mem in temp shift list to shiftlist
        for mem in tempShiftList{
            _ = addShiftToList(newShift: mem)
        }
        var newShiftList = [ [Member](), [Member](), [Member](), [Member](), [Member]()]
        
        if compactMode{
            newShiftList = [[], []]
        }
        
        // for all mem in shiftList
        for i in 0..<shiftList.count{
            for mem in shiftList[i]{
                // if it was assigned by AMO
                if mem.source == ShiftManager.Default_source{
                    // if it is still in the sign-in sheet
                    if (self.tempShiftList.firstIndex(where: {$0.identifier == mem.identifier}) != nil) || mem.status.signed{
                        newShiftList[i].append(mem)
                    }else{
                        LogManager.writeLog(info: "Warning! Shift\(mem.identifier) of \(mem.name) assigned by AMO not found in sign-in-form. Delete it from the local shiftlist. ")
                    }
                }else{
                    newShiftList[i].append(mem)
                }
            }
        }
        shiftList = newShiftList
    }
    
    
    
    /// add shift using detailed information to shiftlist
    public func addShift(identifier: String,
                          name: String,
                          deposit: Int,
                          room: String,
                          role: String,
                          shiftType: String,
                          startTime: Date,
                          endTime: Date,
                          status: Status,
                          assignedBy: String = ShiftManager.Default_source,
                          note: String = "",
                          completion: ((Bool) -> Void)?
        ){
        let newShift = Member(identifier: identifier, name: name, deposit: deposit, room: room, role: role, shiftType: shiftType, startTime: startTime, endTime: endTime, status: status, source: assignedBy)
        newShift.addNotes(note: note)
        let result = self.addShiftToList(newShift: newShift)
        completion?(result)
    }
    
    /// add shift to temp shift list
    private func addShiftToTempList(identifier: String,
                          name: String,
                          deposit: Int,
                          room: String,
                          role: String,
                          shiftType: String,
                          startTime: Date,
                          endTime: Date,
                          status: Status,
                          assignedBy: String = ShiftManager.Default_source,
                          note: String = "",
                          completion: ((Bool) -> Void)?
        ){
        let newShift = Member(identifier: identifier, name: name, deposit: deposit, room: room, role: role, shiftType: shiftType, startTime: startTime, endTime: endTime, status: status, source: assignedBy)
        newShift.addNotes(note: note)
        //print("Add: \(newShift.toString())")
        let result = self.addShiftToTempList(newShift: newShift)
        completion?(result)
    }
    
    /// add shift from shift object
    public func addShift(newShift: Member, completion: ((Bool) -> ())?){
        let result = self.addShiftToList(newShift: newShift)
        completion?(result)
    }
    
    /// add shift from signIn sheet to the tempshift list and merge it to the shiftlist
    public func addShift(fromSignInSheet: String, date: String){
        let columns = fromSignInSheet.components(separatedBy: ",")
        // basic info: index, time, name, deposite
        if columns.count < 4{
            // if there is no minimal info, skip to next
            return
        }
        if columns[2] != ""{
            let time = columns[1].components(separatedBy: " ") // [12, pm, 4, pm]
            
            var startTimeText = date + "-5 am"
            var endTimeText = date + "-9 am"
            if time.count >= 2{
                startTimeText = date + "-" + time[0] + " " + time[1]
            }
            if time.count >= 4{
                endTimeText = date + "-" + time[2] + " " + time[3]
            }
            
            let formatter = DateManager.dateFormatter
            formatter.dateFormat = "MMddyyyy-h a"
            let startTime = formatter.date(from: startTimeText) ?? Date()
            let defaultEndTime = Calendar.current.date(byAdding: .hour, value: Int(Default_hour), to: startTime) ?? DateManager.defaultDate
            var endTime = formatter.date(from: endTimeText) ?? defaultEndTime
            
            //formatter.dateFormat = "yyyyMMddhh"
            formatter.dateFormat = "yyyyMMddhh"
            var identifier = columns[3] + "-"
            identifier += formatter.string(from: startTime)

            let name = columns[2]
            let deposit = Int(columns[3]) ?? 10000
            var room = ""
            
            if columns.count > 4{
                room = columns[4]
            }
            var shiftType = "Regular"
            var role = "Regular"
            
            if columns.count >= 6{
                let signature = columns[5]
                if signature.contains("LoA"){
                    // delete shifts taking LoA
                    return
                }
                if let crewList = crewManager?.allElements as? [Crew]{
                    for crew in crewList{
                        if signature.contains(crew.name){
                            role = crew.name
                            break
                        }
                    }
                }
                
                if signature.contains("Temp"){
                    shiftType = "Temp."
                }else if signature.contains("Credit"){
                    shiftType = "Credit"
                }
            }
            
            let hours = crewManager?.getCrewHours(crewName: role) ?? Default_hour
            let minutes = crewManager?.getCrewMinutes(crewName: role) ?? 0
            
            endTime = Calendar.current.date(byAdding: .hour, value: Int(hours), to: startTime) ?? endTime
            endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: endTime) ?? endTime
            
            let status = Status(signed: false)
            self.addShiftToTempList(identifier: identifier,
                           name: name,
                           deposit: deposit,
                           room: room,
                           role: role,
                           shiftType: shiftType,
                           startTime: startTime,
                           endTime: endTime,
                           status: status,
                           completion: nil)
        }
        return
    }
    
    /// add shift from csv file
    public func addShift(fromString: String, completion: ((Bool) -> ())?){
        let columns = fromString.components(separatedBy: ",")
        if columns.count < 9 {
            completion?(false)
            return
        }
        
        // identifier, name, deposit, room, role, shiftType, source
        let identifier = columns[0]
        let name = columns[1]
        let deposit = Int(columns[2]) ?? 10000
        let room = columns[3]
        let role = columns[4]
        let shiftType = columns[5]
        let source = columns[6]
        
        let startTime = DateManager.stringToDate(string: columns[7])
        let endTime = DateManager.stringToDate(string: columns[8])
        
        let status = Status(signed: false)
        var note = ""
        
        if columns.count > 18{
            
            var money = 0.0
            var coveredBy = ""
            
            let signed = stringToBool(string: columns[9])
            status.signed = signed
            
            // signInTime, signOutTime, breakOutTime, breakInTime
            if signed{
                status.signIn  = DateManager.stringToDate(string: columns[10])
                status.signOut = DateManager.stringToDate(string: columns[11])
                status.breakOut = DateManager.stringToDate(string: columns[12])
                status.breakIn = DateManager.stringToDate(string: columns[13])
                status.setDuration(minutes: Int(columns[14]) ?? -1)
                status.setChecked(checked: stringToBool(string: columns[15]))
            }
            
            money = Double(columns[16]) ?? 0.0
            coveredBy = columns[17]
            note = columns[18]
            
            status.addFine(money: money)
            status.setCoveredBy(coveredBy: coveredBy)
        }
        
        self.addShift(identifier: identifier,
                      name: name,
                      deposit: deposit,
                      room: room,
                      role: role,
                      shiftType: shiftType,
                      startTime: startTime,
                      endTime: endTime,
                      status: status,
                      assignedBy: source,
                      note: note,
                      completion: completion)
    }
    
    public func addShift(fromSpreadSheet: String, completion: ((Bool) -> Void)? = nil){
        
        let columns = fromSpreadSheet.components(separatedBy: ",")
        
        //print(columns)
        
        if columns.count < 7{
            completion?(false)
            return
        }
        
        // identifier, name, deposit, room, role, shiftType, source
        let name = columns[0]
        let depositString = columns[1]
        let weekday = columns[2]
        let role = columns[5]
        let shiftType = columns[6] // Regular, Credit, Temp
        let startTimeString = columns[3]
        let endTimeString = columns[4]
        
        guard let deposit = Int(depositString) else{
            completion?(false)
            return
        }
        
        if DateManager.dayStringToNumber(day: weekday) != DateManager.getDayNumber(date: Date()){
            completion?(false)
            return
        }
        
        guard name.replacingOccurrences(of: " ", with: "").count > 0, deposit > 0 else{
            completion?(false)
            return
        }
        
        if columns.count >= 8, columns[7] != "", shiftType != "Regular"{
            completion?(false)
            return
        }
        
        let startTime = DateManager.stringToDate(string: startTimeString)
        let endTime = DateManager.stringToDate(string: endTimeString)
        let status = Status(signed: false)
        
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = "yyyyMMddhh"
        let identifier =  "\(deposit)-\(formatter.string(from: startTime))"
        
        self.addShift(identifier: identifier,
                      name: name,
                      deposit: deposit,
                      room: "",
                      role: role,
                      shiftType: shiftType,
                      startTime: startTime,
                      endTime: endTime,
                      status: status,
                      assignedBy: "CC",
                      completion: completion)
    }
    
    
    public func addShift(fromChore: Chore, completion: ((Bool) -> Void)? = nil){
        
        let chore = fromChore
        
        if DateManager.dayStringToNumber(day: chore.date) != DateManager.getDayNumber(date: Date()){
            completion?(false)
            return
        }
        
        
        
        let startTime = DateManager.stringToDate(string: chore.startTime)
        let endTime = DateManager.stringToDate(string: chore.endTime)
        let status = Status(signed: false)
        
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = "yyyyMMddhh"
        let identifier =  "\(chore.member.deposit)-\(formatter.string(from: startTime))"
        
        self.addShift(identifier: identifier,
                      name: chore.member.name,
                      deposit: chore.member.deposit,
                      room: "",
                      role: chore.role.name,
                      shiftType: "Regular",
                      startTime: startTime,
                      endTime: endTime,
                      status: status,
                      assignedBy: "CC",
                      completion: nil)
    }
    
    private func hasOpening(crewName: String, section: Int) -> Bool{
        var size = 0
        
        guard let crew = crewManager?.find(id:crewName) as? Crew else{
            LogManager.writeLog(info: "Try to add \(crewName), but did not find such crew in the crewManager.")
            return false
        }
        
        // check the total daily capacity
        for sec in self.shiftList{
            for mem in sec{
                mem.config()
                if mem.role == crewName, !mem.status.noShow{
                    size += 1
                }
            }
        }
        
        if size >= crew.capacity{
            LogManager.writeLog(info: "Try to add \(crewName), but the daily crew capacity is reached.")
            return false
        }
        
        size = 0
        
        // check the capacity of the corresponding section
        for mem in self.shiftList[section]{
            if mem.role == crewName, !mem.status.noShow{
                size += 1
            }
        }
        
        if let capacityList = crewManager?.regularCapacity{
            var capacity = [0, 0, 0, 0, 0]
            if compactMode{
                capacity = [0, 0]
            }
            if DateManager.isWeekend(date: Date()){
                capacity = capacityList[1]
            }else{
                capacity = capacityList[0]
            }
            if size >= capacity[section]{
                LogManager.writeLog(info: "Try to add \(crewName) at section #\(section), but the maximal section capacity is reached.")
                return false
            }
        }
        
        return true
    }
    
    public func getOpenings(crewName: String, section: Int) -> Int{
        var size = 0
        // check the capacity of the corresponding section
        for mem in self.shiftList[section]{
            if mem.role == crewName, !mem.status.noShow{
                size += 1
            }
        }
        
        if let capacityList = crewManager?.regularCapacity{
            var capacity = [0, 0, 0, 0, 0]
            if compactMode{
                capacity = [0, 0]
            }
            
            if DateManager.isWeekend(date: Date()){
                capacity = capacityList[1]
            }else{
                capacity = capacityList[0]
            }
            if size >= capacity[section]{
                return 0
            }else{
                return capacity[section] - size
            }
        }
        
        return 0
        
    }
}
