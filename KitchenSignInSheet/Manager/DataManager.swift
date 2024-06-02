//
//  DataManager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/19/22.
//  Copyright © 2022 AMO. All rights reserved.
//
import UIKit


final class DataManager{
    
    var shiftManager: ShiftManager
    var lastUpdateTime: Date
    
    init(){
        self.shiftManager = ShiftManager()
        self.lastUpdateTime = Date(timeIntervalSince1970: 0)
    }
    
    func config(){
        shiftManager.config()
    }
    
    static func checkFileExist(filename: String) -> Bool{
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(filename) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    static func resetDefaultsData() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        dictionary.keys.forEach { key in
            if key.contains("memberList-"){
                defaults.removeObject(forKey: key)
            }else if key.contains("crewList"){
                defaults.removeObject(forKey: key)
            }
        }
    }
    
    static func anyArrayToData(any2DArray: [[Any]]) -> Data? {
        //
        var allData = ""
        for row in any2DArray{
            if let rowString = row as? [String]{
                allData += rowString.joined(separator: ",") + "\n"
            }
        }
        return allData.data(using: .utf8)
      }
    
    
    static func removeAllDocuments(){
        //LogManager.writeLog(info: "did tap remove all documents option")
        //self.resetDefaultsData()
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs where fileURL.pathExtension == "csv" {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            for fileURL in fileURLs where fileURL.pathExtension == "log" {
                try FileManager.default.removeItem(at: fileURL)
            }
            
        } catch  { LogManager.writeLog(info: "Remove all document error: \(error)") }
    }
    
    
    static func saveCSVFile(data: Data?, filename: String, completion: @escaping (String)->() ){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(filename) {
            do{
                try data?.write(to: pathComponent)
            }catch{
                LogManager.writeLog(info: "save data to csv failed because Error:\(error)")
                
            }
        }
        completion(filename)
    }
}

// MARK: - delete data

extension DataManager{
    /// clear today's data in userdefaults
    func clearUserDefaults(){
        let defaults = UserDefaults.standard
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = "MM-dd-yyyy"
        let key = "memberList-\( formatter.string(from: lastUpdateTime))"
        LogManager.writeLog(info: "Deleting usedefault with key = \(key)")
        defaults.removeObject(forKey: key)
    }
    
    /// delete today's csv file, includes records, FDC file
    func deleteCSV(){
        
        let fileManager = FileManager.default
        
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = "MMddyyyy"
        let filename = "\(formatter.string(from: lastUpdateTime))"
        
        do{
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            
            if(DataManager.checkFileExist(filename: filename + "_Records.csv")){
                LogManager.writeLog(info: "Deleting file \(filename)_Records.csv")
                let fileURL = path.appendingPathComponent(filename + "_Records.csv")
                try fileManager.removeItem(at: fileURL)
            }
            
            if(DataManager.checkFileExist(filename: filename + "_Credit-Debit-Fine.csv")){
                LogManager.writeLog(info: "Deleting file \(filename)_Credit-Debit-Fine.csv")
                let fdcURL = path.appendingPathComponent(filename + "_Credit-Debit-Fine.csv")
                
                try fileManager.removeItem(at: fdcURL)
            }
            
        }catch{
            LogManager.writeLog(info: "Failed to delete csv file. Error: \(error)")
        }
        
        
    }
    
    /// remove local sign-in form (if exists) and weekly spreadsheet (if exists)
    func deleteSignInForm(fileNames: [String?]){
        
        let fileManager = FileManager.default
        
        do{
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            
            for fileName in fileNames{
                if let filename = fileName, DataManager.checkFileExist(filename: filename){
                    let fileURL = path.appendingPathComponent(filename)
                    try fileManager.removeItem(at: fileURL)
                }
            }
        }catch{
            LogManager.writeLog(info: "Failed to delete files: \(fileNames)")
        }
        
    }
}


// MARK: - load data
extension DataManager{
    
    func loadFromChoreManager(choreManager: ChoreManager){
        for chore in choreManager.allElements{
            if let ch = chore as? Chore{
                shiftManager.addShift(fromChore: ch)
            }
        }
    }
    
