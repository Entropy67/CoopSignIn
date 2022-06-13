//
//  SettingViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 5/8/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {
    
    var didMakeChange = false
    var completion: (()->Void)? = nil
    
    var policyManager: PolicyManager? = nil
    var crewManager: CrewManager? = nil
    var securityManager: SecurityManager? = nil
    var googleDriveManager: GoogleDriveManager? = nil
    var shiftManager: ShiftManager? = nil
    
    var compactMode = false
    
    public var models = [[EditProfileFormModel]] ()
    public var sectionTitles = [String]()
    
    public let tableView: UITableView = {
       let tableView = UITableView()
        tableView.register(FormTableViewCell.self, forCellReuseIdentifier: FormTableViewCell.identifier)
        tableView.tag = 100
        tableView.isScrollEnabled = true
        return tableView
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .clear
        }
        
        
        title = "Settings"
        tableView.dataSource = self
        
        compactMode = UserDefaults.standard.bool(forKey: SettingBundleKeys.CompactModeKey)
        
        updateTableView()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(didTapCancel))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: view.width / 6, y: 100, width: view.width / 1.5, height: view.height - 200)
        view.addSubview(tableView)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    @objc private func didTapSave(){
        if didMakeChange{
            save()
        }
    }
    
    @objc private func didTapCancel(){
        completion?()
    }
    
    public func save(){
        
        var info = ""
        
        // title and display mode
        if models[7][0].valueChanged{
            AlertManager.sendAlert(title: "CANNOT change title here", message: "You cannot change the title here. Please go to iPad Setting and change the item <Crew Name>.", click: "OK", inView: self){[weak self] in
                self?.updateTableView()
            }
            return
        }
        
        if models[7][1].valueChanged, let DisplayMode = models[7][1].value{
            UserDefaults.standard.set(DisplayMode, forKey: SettingBundleKeys.CompactModeKey)
            crewManager?.config()
            //shiftManager?.config()
            info = "‼️‼️Please restart the program!"
        }
        
        // save password
        if models[0][0].valueChanged, let password = models[0][0].value{
            UserDefaults.standard.set(password, forKey: SettingBundleKeys.KCpasswordKey)
            securityManager?.config()
        }
        
        if models[0][1].valueChanged, let autoLockDurationText = models[0][1].value, let autoLockDuration = Int(autoLockDurationText){
            UserDefaults.standard.set(autoLockDuration, forKey: SettingBundleKeys.LockTimeKey)
            securityManager?.config()
        }
        
        
        // update daily maximum
        for model in models[1]{
            if model.valueChanged, let capacityText = model.value, let capacity = Int(capacityText){
                if let crew = crewManager?.find(id: model.label) as? Crew{
                    crew.setCapacity(capacity: capacity)
                }
            }
        }
        
        // update weekday(i=0) and weekend (i=1) regular capacity
        for i in 0..<2{
            for j in 0..<models[2+i].count{
                let model = models[2+i][j]
                if model.valueChanged, let capacityText = model.value, let capacity = Int(capacityText){
                    crewManager?.regularCapacity[i][j] = capacity
                }
            }
        }
        
        
        // update policy
        for index in 0..<models[4].count{
            let model = models[4][index]
            if model.valueChanged, let policyText = model.value, let policyValue = Int(policyText){
                policyManager?.setPolicy(index: index, value: policyValue)
            }
        }
        
        // update break time
        for index in 0..<models[5].count{
            let model = models[5][index]
            if model.valueChanged, let breakTimeText = model.value, let breakTimeValue = Int(breakTimeText){
                if let crew = crewManager?.getCrew(at: index){
                    crew.setBreakTime(breakTime: breakTimeValue)
                }
            }
        }
        
        // save Google Drive service
        if models[6][0].valueChanged, let GoogleDriveFlag = models[6][0].value{
            UserDefaults.standard.set(GoogleDriveFlag, forKey: SettingBundleKeys.GoogleDriveKey)
            googleDriveManager?.config()
            info = "‼️‼️Please restart the program!"
        }
        
        if models[6][1].valueChanged, let SpreadsheetFlag = models[6][1].value{
            UserDefaults.standard.set(SpreadsheetFlag, forKey: SettingBundleKeys.GoogleSpreadsheetDriveKey)
            googleDriveManager?.config()
            info = "‼️‼️Please restart the program!"
        }
        
        
        if models[6][2].valueChanged, let UploadFlag = models[6][2].value{
            UserDefaults.standard.set(UploadFlag, forKey: SettingBundleKeys.UploadDataToGoogleDrive)
            googleDriveManager?.config()
            info = "‼️‼️Please restart the program!"
        }
        
        
        

        
        crewManager?.save(){[weak self] success in
            if success{
                AlertManager.sendAlert(title: "Complete", message: "The change has been saved. Please double check the information before you leave. \n\n \(info)", click: "OK", inView: self, completion: self?.updateTableView)
            }else{
                LogManager.writeLog(info: "Failed to save the change")
                AlertManager.sendAlert(title: "Failed", message: "The change hasn't been saved.", click: "OK", inView: self, completion: nil)
            }
        }
        
        
    }
    
    
    private func updateTableView(){
        configureModels(){[weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
    }
    
    public func configureModels(completionHandler: (()->Void)? = nil){
        models.removeAll()
        sectionTitles.removeAll()
        

        ///MARK : change password
        sectionTitles.append("Change Password")
        addSection(labels: ["Crew Chief (KC) password", "Auto lock seconds"],
                   placeHolders: ["password", "second"],
                   values: [UserDefaults.standard.string(forKey: SettingBundleKeys.KCpasswordKey),
                            UserDefaults.standard.string(forKey: SettingBundleKeys.LockTimeKey)
                           ])
        ///MARK: change capacity
        
        if let crewList = crewManager?.allElements as? [Crew] {
            sectionTitles.append("Crew Max Daily Capacity")
            addSection(labels: crewList.map {"\($0.name)"},
                       placeHolders:crewList.map {"\($0.capacity)"},
                       values: crewList.map {"\($0.capacity)"})
        }
        
        
        if let capacity = crewManager?.regularCapacity{
            if compactMode{
                sectionTitles.append("Weekday Daily Capacity")
                addSection(labels: ["Morning", "Afternoon"],
                           placeHolders: capacity[0].map {"\($0)"},
                           values: capacity[0].map {"\($0)"})
                
                sectionTitles.append("Weekend Daily Capacity")
                addSection(labels: ["Morning", "Afternoon"],
                           placeHolders: capacity[1].map {"\($0)"},
                           values: capacity[1].map {"\($0)"})
            }else{
                sectionTitles.append("Weekday Daily Capacity")
                addSection(labels: ["6am-10am",
                                    "10am-2pm",
                                    "2pm-6pm",
                                    "5pm-9pm",
                                    "Other"],
                           placeHolders: capacity[0].map {"\($0)"},
                           values: capacity[0].map {"\($0)"})
                
                sectionTitles.append("Weekend Daily Capacity")
                addSection(labels: ["8am-12pm",
                                    "12pm-4pm",
                                    "4pm-8pm",
                                    "5pm-9pm",
                                    "Other"],
                           placeHolders: capacity[1].map {"\($0)"},
                           values: capacity[1].map {"\($0)"})
            }
        }
        
        ///MARK: change policy
        if let policyManager = policyManager {
            sectionTitles.append("Manage Policy")
            addSection(labels: PolicyManager.policyNames,
                       placeHolders: PolicyManager.policyNames.map {_ in "mins"},
                       values: policyManager.getAllPolicy().map {"\($0)"})
        }
        
        if let crewList = crewManager?.allElements as? [Crew]{
            sectionTitles.append("Change BreakTime")
            addSection(labels: crewList.map {"\($0.name)"},
                       placeHolders: crewList.map {_ in "break mins"},
                       values: crewList.map {"\($0.breakTime)"})
        }
        
        ///MARK: Google service
        sectionTitles.append("Google Service")
        addSection(labels: ["Download from Google Drive (0:no, 1:yes)", "Download Google spreadsheet (0:no, 1:yes)", "Edit Google Drive (0:no, 1:yes)"],
                   placeHolders: ["0 or 1", "0 or 1", "0 or 1"],
                   values: [UserDefaults.standard.string(forKey: SettingBundleKeys.GoogleDriveKey),
                            UserDefaults.standard.string(forKey: SettingBundleKeys.GoogleSpreadsheetDriveKey),
                            UserDefaults.standard.string(forKey: SettingBundleKeys.UploadDataToGoogleDrive)
                           ])
        
        
        ///MARK:  Title and view Mode
        sectionTitles.append("Title and Display Mode")
        addSection(labels: ["Sign-in sheet title", "Use compact display mode (0: no, 1:yes)"],
                   placeHolders: ["Kitchen", "0"],
                   values: [UserDefaults.standard.string(forKey: SettingBundleKeys.CrewNameKey),
                            UserDefaults.standard.string(forKey: SettingBundleKeys.CompactModeKey)
                   ])
        
        
    }
    
    
    private func addSection(labels: [String], placeHolders: [String], values: [String?]){
        var section = [EditProfileFormModel]()
        for i in 0..<labels.count{
            let model = EditProfileFormModel(label: labels[i], placeholder: placeHolders[i], value: values[i])
            section.append(model)
        }
        models.append(section)
    }
    
    public func getSectionTitle(section: Int) -> String{
        if section < sectionTitles.count{
            return sectionTitles[section]
        }
        return " "
    }
    
    
}



extension SettingViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < models.count{
            return models[section].count
        }else{
            return 8
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FormTableViewCell.identifier, for: indexPath) as! FormTableViewCell
        if indexPath.section < models.count{
            cell.configure(with: models[indexPath.section][indexPath.row])
            cell.field.keyboardType = .numberPad
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return getSectionTitle(section: section)
    }
}

extension SettingViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension SettingViewController: FormTableViewCellDelegate{
    func formtableViewCell(_ cell: FormTableViewCell, didUpdateField updateModel: EditProfileFormModel) {
        self.didMakeChange = true
        if let indexPath = tableView.indexPath(for: cell), indexPath.section < models.count, indexPath.row < models[indexPath.section].count{
            models[indexPath.section][indexPath.row].value = updateModel.value
            models[indexPath.section][indexPath.row].valueChanged = true
        }
    }
}

