//
//  Manager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 5/6/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

protocol Element{
    var name: String { get }
    var id: String { get }
    func toString() -> String
}

class Manager{
    var key = "element"
    var allElements = [Element]()
    var count = 0

    
    public enum ManagerError: Error{
        case saveError
        case loadError
        case saveAndLoadError
        case elementExists
        case elementNotFound
    }
    
    public func config(){
        if isKeyPresentInUserDefaults(key: key){
            load()
        }
    }
    
    public func getElement(at: Int) -> Element?{
        guard at >= 0, at < count else{
            return nil
        }
        return allElements[at]
    }
    
    public func update(element: Element, completion: ((Error?) -> Void)? = nil){
        if let index = findIndex(element: element){
            allElements[index] = element
            completion?(nil)
        }else{
            completion?(ManagerError.elementNotFound)
        }
        return
    }
    
    private func findIndex(element: Element) -> Int?{
        for i in 0..<allElements.count{
            if allElements[i].id == element.id{
                return i
            }
        }
        return nil
    }
    
    public func find(id: String) -> Element?{
        for element in allElements {
            if element.id == id{
                return element
            }
        }
        return nil
    }
    
    public func delete(element: Element, completion: ((Error?) -> Void)? = nil){
        if let index = findIndex(element: element){
            allElements.remove(at: index)
            saveAndLoad(){success in
                if(!success){
                    completion?( ManagerError.saveAndLoadError)
                }else{
                    self.count -= 1
                    completion?(nil)
                }
            }
        }else{
            completion?(ManagerError.elementNotFound)
        }
        return
    }
    
    
    public func add(newElement: Element, completion: ((Error?) -> Void)? = nil){
        for element in allElements{
            if element.id == newElement.id{
                completion?(ManagerError.elementExists)
                return
            }
        }
        
        allElements.append(newElement)
        saveAndLoad(){success in
            if(success){
                self.count += 1
                completion?(nil)
            }else{
                completion?(ManagerError.saveAndLoadError)
            }
        }
        return
    }
    
    public func saveAndLoad(completion: ((Bool)->Void)? = nil){
        save(){ [weak self] successSave in
            self?.load(){ successLoad in
                completion?(successSave && successLoad)
            }
        }
    }
    
    public func load(completion: ((Bool)->Void)? = nil){
        guard isKeyPresentInUserDefaults(key: key), let decoded = UserDefaults.standard.data(forKey: key) else {
            completion?(false)
            return
        }
        
        do{
            allElements = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as! [Element]
            completion?(true)
        }catch{
            completion?(false)
            LogManager.writeLog(info: "load crewlist error \(error)")
        }
        
        count = allElements.count
        return
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    
    public func save(completion: ((Bool) -> Void)? = nil){
        do{
            let encodedData = try NSKeyedArchiver.archivedData(withRootObject: allElements, requiringSecureCoding: false)
            UserDefaults.standard.set(encodedData, forKey: key)
            UserDefaults.standard.synchronize()
            completion?(true)
        }catch{
            LogManager.writeLog(info: "save member error. \(error)")
            completion?(false)
        }
    }
    
    
    
}

