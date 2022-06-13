//
//  ChangePolicyViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 4/8/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class ChangePolicyViewController: UIViewController {
    
    var didMakeChange = false

    var completion: (()->Void)? = nil

    var policyManager: PolicyManager? = nil
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
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .clear
        }
        title = "Change Policy"
        configureModels()
        tableView.reloadData()
        view.addSubview(tableView)
        tableView.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(didTapCancel))
        
        //hideKeyboardWhenTappedAround()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: view.width / 6, y: 100, width: view.width / 1.5, height: view.height - 200)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    @objc private func didTapSave(){
        if didMakeChange{
            savePolicy()
        }
    }
    
    @objc private func didTapCancel(){
        completion?()
    }
    
    
    private func savePolicy(){
        guard let policyManager = policyManager,
              let crewManager = crewManager,
              models.count >= 2,
              models[0].count >= policyManager.policyList.count,
              models[1].count >= crewManager.count  else {
            return
        }
        
        // update policy
        for index in 0..<models[0].count{
            let model = models[0][index]
            if model.valueChanged, let policyText = model.value, let policyValue = Int(policyText){
                policyManager.setPolicy(index: index, value: policyValue)
            }
        }
        
        // update break time
        for index in 0..<models[1].count{
            let model = models[1][index]
            if model.valueChanged, let breakTimeText = model.value, let breakTimeValue = Int(breakTimeText){
                if let crew = crewManager.getCrew(at: index){
                    crew.setBreakTime(breakTime: breakTimeValue)
                }
            }
        }
        
        crewManager.save(){[weak self]success in
            if success{
                AlertManager.sendAlert(title: "Complete", message: "The change has been saved. Please double check the policy list before leaving.", click: "OK", inView: self, completion: self?.updateTableView)
            }else{
                LogManager.writeLog(info: "Failed to save policy change")
                AlertManager.sendAlert(title: "Failed", message: "Failed to save the change in crew break time", click: "OK", inView: self, completion: nil)
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
        guard let policyManager = policyManager else {
            return
        }

        var section0Labels = [String]()
        var placeHolders0 = [String]()
        var value0 = [String]()
        for index in 0..<policyManager.policyList.count{
            section0Labels.append(PolicyManager.policyNames[index])
            placeHolders0.append("")
            value0.append("\(policyManager.getPolicy(index: index))")
        }
        
        var section0 = [EditProfileFormModel]()
        for i in 0..<section0Labels.count{
            let model = EditProfileFormModel(label: section0Labels[i], placeholder: placeHolders0[i], value: value0[i])
            section0.append(model)
        }
        models.append(section0)
        
        guard let crewManager = crewManager else {
            return
        }

        var section1Labels = [String]()
        var placeHolders1 = [String]()
        var value1 = [String]()
        for crew in crewManager.getCrewList(){
            section1Labels.append("\(crew.name)")
            placeHolders1.append("\(crew.breakTime)")
            value1.append("\(crew.breakTime)")
        }
        
        var section1 = [EditProfileFormModel]()
        for i in 0..<section1Labels.count{
            let model = EditProfileFormModel(label: section1Labels[i], placeholder: placeHolders1[i], value: value1[i])
            section1.append(model)
        }
        models.append(section1)
        
    }
    
    
}


extension ChangePolicyViewController: UITableViewDataSource{
    
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
            return "Current Policy"
        }else if section == 1{
            return "Break Time Limit (minutes)"
        }
        return " "
    }
}

extension ChangePolicyViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension ChangePolicyViewController: FormTableViewCellDelegate{
    func formtableViewCell(_ cell: FormTableViewCell, didUpdateField updateModel: EditProfileFormModel) {
        self.didMakeChange = true
        if let indexPath = tableView.indexPath(for: cell), indexPath.section < models.count, indexPath.row < models[indexPath.section].count{
            models[indexPath.section][indexPath.row].value = updateModel.value
            models[indexPath.section][indexPath.row].valueChanged = true
        }
    }
}
