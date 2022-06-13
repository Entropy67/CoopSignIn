//
//  LogViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/2/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit
import JGProgressHUD
import SpreadsheetView

class MyLabelCell: Cell{
    private let label = UILabel()
    public static let identifier = "MyLabelCell"
    
    public func setup(with text: String){
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = .white
        label.textColor = .black
        contentView.addSubview(label)
    }
    
    public func setColor(with color: UIColor){
        label.backgroundColor = color
        label.textColor = .white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }
}

class SpreadSheetViewController: UIViewController, SpreadsheetViewDataSource{
    
    let spreadsheetView: SpreadsheetView = SpreadsheetView()
    
    var logName: String?
    let fileManager = FileManager.default
    
    var googleDriveManager: GoogleDriveManager? = nil
    var googleDriveTarget: String? = nil
    let spinner = JGProgressHUD(style: .dark)
    
    var completion: (()->Void)? = nil
    
    
    var data = [[String]]()
    
    private let uploadButton: UIButton = {
       let myButton = UIButton()
        myButton.setTitle("Upload to google drive", for: .normal)
        myButton.backgroundColor = MyColor.first_color
        myButton.setTitleColor(MyColor.first_text_color, for: .normal)
        myButton.layer.cornerRadius = 20
        myButton.titleLabel?.font = myButton.titleLabel?.font.withSize(16)
        return myButton
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        spreadsheetView.gridStyle = .solid(width: 1, color: MyColor.first_color)
        spreadsheetView.register(MyLabelCell.self, forCellWithReuseIdentifier: MyLabelCell.identifier)
        spreadsheetView.dataSource = self
        
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareFile))
        } else {
            // Fallback on earlier versions
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "<< Back", style: .plain, target: self, action: #selector(didTapCancel))
        
        if let filename = self.logName {
            data = getData(fullFilename: filename)
            title = filename
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        spreadsheetView.frame = CGRect(x: 0, y: 100, width: view.frame.size.width, height: view.frame.size.height - 100)
        view.addSubview(spreadsheetView)
        uploadButton.frame = CGRect(x: self.view.frame.size.width/2 - 125, y:self.view.frame.size.height - 100, width: 250, height: 50)
        uploadButton.setTitleColor(UIColor.white, for: .normal)
        uploadButton.addTarget(self, action: #selector(self.didTapuploadButton(sender:)), for: .touchUpInside)
        self.view.addSubview(uploadButton)
    }
    
    @objc private func didTapCancel(){
        completion?()
    }
    
    @objc func shareFile(){
        do{
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            if let filename = logName{
                let fileURL = path.appendingPathComponent(filename)
                
                let fileURLtoShare = NSURL(string: fileURL.absoluteString)
                
                var filesToShare = [Any]()
                filesToShare.append(fileURLtoShare!)
                
                let activityVC = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                
                activityVC.popoverPresentationController?.sourceView = self.view
                
                let screenSize = UIScreen.main.bounds.size
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: 10, y:screenSize.height - 100, width:screenSize.width - 20, height:100);
                
                self.present(activityVC, animated: true, completion: nil)
            }
        }catch {
            LogManager.writeLog(info: "Unable to access the file when sharing the file Error: \(error)")
        }
    }
    
    
    @objc func didTapuploadButton(sender: UIButton!){
        guard let googleDriveTarget = googleDriveTarget,
              let googleDriveManager = googleDriveManager,
              let filename = logName else {
            return
        }
        spinner.show(in: view)
        googleDriveManager.uploadCSVFile(filename: filename, destination: googleDriveTarget){ [weak self] (info, error) in
            self?.spinner.dismiss(animated: true)
            if let err = error{
                LogManager.writeLog(info: "Failed to upload \(filename) to Google Drive, Info: \(info ?? "None") Error: \(err)")
            }else{
                AlertManager.sendAlert(title: "Success", message: "You have uploaded \(filename) to Google Drive", click: "OK", inView: self)
            }
        }

    }
    
    
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: MyLabelCell.identifier, for: indexPath) as! MyLabelCell
        
        if indexPath.row < data.count, indexPath.column < data[indexPath.row].count{
            cell.setup(with: data[indexPath.row][indexPath.column])
        }else{
            cell.setup(with: "")
        }
        
        if indexPath.row == 0{
            cell.setColor(with: MyColor.first_color)
        }
        return cell
    }
    
    
    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
        if data.count > 0{
            return data[0].count
        }
        return 10
    }
    
    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
        if data.count > 20{
            return data.count
        }else{
            return 20
        }
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
        return 120
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow row: Int) -> CGFloat {
        return 30
    }
    
    
    private func getData(fullFilename: String) -> [[String]]{
        let dataString = readDataFromCSV(fileName: fullFilename)
        //print("datastring: \(dataString)")
        
        if let data = dataString{
            let dataCleaned = cleanRows(file: data)
            //print("\(csv(data: data))")
            return csv(data: dataCleaned)
        }
        return [[String]]()
    }
    
    private func readDataFromCSV(fileName:String)-> String!{
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            do {
                return try String(contentsOf: fileURL, encoding: .utf8).removeNewLineInQuotes()
            }
            catch {/* error handling here */}
        }
        return ""
    }
    
    func cleanRows(file:String)->String{
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        return cleanFile
    }
    
    func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }
        return result
    }
    
    
    
}

