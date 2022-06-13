//
//  MemberInfoViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/20/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class MemberInfoViewController: UIViewController {
    private let popUpWindowView: PopUpWindowView
    private let inView: UIViewController?
    
    init(key:[String], value:[String], title: String, inView: UIViewController?=nil){
        
        self.inView = inView
        popUpWindowView = PopUpWindowView(key: key, value: value)
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
        
        popUpWindowView.popupTitle.text = title
        popUpWindowView.popupButton.setTitle("Dismiss", for: .normal)
        popUpWindowView.popupButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        view = popUpWindowView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    @objc func dismissView(){
        self.dismiss(animated: true){[weak self] in
            if let inView = self?.inView {
                if #available(iOS 13.0, *) {
                    inView.isModalInPresentation = false
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
}



private class PopUpWindowView: UIView {
    
    let popupView = UIView(frame: CGRect.zero)
    let popupTitle = UILabel(frame: CGRect.zero)
    let popupButton = UIButton(frame: CGRect.zero)
    
    let BorderWidth: CGFloat = 0.0
    
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    
    var key: [String]
    var value: [String]
    var textHeight  = CGFloat(30)
    
    init(key: [String], value:[String]) {
        self.key  = key
        self.value = value
        super.init(frame: CGRect.zero)

        // Semi-transparent background
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        
        // table view
        
        let nib = UINib(nibName: PopupInfoTableViewCell.identifier, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: PopupInfoTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        if value.count > 0{
            textHeight = max(textHeight, value[value.count - 1].height(constraintedWidth: 220, font: .systemFont(ofSize: 17)))
            //print(textHeight)
        }
        
        // Popup Background
        if #available(iOS 13.0, *) {
            popupView.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            popupView.backgroundColor = .white
        }
        popupView.layer.borderWidth = BorderWidth
        popupView.layer.masksToBounds = true
        popupView.layer.cornerRadius = 25
        //popupView.layer.borderColor = UIColor.white.cgColor
        
        // Popup Title
        popupTitle.textColor = MyColor.first_text_color
        popupTitle.backgroundColor = MyColor.first_color
        popupTitle.layer.masksToBounds = true
        popupTitle.adjustsFontSizeToFitWidth = true
        popupTitle.clipsToBounds = true
        popupTitle.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        popupTitle.numberOfLines = 1
        popupTitle.textAlignment = .center
        
        
        // Popup Button
        popupButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .bold)
        popupButton.setTitleColor(MyColor.first_color, for: .normal)
        if #available(iOS 13.0, *) {
            popupButton.backgroundColor = .systemGray6
        } else {
            // Fallback on earlier versions
        }
        popupButton.layer.cornerRadius = 10
        
        popupView.addSubview(popupTitle)
        popupView.addSubview(tableView)
        popupView.addSubview(popupButton)

        addSubview(popupView)
        
        

        let tableViewHeight = CGFloat(min( 30 * key.count, 360))
        // PopupView constraints
        popupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popupView.widthAnchor.constraint(equalToConstant: 350),
            popupView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            popupView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
        
        // PopupTitle constraints
        popupTitle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popupTitle.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: BorderWidth),
            popupTitle.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -BorderWidth),
            popupTitle.topAnchor.constraint(equalTo: popupView.topAnchor, constant: BorderWidth),
            popupTitle.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        
        
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.heightAnchor.constraint(equalToConstant: tableViewHeight + 10),
            tableView.topAnchor.constraint(equalTo: popupTitle.bottomAnchor, constant: 5),
            tableView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: -5),
            tableView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -5),
            tableView.bottomAnchor.constraint(equalTo: popupButton.topAnchor, constant: 5)
        ])
        
        // PopupButton constraints
        popupButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popupButton.heightAnchor.constraint(equalToConstant: 40),
            popupButton.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 90),
            popupButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -90),
            popupButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -10)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
//    private func createFooter(notes: String) -> UIView{
//        let footer = UIView()
//
//        let labelText = "notes: \n  " + notes
//        footer.frame = CGRect(x: 0, y: 5, width: 340,
//                              height: max(textHeight, labelText.height(constraintedWidth: 330, font: .systemFont(ofSize: 17))))
//        let label = UILabel()
//        label.frame = footer.frame
//        label.clipsToBounds = true
//        label.text = labelText
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        label.font = .systemFont(ofSize: 17)
//        label.sizeToFit()
//        label.lineBreakMode = .byWordWrapping
//        footer.addSubview(label)
//        return footer
//    }
    
}




extension PopUpWindowView: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PopupInfoTableViewCell.identifier, for: indexPath) as! PopupInfoTableViewCell
        cell.config(key: key[indexPath.row], value: value[indexPath.row])
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return key.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == key.count-1{
            return textHeight
        }
        return 30
    }
    
}
