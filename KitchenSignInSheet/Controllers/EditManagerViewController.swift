//
//  EditManagerViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 5/7/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit


struct EditProfileFormModel{
    let label: String
    var placeholder: String
    var value: String?
    var valueChanged = false
}

class EditManagerViewController: UIViewController, UITableViewDataSource  {
    var manager: Manager? = nil
    
    var completion: (()->Void)? = nil
    public var didMakeChange = false
    var hiddenSections = Set<Int>()
    
    var sectionLabels = [["Name", "ID"]]
    var sectionPlaceHolder = [["Your name", "Your ID"]]
    var sectionValues: [[String?]] = [[nil, nil]]
    
    public let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(FormTableViewCell.self, forCellReuseIdentifier: FormTableViewCell.identifier)
        tableView.tag = 100
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    public let listView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tag = 200
        return tableView
    }()
    
    
    public let tableViewHead: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Add"
        label.textColor = MyColor.first_color
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    
    public let listHead: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Existing"
        label.textColor = MyColor.first_color
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    
    public var models = [[EditProfileFormModel]] ()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        configureModels()
        
        view.addSubview(tableView)
        view.addSubview(tableViewHead)
        tableView.dataSource = self
        
        view.addSubview(listHead)
        view.addSubview(listView)
        listView.dataSource = self
        listView.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didTapCancel))
        
        if let manager = manager {
            if manager.count > 1{
                for section in 1..<manager.count{
                    hiddenSections.insert(section)
                }
            }
        }

        tableView.reloadData()
        listView.reloadData()

        // keyborad
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //hideKeyboardWhenTappedAround()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        
        listView.frame = CGRect(x: view.width / 6 - 50,
                                    y: 150,
                                    width: view.width / 3,
                                    height: view.height - 200)
        
        listHead.frame = CGRect(x: view.width / 6 - 50,
                                    y: 100,
                                    width: view.width / 3,
                                    height: 50)
        
        tableView.frame = CGRect(x: listView.right + 100,
                                 y: 150,
                                 width: view.width / 3,
                                 //height: view.height - 200)
                                 height: 400)
        
        tableViewHead.frame = CGRect(x: listView.right + 100,
                                     y: 100,
                                     width: view.width / 3,
                                     height: 50)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    public func getElementInfo(section: Int, row: Int) -> String{
        return ""
    }
    
    public func getElementInfoCount() -> Int{
        return 5
    }
    
    public func getElementInfo(element: Element) -> [[String?]]{
        return [[""]]
    }
    
    public func getElementColor(element: Element) -> UIColor{
        return .black
    }
    
    public func configureModels(){
        guard sectionLabels.count == sectionPlaceHolder.count, sectionLabels.count == sectionValues.count else{
            return
        }
        models.removeAll()
        for i in 0..<sectionLabels.count{
            if sectionLabels[i].count == sectionPlaceHolder[i].count, sectionLabels[i].count == sectionValues[i].count {
                var section1 = [EditProfileFormModel]()
                for j in 0..<sectionLabels[i].count{
                    let model = EditProfileFormModel(label: sectionLabels[i][j],
                                                     
                                                    placeholder: sectionPlaceHolder[i][j],
                                                     value: sectionValues[i][j])
                    section1.append(model)
                }
                models.append(section1)
            }
        }
        tableView.reloadData()
    }
    
    
    public func save(){
        /// TODO write the save function
    }
    
    @objc func didTapSave(){
        if didMakeChange{
            save()
        }
    }
    
    @objc private func didTapCancel(){
        completion?()
    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height / 4
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    
    // MARK:  TABLE
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 100{
            return models.count
        }else{
            if let manager = manager {
                return manager.count
            }
           return 0
        }
    }
    
    
    private func createSectionHeader(section: Int) -> UIView? {
        let sectionHeader = UIView(frame: .zero)
        sectionHeader.backgroundColor = .systemGray5
        
        if let element = manager?.getElement(at: section) {
            let sectionButton = UIButton()
            sectionButton.setTitle(element.name,
                                   for: .normal)
            sectionButton.backgroundColor = .systemGray5
            sectionButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
            sectionButton.setTitleColor(getElementColor(element: element), for: .normal)
            sectionButton.tag = section
            sectionButton.addTarget(self,
                                    action: #selector(self.hideSection(sender:)),
                                    for: .touchUpInside)
            sectionHeader.addSubview(sectionButton)
            // use auto layout
            sectionButton.translatesAutoresizingMaskIntoConstraints = false
            // add width / height constraints
            NSLayoutConstraint.activate([
                sectionButton.leadingAnchor.constraint(equalTo: sectionHeader.leadingAnchor, constant: 0),
                sectionButton.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor, constant: -60),
                sectionButton.topAnchor.constraint(equalTo: sectionHeader.topAnchor, constant: 0),
                sectionButton.heightAnchor.constraint(equalTo: sectionHeader.heightAnchor)
            ])
            
            
            let sectionDeleteButton = UIButton()
            sectionDeleteButton.setImage(UIImage(systemName: "x.circle"), for: .normal)
            sectionDeleteButton.backgroundColor = .systemGray5
            sectionDeleteButton.tintColor = .black
            sectionDeleteButton.tag = section
            sectionDeleteButton.addTarget(self, action: #selector(deleteSection), for: .touchUpInside)
            sectionHeader.addSubview(sectionDeleteButton)
            // use auto layout
            sectionDeleteButton.translatesAutoresizingMaskIntoConstraints = false
            // add width / height constraints
            NSLayoutConstraint.activate([
                sectionDeleteButton.leadingAnchor.constraint(equalTo:  sectionButton.trailingAnchor, constant: 30),
                sectionDeleteButton.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor, constant: 0),
                sectionDeleteButton.topAnchor.constraint(equalTo: sectionHeader.topAnchor, constant: 0),
                sectionDeleteButton.heightAnchor.constraint(equalTo: sectionHeader.heightAnchor)
            ])
            
            
            let sectionEditButton = UIButton()
            sectionEditButton.setImage(UIImage(named: "pencil.circle"), for: .normal)
            
            sectionEditButton.backgroundColor = .systemGray5
            sectionEditButton.tintColor = .black
            sectionEditButton.tag = section
            sectionEditButton.addTarget(self, action: #selector(editSection), for: .touchUpInside)
            sectionHeader.addSubview(sectionEditButton)
            // use auto layout
            sectionEditButton.translatesAutoresizingMaskIntoConstraints = false
            // add width / height constraints
            NSLayoutConstraint.activate([
                sectionEditButton.leadingAnchor.constraint(equalTo:  sectionButton.trailingAnchor, constant: 0),
                sectionEditButton.trailingAnchor.constraint(equalTo: sectionDeleteButton.leadingAnchor, constant: 0),
                sectionEditButton.topAnchor.constraint(equalTo: sectionHeader.topAnchor, constant: 0),
                sectionEditButton.heightAnchor.constraint(equalTo: sectionHeader.heightAnchor)
            ])
            
            return sectionHeader
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 100{
            return models[section].count
        }else{
            if self.hiddenSections.contains(section) {
                return 0
            }
            return getElementInfoCount()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 100{
            let cell = tableView.dequeueReusableCell(withIdentifier: FormTableViewCell.identifier, for: indexPath) as! FormTableViewCell
            cell.configure(with: models[indexPath.section][indexPath.row])
            cell.delegate = self
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            if (manager?.allElements) != nil {
                cell.textLabel?.text = getElementInfo(section: indexPath.section, row: indexPath.row)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView.tag == 100{
            if section < 1{
                return "Name and ID"
            }
            return "Other Info."
        }
        return nil
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UILabel()
        footer.backgroundColor = .clear
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView.tag == 100{
            return nil
        }else{
            return createSectionHeader(section: section)
        }
    }

    
    
    
    @objc
    private func hideSection(sender: UIButton) {
        // Create section let
        // Add indexPathsForSection method
        // Logic to add/remove sections to/from hiddenSections, and delete and insert functionality for tableView
        let section = sender.tag
        guard let manager = manager else {
            return
        }
        
        _ = manager.count
        func indexPathsForSection(currSection: Int) -> [IndexPath] {
            var indexPaths = [IndexPath]()
            
            for row in 0..<getElementInfoCount() {
                indexPaths.append(IndexPath(row: row, section: currSection))
            }
            return indexPaths
        }
        
        if self.hiddenSections.contains(section) {
            self.hiddenSections.remove(section)
            self.listView.insertRows(at: indexPathsForSection(currSection: section),
                                         with: .fade)
            
        } else {
            self.hiddenSections.insert(section)
            self.listView.deleteRows(at: indexPathsForSection(currSection: section),
                                         with: .fade)
        }
        
        
    }
    
    @objc
    private func deleteSection(sender: UIButton){
        guard let element = manager?.getElement(at: sender.tag) else{
            return
        }
        let alert = UIAlertController(title: "Delete \(element.name)", message: "Do you want to delete the \(element.name)? The operation cannot be revoked. ", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {[weak self] _ in
            self?.manager?.delete(element: element){ error in
                if (error == nil){
                    AlertManager.sendAlert(title: "Success", message: "Successfully deleted \(element.name)", click: "OK", inView: self)
                    self?.listView.reloadData()
                }else{
                    AlertManager.sendAlert(title: "Failed", message: "This cannot be deleted.", click: "OK", inView: self)
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func editSection(sender: UIButton){
        guard let element = manager?.getElement(at: sender.tag) else{
            return
        }
        sectionValues = getElementInfo(element: element)
        configureModels()
    }
    

}



extension EditManagerViewController: FormTableViewCellDelegate{
    func formtableViewCell(_ cell: FormTableViewCell, didUpdateField updateModel: EditProfileFormModel) {
        self.didMakeChange = true

        if let indexPath = tableView.indexPath(for: cell){
            models[indexPath.section][indexPath.row].value = updateModel.value
        }
    }
}


extension EditManagerViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