class LogViewController: UIViewController {
    
    let spinner = JGProgressHUD(style: .dark)
    var logName: String?
    let fileManager = FileManager.default
    
    var googleDriveManager: GoogleDriveManager? = nil
    var googleDriveTarget: String? = nil
    
    let txView: UITextView = {
        let tx = UITextView()
        tx.isScrollEnabled = true
        tx.isUserInteractionEnabled = true
        tx.isEditable = false 
        tx.text = "log"
        return tx
    }()
    
    private let uploadButton: UIButton = {
       let myButton = UIButton()
        myButton.setTitle("Upload to google drive", for: .normal)
        myButton.backgroundColor = MyColor.first_color
        myButton.setTitleColor(MyColor.first_text_color, for: .normal)
        myButton.layer.cornerRadius = 20
        myButton.titleLabel?.font = myButton.titleLabel?.font.withSize(16)
        return myButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareFile))
        } else {
            // Fallback on earlier versions
        }
        
        self.txView.frame = CGRect(x: 10, y: 10, width: self.view.frame.width - 20, height: self.view.frame.height - 20)
        
        if let filename = self.logName {
            title = filename
            if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = dir.appendingPathComponent(filename)
                do {
                    self.txView.text = try String(contentsOf: fileURL, encoding: .utf8).removeNewLineInQuotes()
                }
                catch {/* error handling here */}
            }
            self.view.addSubview(self.txView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        uploadButton.frame = CGRect(x: self.view.frame.size.width/2 - 125, y:self.view.frame.size.height - 100, width: 250, height: 50)
        uploadButton.setTitleColor(UIColor.white, for: .normal)
        uploadButton.addTarget(self, action: #selector(self.didTapuploadButton(sender:)), for: .touchUpInside)
        self.view.addSubview(uploadButton)
    }
    
    
    @objc func didTapuploadButton(sender: UIButton!){
        guard let googleDriveTarget = googleDriveTarget,
              let googleDriveManager = googleDriveManager,
              let filename = logName else {
            return
        }
        spinner.show(in: view)
        googleDriveManager.uploadCSVFile(filename: filename, destination: googleDriveTarget){ [weak self] (info, error) in
            self?.spinner.dismiss(animated: true)
            if error != nil{
                LogManager.writeLog(info: "Failed to upload \(filename) to Google Drive, Info: \(info) Error: \(error)")
            }else{
                AlertManager.sendAlert(title: "Success", message: "You have uploaded \(filename) to Google Drive", click: "OK", inView: self)
            }
        }

    }
    
    @objc func shareFile(){
        do{
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            if let filename = logName{
                let fileURL = path.appendingPathComponent(filename)
                
                let fileURLtoShare = NSURL(string: fileURL.absoluteString)
                
                var filesToShare = [Any]()
                filesToShare.append(fileURLtoShare!)
                
                let activityVC = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                
                activityVC.popoverPresentationController?.sourceView = self.view
                
                let screenSize = UIScreen.main.bounds.size
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: 10, y:screenSize.height - 100, width:screenSize.width - 20, height:100);
                
                self.present(activityVC, animated: true, completion: nil)
            }
        }catch {
            LogManager.writeLog(info: "Unable to access the file when sharing the file Error: \(error)")
        }
    }
    

}
