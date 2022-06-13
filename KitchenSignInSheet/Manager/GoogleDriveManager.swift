//
//  GoogleDriveManager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/19/22.
//  Copyright © 2022 AMO. All rights reserved.
//


import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import UIKit

final class GoogleDriveManager{
    
    public var googleDriveService: GTLRDriveService? = nil
    public var googleUser: GIDGoogleUser? = nil
    public var googleSheetService: GTLRSheetsService? = nil
    public var useGoogleDrive: Bool = true
    public var useSpreadsheet: Bool = true
    public var uploadDataToGoogleDrive: Bool = true
    init(){}
    
    init(googleUser: GIDGoogleUser?, googleDriveService: GTLRDriveService?){
        self.googleUser = googleUser
        self.googleDriveService = googleDriveService
    }
    
    public func config(){
        useGoogleDrive = (UserDefaults.standard.integer(forKey: SettingBundleKeys.GoogleDriveKey) != 0)
        useSpreadsheet = (UserDefaults.standard.integer(forKey: SettingBundleKeys.GoogleSpreadsheetDriveKey) != 0)
        uploadDataToGoogleDrive = (UserDefaults.standard.integer(forKey: SettingBundleKeys.UploadDataToGoogleDrive) != 0)
    }
    
    
    public enum GoogleDriveError: Error {
        case failedToDelete
        case failedToFetch
        case failedToUpload
        case failedToCreate
        case noGoogleService
        case noSpreadSheetService
        case failedToFindFolder
        case noSpreadsheetID
    }
}

// MARK: - Manage sign-in form and records

extension GoogleDriveManager{
    
    func searchSignInForm(fileNameStrings: [String], onCompleted: @escaping (String?, Error?) -> ()){
        if !useGoogleDrive, !useSpreadsheet{
            onCompleted(nil, GoogleDriveError.noGoogleService)
            return
        }
        
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        
        var q = ""
        let num_of_condition = fileNameStrings.count
        
        for i in 0..<num_of_condition{
            if i < num_of_condition - 1{
                q += "name contains '\(fileNameStrings[i])' and "
            }else{
                q += "name contains '\(fileNameStrings[i])'"
            }
        }
        query.q = q
        
        guard let googleDriveService = self.googleDriveService else{
            onCompleted("Google drive service is not available", GoogleDriveError.noGoogleService)
            LogManager.writeLog(info: "Google Drive service is not available")
            return
        }
        
        googleDriveService.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
        
        
    }
    
    
    func uploadData(target: String, timeStamp: Date?, completion: @escaping (Bool, String) -> ()){
        if !useGoogleDrive || !uploadDataToGoogleDrive{
            completion(false, "Upload action is disabled")
            return
        }
        
        guard let timeStamp = timeStamp else{
            completion(false, "time stamp error")
            return
        }
        //LogManager.writeLog(info: "try to upload data")
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddyyyy"
        let filename = "\( formatter.string(from: timeStamp))_Records"
        
        var allError = ""
        
        
        if self.googleUser != nil{
            
            uploadCSV(filename: filename + ".csv", destination: target){ [weak self](info, error) in
                allError += info ?? "" + ";"
                if allError != ""{
                    completion(false, allError)
                }else{
                    self?.uploadCSV(filename: filename + "_Credit-Debit-Fine.csv", destination: target){(info, error) in if error != nil{allError += info ?? "" + ";"}}
                    if allError != ""{
                        completion(false, allError)
                    }else{
                        completion(true, allError)
                    }
                }
                LogManager.writeLog(info: "upload DATA to google drive finishes. error: \(allError)")
            }
            return
        }else{
            allError += "; You haven't logged in the Google Drive. Please log in first"
        }
        completion(false, allError)
        LogManager.writeLog(info: "did not upload DATA to google drive. error: \(allError)")
        return
    }
    
    public func downloadFile(fileID: String, onCompleted: @escaping (Data?, Error?) -> ()){
        if !useGoogleDrive{
            onCompleted(nil, GoogleDriveError.noGoogleService)
            return
        }
        
        download(fileID, onCompleted: onCompleted)
    }
    
    public func uploadCSVFile(filename: String, destination: String, complition: @escaping (String?, Error?)->()){
        if !useGoogleDrive || !uploadDataToGoogleDrive{
            complition("Google Drive upload service is disabled", GoogleDriveError.noGoogleService)
            return
        }
        uploadCSV(filename: filename, destination: destination, complition: complition)
        
    }
    
    
}

