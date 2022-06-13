//
//  OptionManager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/4/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

protocol OptionsManager {
    var options: [String]  { get }
    var didShowOptions: Bool { get }
    func showOptions()
    func closeOptions()
    func resetOptions(options: [String])
}


/// this class manages the drop down menu
class HomeOptionsManager: NSObject, OptionsManager {
    
    
    /// Use private(set) to mark the setter private
    private(set) var options: [String]
    public var didShowOptions: Bool
    
    private let TABLE_CELL_HEIGHT: CGFloat =  44
    
    let mainView: UIViewController
    var topbarHeight: CGFloat
    let anchorPosition = ""
    var screenSize = UIScreen.main.bounds.size
    var x0 = CGFloat(0)
    
    private var tableViewHeight: CGFloat {
        if #available(iOS 11.0, *) {
            return TABLE_CELL_HEIGHT * CGFloat(options.count) + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)/// Taking into account the bottom safe area for full-screen iphones
        } else {
            // Fallback on earlier versions
            return TABLE_CELL_HEIGHT * CGFloat(options.count)
        }

    }
    
    /// Views
    private var backgroundView: UIView?
    private var optionsView: UITableView?
    
    /// Action handler
    public var optionsDidOpen: (() -> ())?
    public var optionsDidDismiss: (() -> ())?
    public var didSelectOption: ((String) -> ())?
    
    init(options: [String] = [], mainView: UIViewController, anchorPosition: String = "") {
        self.options = options
        self.mainView = mainView
        self.topbarHeight = mainView.topbarHeight
        if anchorPosition == "right"{
            self.x0 = self.screenSize.width * 2 / 3
        }
        self.didShowOptions = false
    }
    
    public func resetOptions(options: [String]=[]){
        self.options = options
        optionsView?.reloadData()
    }
    
    
    @objc func didTapBackground(){
        self.didShowOptions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            //optionsTableView.bottomConstraint?.constant = 0
            
            self.screenSize = UIScreen.main.bounds.size
            
            if self.anchorPosition == "right"{
                self.x0 = self.screenSize.width -  self.screenSize.width / 3
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
                
                /// Introduces half alpha and forces a layout pass
                self.backgroundView?.alpha = 0
                self.optionsView?.frame = CGRect(x: self.x0,
                                                 y:  self.topbarHeight,
                                                 width:  self.screenSize.width / 3,
                                                 height:0)
                
            }) { (complete) in
                self.backgroundView?.removeFromSuperview()
                self.optionsView?.removeFromSuperview()
                self.backgroundView = nil
                
                self.optionsDidDismiss?()
            }
        }
        
    }
    
    public func closeOptions(){
        if self.didShowOptions{
            self.didTapBackground()
        }
    }
    
    /// Configures options view and add to screen
    public func showOptions() {
        guard backgroundView == nil else { return }
        guard let window = UIApplication.shared.windows.first else { return }
        topbarHeight = mainView.topbarHeight
        
        self.screenSize = UIScreen.main.bounds.size
        /// The background view that covers the entire screen
        //let backgroundView = UIView(frame: window.bounds)
        let backgroundView = UIView(frame: CGRect(x: 0, y:  self.mainView.topbarHeight, width:  self.screenSize.width, height: self.screenSize.height - self.mainView.topbarHeight))
        backgroundView.backgroundColor = .black
        backgroundView.alpha = 0
        
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        backgroundView.isUserInteractionEnabled = true
        /// Ensures the tap is passed on to its subviews
        backgroundTapGesture.cancelsTouchesInView = false
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        self.backgroundView = backgroundView
        
        if self.optionsView == nil{
        /// The actual clickable options table view
            let optionsTableView = UITableView(frame: .zero, style: .plain)
            optionsTableView.isScrollEnabled = false
            optionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            optionsTableView.delegate = self
            optionsTableView.dataSource = self
            
            if self.anchorPosition == "right"{
                self.x0 = self.screenSize.width -  self.screenSize.width / 3
            }
            optionsTableView.frame = CGRect(x: self.x0, y:  self.mainView.topbarHeight, width:  self.screenSize.width / 3, height: self.tableViewHeight)
            optionsTableView.backgroundColor = .white
            optionsTableView.alpha = 1
            self.optionsView = optionsTableView
            
        }
        window.addSubview(self.backgroundView!)
        window.addSubview(self.optionsView!)
        self.didShowOptions = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            //optionsTableView.bottomConstraint?.constant = 0
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, animations: {
                
                /// Introduces half alpha and forces a layout pass
                backgroundView.alpha = 0.5
                backgroundView.layoutIfNeeded()
                //self.optionsView?.frame = CGRect(x: 0, y: backgroundView.frame.height - self.tableViewHeight, width: backgroundView.frame.width, height: self.tableViewHeight)
                self.optionsView?.frame = CGRect(x: self.x0, y: self.mainView.topbarHeight, width:  self.screenSize.width / 3, height: self.tableViewHeight)
                
            }) { (complete) in
                
                self.optionsDidOpen?()
                
            }
        }
    }

}

extension HomeOptionsManager: UITableViewDataSource, UITableViewDelegate {

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options[section].count

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.row < options.count{
            cell.textLabel?.text = options[indexPath.row]
            cell.textLabel?.textAlignment = .center
            if #available(iOS 13.0, *) {
                cell.textLabel?.textColor = .link
            } else {
                // Fallback on earlier versions
                cell.textLabel?.textColor = .blue
            }
            if options[indexPath.row].contains("*"){
                if #available(iOS 13.0, *) {
                    cell.textLabel?.textColor = .systemIndigo
                } else {
                    // Fallback on earlier versions
                    cell.textLabel?.textColor = .purple
                }
            }
        }
        return cell
        
    }
    
    
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return TABLE_CELL_HEIGHT
//    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectOption?(options[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