    func loadFromSpreadSheet(filename: String, completion:((Bool, [Int])->Void)?){
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        var rowToBeRemoved = [Int]()
        if let pathComponent = url.appendingPathComponent(filename) {
            //convert that file into one long string
            var data = ""
            do {
                data = try String(contentsOf: pathComponent).removeNewLineInQuotes()
            } catch let error {
                LogManager.writeLog(info: "Error: failed to read content of signIn sheet. \(error)")
                completion?(false, [])
                return
            }

            var rows = data.components(separatedBy: "\n")
            guard rows.count >= 1 else {
                LogManager.writeLog(info: "Error: spreadsheet entries are empty!")
                completion?(false, [])
                return
            }
            rows.removeFirst(1)
            for i in 0..<rows.count{
                //print("spreadsheet row: \(row)")
                shiftManager.addShift(fromSpreadSheet: rows[i]){success in
                    if success{
                        rowToBeRemoved.append(i + 1)
                    }
                }
            }
            //shiftManager.mergeTempMemList()
            saveData(completion: nil)
            completion?(true, rowToBeRemoved)
        }
        
    }
    
    func loadFromSignInSheet(filename: String, completion: ((Bool)->Void)?){
        let theFileName = (filename as NSString).lastPathComponent
        
        let index = theFileName.index(theFileName.startIndex, offsetBy: 8)
        let date = theFileName[..<index] // i.e. 02212022

        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        
        if let pathComponent = url.appendingPathComponent(filename) {
        
            //convert that file into one long string
            var data = ""
            do {
                data = try String(contentsOf: pathComponent).removeNewLineInQuotes()
            } catch let error {
                LogManager.writeLog(info: "Error: failed to read content of signIn sheet. \(error)")
                return
            }

            var rows = data.components(separatedBy: "\n")
            guard rows.count >= 1 else {
                LogManager.writeLog(info: "Error: Sign in form is empty!")
                completion?(false)
                return
            }
            
            shiftManager.tempShiftList.removeAll()
            rows.removeFirst(1)
            for row in rows {
                shiftManager.addShift(fromSignInSheet: row, date: String(date))
            }
            shiftManager.mergeTempMemList()
            saveData(completion: completion)
            return
        }else{
            //AlertManager.sendAlert(title: "Failed", message: "Cannot find sign-in form. You can input shift manually", click: "OK", inView: self)
            LogManager.writeLog(info: "Error: Failed to load sign-in form. Cannot find sign-in form in memory. ")
            completion?(false)
            return
            
        }
    }
    
    
    func loadFromCSV(filename: String, completion: ((Bool)->Void)?){
        let fileManager = FileManager.default
        do{
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
        
            let filepath = path.appendingPathComponent(filename + ".csv")
        
            //convert that file into one long string
            var data = ""
            do {
                data = try String(contentsOf: filepath)
            } catch let error{
                LogManager.writeLog(info: "failed to read the content of csv file. Error: \(error)")
                return
            }
            //now split that string into an array of "rows" of data.  Each row is a string.
            var rows = data.components(separatedBy: "\n")
            rows.removeFirst()
            //now loop around each row, and split it into each of its columns
            for row in rows {
                shiftManager.addShift(fromString: row, completion: nil)
            }
            saveData(completion: completion)
        } catch let error{
            LogManager.writeLog(info: "load from csv failed. Error: \(error)")
            completion?(false)
            return
        }
        completion?(true)
    }
}