// MARK: - Google sheet service
extension GoogleDriveManager{
    
    public func createSpreadsheet(filename: String, completion: @escaping ((Bool, Error?) -> Void)){
        if !useGoogleDrive || !useSpreadsheet || !uploadDataToGoogleDrive{
            completion(false, GoogleDriveError.noSpreadSheetService)
            return
        }
        
        googleSheetService?.authorizer = googleUser?.authentication.fetcherAuthorizer()
        
        let newSheet = GTLRSheets_Spreadsheet.init()
        let properties = GTLRSheets_SpreadsheetProperties.init()
        
        properties.title = filename
        newSheet.properties = properties
        
        let query = GTLRSheetsQuery_SpreadsheetsCreate.query(withObject: newSheet)
        query.fields = "spreadsheetId"
        
        query.completionBlock = {[weak self] (ticket, result, NSError) in
            if let error = NSError{
                completion(false, error)
            }else{
                let response = result as! GTLRSheets_Spreadsheet
                let identifier = response.spreadsheetId
                guard let identifier = identifier else {
                    completion(false, GoogleDriveError.noSpreadsheetID)
                    return
                }

                self?.updateRowFromSpreadsheet(spreadsheetId: identifier,
                                         rowToBeUpdated: [0, 0, 0, 0, 0, 0, 0, 0],
                                         columnToBeUpdated: ["A", "B", "C", "D", "E", "F", "G", "H"],
                                         content: ["Name (FirsName LastName)", "Deposit (be accurate!)", "Day (3 letters, i.e. Mon)", "Start Time (24h i.e. 9:00)", "End Time (24h i.e. 14:00)", "Crew (must exist on iPad)", "Type (regular: weekly shift; temp: only one time; credit: only one time;)", "Status (auto-updated)"])
                
                
                LogManager.writeLog(info: "Successfully created a new spreadsheet: \(filename). ID: \(identifier)")
                completion(true, nil)
            }
        }
        
        googleSheetService?.executeQuery(query)
        
    }
    
    public func getDataFromSpreadsheet(spreadsheetId: String, completion: (([[Any]])->Void)? = nil){
        
        if !useGoogleDrive || !useSpreadsheet{
            completion?([])
            return
        }
        
        googleSheetService?.authorizer = googleUser?.authentication.fetcherAuthorizer()
        //let spreadsheetId = "1xlNJWMP8xWr1jKZw1z6kvSNHm50bXmgu7ICxDZeixxA"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: spreadsheetId, range: "Sheet1")
        googleSheetService?.executeQuery(query){ _, result, error in
            //print(" download result: \(result)")
            if let err = error{
                LogManager.writeLog(info: "Google Drive Manager: Failed to read data from spreadsheet. Error: \(err)")
                completion?([])
            }else{
                if let res = result as? GTLRSheets_ValueRange, let data = res.values{
                    //data.removeFirst()
                    completion?(data)
                }else{
                    LogManager.writeLog(info: "Google Drive Manager: Failed fetch data from spreadsheet.")
                    completion?([])
                }
            }
        }
    }
    
