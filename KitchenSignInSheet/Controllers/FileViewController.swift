//
//  FileViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/22/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class FileViewController: UIViewController,UISearchResultsUpdating, UISearchControllerDelegate{
    
    
    @IBOutlet weak var fileTableView: UITableView!
    
    var fileList: [String] = []
    
    var googleDriveManager: GoogleDriveManager? = nil
    var googleDriveTarget: String? = nil
    
    var searchController : UISearchController!
    var viewFileList: [String] = []
    var searchText = ""
    
    private lazy var optionsManager: OptionsManager = {
        let manager = HomeOptionsManager(options: ["Today", "Last 3 days", "Last 7 days",  "Reset"], mainView: self, anchorPosition: "right")
        
        manager.didSelectOption = { (option) in
            if option == "Today"{
                self.showTodayOnly()
            }else if option == "Last 3 days"{
                self.showLast3DayOnly()
            }else if option == "Last 7 days"{
                self.showLast7DayOnly()
            }else if option == "Reset"{
                self.resetData()
            }
            
            manager.didTapBackground()
        }
        return manager
    }()
       
    override func viewDidLoad() {
        
        super.viewDidLoad()
        listAllFile()
        
        
        //navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .done, target: self, action: #selector(didTapShare))
        navigationItem.title = "Spreadsheets"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Options", style: .done, target: self, action: #selector(didTapShowOptionsButton))
        
        self.fileTableView.delegate = self
        self.fileTableView.dataSource = self
        
        self.fileTableView.reloadData()
        
        self.searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        self.searchController.searchResultsUpdater = self
        //self.searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.placeholder = "search by name"
        self.fileTableView.tableHeaderView = self.searchController.searchBar
        self.searchController.showsSearchResultsController = true

    }
    
    override func willMove(toParent parent: UIViewController?) {
        self.optionsManager.closeOptions()
        super.willMove(toParent: parent)
        
    }
    
    @objc func didTapShowOptionsButton(_ sender: Any) {
        if self.optionsManager.didShowOptions{
            self.optionsManager.closeOptions()
        }else{
            self.optionsManager.showOptions()
        }
    }
    
    func showLast3DayOnly(){
        self.showLastNDaysOnly(dayNumber: 3)
    }
    
    func showLast7DayOnly(){
        self.showLastNDaysOnly(dayNumber: 7)
    }
    
    private func showLastNDaysOnly(dayNumber: Int){
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddyyyy"
        
        let fromDate = Calendar.current.date(byAdding: .day, value: -dayNumber, to: Date()) ?? Date()
        
        self.viewFileList = self.fileList.filter({(filename: String) -> Bool in
            let numericPrefix = filename.prefix(while: { "0"..."9" ~= $0 })
            
            let filedate = formatter.date(from: String(numericPrefix)) ?? Date()
            return filedate > fromDate
        })
        self.fileTableView.reloadData()
    }
    
    
    func showTodayOnly(){
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddyyyy"
        let today = formatter.string(from: Date())
        self.searchMember(searchText: today)
    }
    
    func resetData(){
        self.viewFileList = self.fileList
        self.fileTableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text{
            if searchText == ""{
                self.fileTableView.reloadData()
            }else{
                self.searchMember(searchText: searchText)
                self.searchText = searchText
            }
        }
    }
    
    private func searchMember(searchText: String){

        self.viewFileList = searchText.isEmpty ? self.fileList : self.fileList.filter({(filename: String) -> Bool in
            return filename.range(of: searchText, options: .caseInsensitive) != nil
        })
        
        self.fileTableView.reloadData()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        self.searchMember(searchText: self.searchText)
        //print("will dismiss search controller, searchtext =", self.searchText)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        self.searchMember(searchText: self.searchText)
        //print("did dismiss search controller, searchtext =", self.searchText)
    }
    
    
    
    
    func listAllFile(){
        
        self.fileList.removeAll()
        
        do {
            // Get the document directory url
            let documentDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            //print("documentDirectory", documentDirectory.path)
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: documentDirectory,
                includingPropertiesForKeys: nil
            )
            
            //print("directoryContents:", directoryContents.map { $0.localizedName ?? $0.lastPathComponent })
            
            for url in directoryContents {
                self.fileList.append(url.localizedName ?? url.lastPathComponent)
            }
            
            self.fileList.sort()
            self.fileList.reverse()
            
        } catch {
            LogManager.writeLog(info: "List file error \(error)")
        }
        self.viewFileList = self.fileList
    }

}



extension FileViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let logName = viewFileList[indexPath.row]
        
        if logName.hasSuffix("csv"){
            let vc = SpreadSheetViewController()
            vc.logName = viewFileList[indexPath.row]
            vc.googleDriveTarget = googleDriveTarget
            vc.googleDriveManager = googleDriveManager
            vc.completion = {[weak self] () in
                self?.navigationController?.popViewController(animated: true)
            }
            navigationController?.pushViewController(vc, animated: true)
            
        }else{
            let vc = storyboard?.instantiateViewController(identifier: "logViewer") as! LogViewController
            vc.logName = viewFileList[indexPath.row]
            vc.googleDriveTarget = googleDriveTarget
            vc.googleDriveManager = googleDriveManager
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension FileViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewFileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath)
        
        cell.imageView?.image = UIImage(systemName: "doc")
        cell.textLabel?.text = self.viewFileList[indexPath.row]
        return cell
    }
    
    
    
}


extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var isMP3: Bool { typeIdentifier == "public.mp3" }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
    var hasHiddenExtension: Bool {
        get { (try? resourceValues(forKeys: [.hasHiddenExtensionKey]))?.hasHiddenExtension == true }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.hasHiddenExtension = newValue
            try? setResourceValues(resourceValues)
        }
    }
}
