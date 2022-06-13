//
//  ChangeCapacityViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 4/6/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class ChangeCapacityViewController: UIViewController {
    
    var didMakeChange = false

    var completion: (()->Void)? = nil

    var crewManager: CrewManager? = nil
    
    public let tableView: UITableView = {
       let tableView = UITableView()
        tableView.register(FormTableViewCell.self, forCellReuseIdentifier: FormTableViewCell.identifier)
        tableView.tag = 100
        tableView.isScrollEnabled = true
        return tableView
    }()
    
    
    public var models = [[EditProfileFormModel]] ()
    
    init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Change Capacity"
        configureModels()
        tableView.reloadData()
        view.addSubview(tableView)
        tableView.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(didTapCancel))

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: view.width / 4, y: 100, width: view.width / 2, height: view.height - 200)
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    @objc private func didTapSave(){
        if didMakeChange{
            saveCapacity()
        }
    }
    
    @objc private func didTapCancel(){
        completion?()
    }
    
    
    private func saveCapacity(){
        guard models.count >= 3 else {
            return
        }
        // update daily total
        for model in models[0]{
            if model.valueChanged, let capacityText = model.value, let capacity = Int(capacityText){
                if let crew = crewManager?.find(id: model.label) as? Crew{
                    crew.setCapacity(capacity: capacity)
                }
            }
        }
        
        // update weekday(i=0) and weekend (i=1) regular capacity
        for i in 0..<2{
            for j in 0..<models[1+i].count{
                let model = models[1+i][j]
                if model.valueChanged, let capacityText = model.value, let capacity = Int(capacityText){
                    crewManager?.regularCapacity[i][j] = capacity
                }
            }
        }
        
        crewManager?.save(){[weak self] success in
            if success{
                AlertManager.sendAlert(title: "Complete", message: "The change has been saved. Please double check the capacity list before leaving.", click: "OK", inView: self, completion: self?.updateTableView)
            }else{
                LogManager.writeLog(info: "Failed to save crew list")
                AlertManager.sendAlert(title: "Failed", message: "The change hasn't been saved.", click: "OK", inView: self, completion: nil)
            }
        }
    }
    
    private func updateTableView(){
        configureModels()
        tableView.reloadData()
    }
    
    
    private func configureModels(){
        
        models.removeAll()
        
        // total
        guard let crewManager = crewManager else {
            return
        }

        var section0Labels = [String]()
        var placeHolders0 = [String]()
        var value0 = [String]()
        for crew in crewManager.getCrewList(){
            
            section0Labels.append("\(crew.name)")
            placeHolders0.append("\(crew.capacity)")
            value0.append("\(crew.capacity)")
        }
        
        
        var section0 = [EditProfileFormModel]()
        for i in 0..<section0Labels.count{
            let model = EditProfileFormModel(label: section0Labels[i], placeholder: placeHolders0[i], value: value0[i])
            section0.append(model)
        }
        models.append(section0)
        
        
        let compactMode =  UserDefaults.standard.bool(forKey: SettingBundleKeys.CompactModeKey)
        
        
        // weekdays
        var section1Labels = ["6am-10am",
                              "10am-2pm",
                              "2pm-6pm",
                              "5pm-9pm",
                              "Other"
        ]
        
        if compactMode{
            section1Labels = ["Morning", "Afternoon"]
        }
        
        var placeHolders1 = [String]()
        var value1 = [String]()
        for capacity in crewManager.regularCapacity[0]{
            placeHolders1.append("\(capacity)")
            value1.append("\(capacity)")
        }
        
        var section1 = [EditProfileFormModel]()
        for i in 0..<section1Labels.count{
            let model = EditProfileFormModel(label: section1Labels[i], placeholder: placeHolders1[i], value: value1[i])
            section1.append(model)
        }
        models.append(section1)
        
        
        // weekends
        var section2Labels = ["8am-12pm",
                              "12pm-4pm",
                              "4pm-8pm",
                              "5pm-9pm",
                              "Other"
        ]
        
        if compactMode{
            section2Labels = ["Morning", "Afternoon"]
        }
        
        
        var placeHolders2 = [String]()
        var value2 = [String]()
        for capacity in crewManager.regularCapacity[1]{
            placeHolders2.append("\(capacity)")
            value2.append("\(capacity)")
        }
        
        var section2 = [EditProfileFormModel]()
        for i in 0..<section2Labels.count{
            let model = EditProfileFormModel(label: section2Labels[i], placeholder: placeHolders2[i], value: value2[i])
            section2.append(model)
        }
        models.append(section2)
    }
    
    
}


extension ChangeCapacityViewController: UITableViewDataSource{
    
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
        if section == 0{
            return "Daily total"
        }else if section == 1{
            return "Weekday regular"
        }else if section == 2{
            return "Weekend regular"
        }
        return " "
    }
}

extension ChangeCapacityViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension ChangeCapacityViewController: FormTableViewCellDelegate{
    func formtableViewCell(_ cell: FormTableViewCell, didUpdateField updateModel: EditProfileFormModel) {
        self.didMakeChange = true
        if let indexPath = tableView.indexPath(for: cell), indexPath.section < models.count, indexPath.row < models[indexPath.section].count{
            models[indexPath.section][indexPath.row].value = updateModel.value
            models[indexPath.section][indexPath.row].valueChanged = true
        }
    }
}