    public func removeRowFromSpreadsheet(spreadsheetId: String, rowToBeRemoved: [Int]){
        if !useGoogleDrive || !useSpreadsheet || !uploadDataToGoogleDrive{
            return
        }
        
        //let spreadsheetIds = "1xlNJWMP8xWr1jKZw1z6kvSNHm50bXmgu7ICxDZeixxA"
        //let rowToBeRemoveds = [1, 2, 4]
        let toDelete = GTLRSheets_ClearValuesRequest.init()
        var ranges = [String]()
        for rows in rowToBeRemoved{
            ranges.append("A\(rows+1):G\(rows+1)")
        }
        
        let group = DispatchGroup()
        ranges = ranges.map{"Sheet1" + "!" + $0};
        for range in ranges{
            group.enter()
            let query = GTLRSheetsQuery_SpreadsheetsValuesClear.query(withObject: toDelete, spreadsheetId: spreadsheetId, range: range)
            googleSheetService?.executeQuery(query){_, result, error in
                
                group.leave()
                if let err = error{
                    LogManager.writeLog(info: "Goorle drive: Failed to remove row from spreadsheet. error: \(err)")
                }
            }
        }
    }
    
    
    public func updateRowFromSpreadsheet(spreadsheetId: String, rowToBeUpdated: [Int], columnToBeUpdated: [String], content: [String]){
        if !useGoogleDrive || !useSpreadsheet || !uploadDataToGoogleDrive{
            return
        }
        
        print("content: \(content)")
        guard rowToBeUpdated.count == columnToBeUpdated.count,  columnToBeUpdated.count == content.count else{
            return
        }
        
        //let spreadsheetId = "1xlNJWMP8xWr1jKZw1z6kvSNHm50bXmgu7ICxDZeixxA"
        //let rowToBeRemoved = [1, 2, 4]
        
        var ranges = [String]()
        for i in 0..<rowToBeUpdated.count{
            ranges.append("\(columnToBeUpdated[i])\(rowToBeUpdated[i]+1):\(columnToBeUpdated[i])\(rowToBeUpdated[i]+1)")
        }
        
        print("ranges \(ranges)")
        
        let group = DispatchGroup()
        ranges = ranges.map{"Sheet1" + "!" + $0};
        
        for i in 0..<ranges.count{
            group.enter()
            let valueRange = ValueRange(majorDimension: "ROWS", range: ranges[i], values: [[content[i]]])
            let jsonEncoder = JSONEncoder()
            do{
                let jsonData = try jsonEncoder.encode(valueRange)
                if let json = String(data: jsonData, encoding: String.Encoding.utf8){
                    
                    
                    let toChange = GTLRSheets_ValueRange(json: convertToDictionary(text:json))
                    
                    let query0 = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: toChange, spreadsheetId: spreadsheetId, range: ranges[i])
                    query0.valueInputOption = kGTLRSheetsValueInputOptionRaw
                    
                    googleSheetService?.executeQuery(query0){_, result, error in
                        group.leave()
                        if let err = error{
                            LogManager.writeLog(info: "Goorle drive: Failed to update the spreadsheet. error: \(err)")
                        }
                    }
                }
            }catch{
                LogManager.writeLog(info: "error:\(error)")
            }
        }
        
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
                                         
}

// MARK: - General Google drive service

extension GoogleDriveManager{
    
