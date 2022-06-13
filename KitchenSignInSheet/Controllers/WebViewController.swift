//
//  WebViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/28/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

import PDFKit

class WebViewController: UIViewController{

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let fileURL = Bundle.main.url(forResource: "AMO-signIn-instruction", withExtension: "pdf") else{
            LogManager.writeLog(info: "did not find the path")
            return
        }
        
        
        
        if #available(iOS 11.0, *) {
            let pdfView = PDFView(frame: self.view.bounds)
            
            pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(pdfView)
            
            // Fit content in PDFView.
            pdfView.autoScales = true
            pdfView.document = PDFDocument(url: fileURL)
        }
    }
    

}
