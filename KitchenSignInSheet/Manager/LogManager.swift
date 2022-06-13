//
//  File.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/19/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import Foundation
import UIKit

final class LogManager{
    
    static func writeLog(info: String){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm: "
        var s = formatter.string(from: Date())
        s.append(info)
        s.append("\n")
        
        
        guard let data = s.data(using: String.Encoding.utf8) else{
            return
        }
        
        let fileManager = FileManager.default
        formatter.dateFormat = "MMddyyyy"
        let filename = "\(formatter.string(from: Date())).log"
        
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            fileHandle.closeFile()
                        }
            } else {
                try data.write(to: fileURL, options: .atomicWrite)
            }
            print(info)
            
        } catch {
            LogManager.writeLog(info:"save log failed: info = \(info); error=\(error)")
        }
        
    }
}