    /// delete a file on google drive using fileID
    private func delete(_ fileID: String?, onCompleted: @escaping ((Error?) -> ())) {
        if fileID == nil{
            onCompleted(nil)
            return
        }
        guard let googleDriveService = self.googleDriveService else{
            onCompleted(GoogleDriveError.noGoogleService)
            return
        }
        
        googleDriveService.executeQuery(GTLRDriveQuery_FilesDelete.query(withFileId: fileID!)) { (ticket, nilFile, error) in
            onCompleted(error)
        }
    }
    
    
    /// search a file that contains filename
    private func search(_ fileName: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        query.q = "name contains '\(fileName)'"

        
        guard let googleDriveService = self.googleDriveService else{
            onCompleted("Google drive service is not available", GoogleDriveError.noGoogleService)
            LogManager.writeLog(info: "Google Drive service is not available")

            return
        }
        
        googleDriveService.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }
    
    
    /// download data using fileID
    private func download(_ fileID: String, onCompleted: @escaping (Data?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        guard let googleDriveService = self.googleDriveService else{
            onCompleted(nil, GoogleDriveError.noGoogleService)
            return
        }
        googleDriveService.executeQuery(query) { (ticket, file, error) in
            onCompleted((file as? GTLRDataObject)?.data, error)
        }
    }
    
    
    /// list files in folderID
    private func listFiles(_ folderID: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 100
        query.q = "'\(folderID)' in parents"
        guard let googleDriveService = self.googleDriveService else{
            onCompleted(nil, GoogleDriveError.noGoogleService)
            return
        }
        googleDriveService.executeQuery(query) { (ticket, result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }
    
    /// list files in folder name
    private func listFilesInFolder(_ folder: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        search(folder) { (folderID, error) in
            guard let ID = folderID else {
                onCompleted(nil, error)
                return
            }
            self.listFiles(ID, onCompleted: onCompleted)
        }
    }
    
    ///create a folder with name
    private func createFolder(_ name: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = "application/vnd.google-apps.folder"
            
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"
        
        guard let googleDriveService = self.googleDriveService else{
            onCompleted(nil, GoogleDriveError.noGoogleService)
            return
        }
        googleDriveService.executeQuery(query) { (ticket, folder, error) in
            onCompleted((folder as? GTLRDrive_File)?.identifier, error)
        }
    }
    
    
    /// upload data in path to parentID
    private func upload(_ parentID: String, path: String, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
            
        guard let data = FileManager.default.contents(atPath: path) else {
            
            guard let pathURL = URL(string: path) else{
                LogManager.writeLog(info: "upload: failed to convert path to URL")
                onCompleted?("Failed to convert path to URL! ", FileError.readingFileFailed)
                return
            }
            do{
                LogManager.writeLog(info:"upload: path content \( try String(contentsOf: pathURL ))")
            }catch{
                LogManager.writeLog(info:"upload: failed to fetch pathURL content")
            }
            onCompleted?("Failed to get the data, because there is no such file! ", FileError.readingFileFailed)
            return
        }
        
        guard let googleDriveService = self.googleDriveService else{
            onCompleted?("Google service is not available", GoogleDriveError.noGoogleService)
            return
        }
            
        let file = GTLRDrive_File()
        file.name = path.components(separatedBy: "/").last
        file.parents = [parentID]

        self.search(file.name!){ (fileID, error) in
            if error==nil{
                self.delete(fileID) {(error) in
                    if error == nil{
                        //LogManager.writeLog(info: "upload: delete google drive file successfully!")
                        let uploadParams = GTLRUploadParameters.init(data: data, mimeType: MIMEType)
                        uploadParams.shouldUploadWithSingleRequest = true
                            
                        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParams)
                        query.fields = "id"
                        query.keepRevisionForever = false
                        
                        googleDriveService.executeQuery(query, completionHandler: { (ticket, file, error) in
                            //onCompleted?((file as? GTLRDrive_File)?.identifier, error)// this returns the fileID
                            if error != nil {
                                onCompleted?("upload: google drive service unable to execute query! ", error)
                            }else{
                                onCompleted?("", error)
                            }
                        })

                    }else{
                        LogManager.writeLog(info: "upload: unable to delete the file: \(String(describing: error))")
                        onCompleted?("unable to delete the file: \(file.name!)", error)
                    }
                }
            }else{
                LogManager.writeLog(info: "upload: search error \(String(describing: fileID))")
                onCompleted?("search error when try to find \(file.name!)", error)
            }
        }
    }
    
    
    /// upload a file with filePath to folder with folderName
    private func uploadFile(_ folderName: String, filePath: String, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
            
        search(folderName) { (folderID, error) in
                
            if let ID = folderID {
                LogManager.writeLog(info: "GoogleDrive: upload found folder \(folderName). start uploading")
                self.upload(ID, path: filePath, MIMEType: MIMEType, onCompleted: onCompleted)
            } else {
                LogManager.writeLog(info: "GoogleDrive: upload did not find folder \(folderName). Error: \(error)")
                onCompleted?("Failed to upload the file because cannot connect to the folder \(folderName) on Google Drive. This might because internet issue. Please try again later. If this continues happening, please contact amo@ucha.coop. ", GoogleDriveError.failedToFindFolder)
//                self.createFolder(folderName, onCompleted: { (folderID, error) in
//                    guard let ID = folderID else {
//                        LogManager.writeLog(info: "GoogleDrive: upload did not find folder \(folderName). frailed to creating \(folderName)")
//                        onCompleted?("uploadFile: createFolder failed! ", error)
//                        return
//                    }
//                    LogManager.writeLog(info: "GoogleDrive: upload did not find folder \(folderName).  created \(folderName). start uploading.")
//                    self.upload(ID, path: filePath, MIMEType: MIMEType, onCompleted: onCompleted)
//                })
            }
        }
    }
    
    
    /// upload csv file to destination
    private func uploadCSV(filename: String, destination: String, complition: @escaping (String?, Error?)->()){
        // automatically upload to google drive
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
            let testFilePath = documentsDir.appendingPathComponent(filename).path
            //googleDriveManager.uploadFile("\(self.CREW_NAME)DailyFDC", filePath: testFilePath, MIMEType: "text/csv", onCompleted: complition)
            uploadFile(destination, filePath: testFilePath, MIMEType: "text/csv", onCompleted: complition)
            return
        }
        LogManager.writeLog(info: "Error: cannot locate the document when upload csv")
        complition("Error (uploadCSV): cannot locate the document", FileError.fetchingPthURLFailed)
    }
    
}

struct ValueRange: Codable {
    var majorDimension: String
    var range: String
    var values: [[String]]
}
