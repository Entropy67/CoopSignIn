//
//  ChangePasswordViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 4/10/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class ChangePasswordViewController: UIViewController {
    
    var didMakeChange = false

    var completion: (()->Void)? = nil
    
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
        title = "Change KC Password"
        configureModels()
        tableView.reloadData()
        view.addSubview(tableView)
        tableView.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(didTapCancel))
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: view.width / 6, y: 100, width: view.width / 1.5, height: view.height - 200)
    }
    
    
    
    @objc private func didTapSave(){
        if didMakeChange{
            savePassword()
        }
    }
    
    @objc private func didTapCancel(){
        completion?()
    }
    
    
    private func savePassword(){
        guard models.count >= 2 else {
            return
        }
        
        // update KC password
        for index in 0..<models[0].count{
            let model = models[0][index]
            if model.valueChanged, let KCpassword = model.value{
                UserDefaults.standard.set(KCpassword, forKey: SettingBundleKeys.KCpasswordKey)
            }
        }
        
        // update auto lock time
        for index in 0..<models[1].count{
            let model = models[1][index]
            if model.valueChanged, let autoLockDurationText = model.value, let autoLockDuration = Int(autoLockDurationText){
                UserDefaults.standard.set(autoLockDuration, forKey: SettingBundleKeys.LockTimeKey)
            }
        }
        
        AlertManager.sendAlert(title: "Success", message: "You have updated the KC password", click: "OK", inView: self)
    }
    
    private func updateTableView(){
        configureModels()
        tableView.reloadData()
    }
    
    
    private func configureModels(){
        
        models.removeAll()

        let section0Labels = ["KC passord"]
        let placeHolders0 = ["password"]
        let value0 = [UserDefaults.standard.string(forKey: SettingBundleKeys.KCpasswordKey)]
        
        var section0 = [EditProfileFormModel]()
        for i in 0..<section0Labels.count{
            let model = EditProfileFormModel(label: section0Labels[i], placeholder: placeHolders0[i], value: value0[i])
            section0.append(model)
        }
        models.append(section0)

        
        let section1Labels = ["Auto lock seconds"]
        let placeHolders1 = ["seconds"]
        let value1 = [UserDefaults.standard.string(forKey: SettingBundleKeys.LockTimeKey)]
        
        var section1 = [EditProfileFormModel]()
        for i in 0..<section1Labels.count{
            let model = EditProfileFormModel(label: section1Labels[i], placeholder: placeHolders1[i], value: value1[i])
            section1.append(model)
        }
        models.append(section1)
        
    }
    
    
}


extension ChangePasswordViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return models[section].count

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
            return "Password"
        }else if section == 1{
            return "Auto Lock Time (in second)"
        }
        return " "
    }
}

extension ChangePasswordViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension ChangePasswordViewController: FormTableViewCellDelegate{
    func formtableViewCell(_ cell: FormTableViewCell, didUpdateField updateModel: EditProfileFormModel) {
        self.didMakeChange = true
        if let indexPath = tableView.indexPath(for: cell), indexPath.section < models.count, indexPath.row < models[indexPath.section].count{
            models[indexPath.section][indexPath.row].value = updateModel.value
            models[indexPath.section][indexPath.row].valueChanged = true
        }
    }
}