// MARK: - Save data
extension DataManager{
    func saveData( completion: ((Bool)->Void)? ){
        if self.shiftManager.getShiftCount() == 0{
            LogManager.writeLog(info: "Warning: saveData: Empty shift list. Do not need to save.")
            return
        }
        
        do{
            let userDefaults = UserDefaults.standard
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd-yyyy"
            let key = "memberList-\( formatter.string(from: lastUpdateTime))"
            let encodedData = try NSKeyedArchiver.archivedData(withRootObject: shiftManager.shiftList, requiringSecureCoding: false)
            userDefaults.set(encodedData, forKey: key)
            userDefaults.synchronize()
        }catch{
            LogManager.writeLog(info: "Error: Failed to save the data to user default. Error: \(error)")
            completion?(false)
        }
        
        do{
            let formatter = DateFormatter()
            formatter.dateFormat = "MMddyyyy"
            let filename = "\(formatter.string(from: lastUpdateTime))"
            try saveToCSV(filename: filename)
        }catch{
            LogManager.writeLog(info: "Error: failed to export data to csv. Error \(error)")
            completion?(false)
        }
        
        completion?(true)
    }
    
    
    private func saveToCSV(filename: String) throws {

        let fileManager = FileManager.default
        var fileSaveError = false
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent(filename + "_Records.csv")
            //LogManager.writeLog(info: "Record.csv is saved to \(fileURL.absoluteString)")
            self.shiftManager.exportRecord(){ csvString in
                do{
                    try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                }catch let error{
                    LogManager.writeLog(info: "Error: Failed to save records. Error: \(error)")
                    fileSaveError = true
                }
            }
        } catch let error{
            LogManager.writeLog(info: "Error: Failed to create records in csv file. Error: \(error)")
            fileSaveError = true
        }
        
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent(filename + "_Credit-Debit-Fine.csv")
            self.shiftManager.exportDebitCreditFine(){ creditDebitFineString in
                if let records = creditDebitFineString{
                    do{
                        try records.write(to: fileURL, atomically: true, encoding: .utf8)
                    }catch let error{
                        LogManager.writeLog(info: "Error: Failed to save no-show file. Error: \(error)")
                        fileSaveError = true
                    }
                }else{
                    do{
                        if DataManager.checkFileExist(filename: filename + "_Credit-Debit-Fine.csv"){
                            try FileManager.default.removeItem(at: fileURL)
                        }
                    }catch{
                        LogManager.writeLog(info: "Error: Failed to delete debit-credit file. Error: \(error)")
                    }
                }
            }
        } catch let error {
            LogManager.writeLog(info: "Error: Failed to create no-show file. Error: \(error)")
            fileSaveError = true
        }
        
        if fileSaveError{
            throw FileError.savingFileFailed
        }
    }
    
    
}

// MARK: - load data
extension DataManager {
    func exportShiftFromCC(filename: String?, completion: (([Int], [String]) -> Void)){
        
        guard let filename = filename else {
            completion([], [])
            return
        }

        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)

        if let pathComponent = url.appendingPathComponent(filename) {
            //convert that file into one long string
            var data = ""
            do {
                data = try String(contentsOf: pathComponent).removeNewLineInQuotes()
            } catch let error {
                LogManager.writeLog(info: "Error: failed to read content of signIn sheet. \(error)")
                completion([], [])
                return
            }

            var rows = data.components(separatedBy: "\n")
            guard rows.count >= 1 else {
                LogManager.writeLog(info: "Error: spreadsheet entries are empty!")
                completion([], [])
                return
            }
            rows.removeFirst(1)
            
            var rowToBeUpdated = [Int]()
            var contents = [String]()
            for i in 0..<rows.count{
                //print("spreadsheet row: \(row)")
                let columns = rows[i].components(separatedBy: ",")
                if columns.count < 7 {
                    continue
                }
                
                if DateManager.dayStringToNumber(day: columns[2]) != DateManager.getDayNumber(date: Date()){
                    continue
                }
                
                let formatter = DateManager.dateFormatter
                formatter.dateFormat = "yyyyMMddhh"
                let deposit = columns[1]
                let startTime = DateManager.stringToDate(string: columns[3])
                
                let identifier =  "\(deposit)-\(formatter.string(from: startTime))"
                
                if let mem = shiftManager.getShift(Id: identifier), mem.source == "CC"{
                    mem.config()
                    if mem.status.noShow{
                        rowToBeUpdated.append(i+1)
                        contents.append("no-show")
                    }
                    
                    if mem.status.signedOut{
                        rowToBeUpdated.append(i+1)
                        contents.append("done")
                    }
                }
            }
            completion(rowToBeUpdated, contents)
        }
        
        
    }
}
