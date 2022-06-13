//
//  ChartViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/24/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit
import Charts

class ChartViewController: UIViewController {
    private let popUpChartView: PopUpBarChartView
    
    init(frame: CGRect, dataX: [[Double]], dataY:[[Double]], labels: [String]){
        popUpChartView = PopUpBarChartView(frame: frame, dataX: dataX, dataY: dataY, labels: labels)
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
        
        popUpChartView.popupTitle.text = "Chart View"
        
        popUpChartView.popupButton.setTitle("OK", for: .normal)
        popUpChartView.popupButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        view = popUpChartView
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
           self.dismiss(animated: true, completion: nil)
       }
}


private class PopUpBarChartView: UIView, ChartViewDelegate{
    
    let popupView = UIView(frame: CGRect.zero)
    let popupTitle = UILabel(frame: CGRect.zero)
    let popupButton = UIButton(frame: CGRect.zero)
    
    let BorderWidth: CGFloat = 0.0
    
    let popupLabel = UILabel(frame: CGRect.zero)
    
    let colorList: [UIColor] = [.green, .orange, .red, .link, .systemGray5, .purple, .systemIndigo]
    private let chartView = BarChartView()
    
    var dataX = [[Double]]()
    var dataY = [[Double]]()
    var labels = [String]()
    
    
    init(frame: CGRect, dataX: [[Double]], dataY:[[Double]], labels: [String]) {
        self.dataX = dataX
        self.dataY = dataY
        self.labels = labels
        super.init(frame: frame)

        // Semi-transparent background
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        // Popup Background
        popupView.backgroundColor = .systemBackground
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
        popupButton.backgroundColor = .systemGray6
        popupButton.layer.cornerRadius = 10
        
        
        // Popup Label
        popupLabel.text = "No Data!"
        popupLabel.textAlignment = .center
        popupLabel.backgroundColor = .systemGray6
        
        
        chartView.delegate = self
        configureChartView()
        
        popupView.addSubview(popupTitle)
        popupView.addSubview(popupLabel)
        popupView.addSubview(popupButton)
        
        let viewWidth = frame.size.width / 2
        let viewHeight = frame.size.height / 2
        let leftEdge = frame.size.width / 4
        let topEdge =  frame.size.height / 4
        // PopupView constraints
        
        popupView.frame = CGRect(x: leftEdge,
                                 y: topEdge,
                                 width: viewWidth,
                                 height: viewHeight)
        
        
        
        // PopupTitle constraints
        popupTitle.frame = CGRect(x: 0, y: 0, width: popupView.width, height: 50)

        // popupLabel
        popupLabel.frame = CGRect(x: 0, y: popupTitle.bottom + 5, width: popupView.width, height: viewHeight - 110)
        
        //chart view
        if dataX.count == dataY.count, dataX.count == labels.count, !dataX.isEmpty{
            popupLabel.isHidden = true
            chartView.isHidden = false 
            chartView.frame = CGRect(x: 0, y: popupTitle.bottom + 5, width: popupView.width, height: viewHeight - 110)
            popupView.addSubview(chartView)
        }else{
            chartView.isHidden = true
            popupLabel.isHidden = false
        }
        // PopupButton constraints
        popupButton.frame = CGRect(x: popupView.width / 4, y: popupLabel.bottom + 5, width: popupView.width / 2, height: 50)
        addSubview(popupView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureChartView(){
        var chartDataSets = [BarChartDataSet]()
        for i in 0..<labels.count{
            var dataEntries = [BarChartDataEntry]()
            for j in 0..<dataX[i].count{
                let entry = BarChartDataEntry(x:  dataX[i][j], y: dataY[i][j])
                //print("load data: \(dataX[i][j]), \(dataY[i][j])")
                dataEntries.append(entry)
            }
            let barchartDataset = BarChartDataSet(entries: dataEntries, label: labels[i])
            barchartDataset.setColor(colorList[i])
            chartDataSets.append(barchartDataset)
        }
        
        let chartData = BarChartData(dataSets: chartDataSets)
        chartView.data = chartData
        
        let months = ["Morning", "", "Noon",  "", "Afternoon", "", "Evening", "", "Other"]
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:months)
        chartView.xAxis.granularity = 2
        
        let formatter: CustomIntFormatter = CustomIntFormatter()
        chartView.data?.setValueFormatter(formatter)
        
        chartView.leftAxis.axisMinimum = 0
        chartView.rightAxis.axisMinimum = 0
    }
    
}

class CustomIntFormatter: NSObject, ValueFormatter{
    public func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        let correctValue = Int(value)
        return String(correctValue)
    }
}

