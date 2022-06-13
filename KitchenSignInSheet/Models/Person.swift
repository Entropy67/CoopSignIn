//
//  Member.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 5/6/22.
//  Copyright © 2022 AMO. All rights reserved.
//


import UIKit

class Person: NSObject, NSCoding, Element{
    
    let id: String
    let name: String
    let deposit: Int
    
    func toString() -> String {
        return "name:\(name); deposit:\(id);"
    }
    
    init(name: String, deposit: Int){
        self.name = name
        self.deposit = deposit
        self.id = String(deposit)
    }
    

    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(deposit, forKey: "deposit")
    }
    
    required convenience init?(coder: NSCoder) {
        let nm = coder.decodeObject(forKey: "name") as! String
        let id = coder.decodeInteger(forKey: "deposit")
        self.init(name: nm, deposit:id)
    }
}
