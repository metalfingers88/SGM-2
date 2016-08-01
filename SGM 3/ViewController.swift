//
//  ViewController.swift
//  SGM 3
//
//  Created by Charlie Vogel on 8/1/16.
//  Copyright © 2016 salido. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import AlamofireObjectMapper
import ObjectMapper
import Charts

/*public protocol Mappable {
 init?(_ map: Map)
 mutating func mapping(map: Map)
 } */

class OrderType: Mappable
{
    var type: String
    var netSalesSum: Float
    var id: String
    
    required init?(_ map: Map)
    {
        type = ""
        netSalesSum = 0
        id = ""
    }
    
    func mapping(map: Map)
    {
        type <- map["type"]
        id <- map["metadata.id"]
        netSalesSum <- (map["totals.net_sales.sum"], TransformOf<Float, String>(fromJSON: { Float($0!) }, toJSON: { $0.map { String($0) } }))
    }
}

class ViewController: UIViewController, ChartViewDelegate
{
    var comps = UILabel(frame: CGRectMake(0, 0, 200, 20))
    var voids = UILabel(frame: CGRectMake(0, 0, 200, 20))
    var checks = UILabel(frame: CGRectMake(0, 0, 200, 20))
    var covers = UILabel(frame: CGRectMake(0, 0, 200, 20))
    var netSales = UILabel(frame: CGRectMake(0, 0, 200, 20))
    func getSetData(date: String)
    {
        self.typeData = []
        self.totalRev = 0.0
        let baseUrl : String = "https://ss-reporting-stg.herokuapp.com/v1"
        let endpoint : String = "/checks/"
        
        let chartQuery : JSON = [
            "filters": [
                "location_id": ["5668c1854da481000a000025"],
                "closed_on_business_day" : [date]
            ],
            "aggregates": [
                "fields": [
                    "net_sales": ["sum"]
                ],
                "groups": ["order_type","revenue_category"]
            ]
        ]
        
        let labelQuery : JSON = [
        "filters": [
            "location_id": ["5668c1854da481000a000025"],
            "closed_on_business_day" : [date]
        ],
        "aggregates": [
            "fields": [
            "net_sales": ["sum","count"],
            "covers": ["count"],
            "discounts": ["sum"],
            "voids": ["sum"]
                        ]
//        "groups": ["order_type","revenue_category"]
        ]
        ]
        
        let urlString = baseUrl + endpoint
        let params : [String:AnyObject] = ["json": chartQuery.rawString(1, options: NSJSONWritingOptions.init(rawValue: 0))!]
        Alamofire.request(.GET, urlString, parameters: params, encoding: .URL).validate().responseJSON { response in
            print("lalala")
            switch response.result
            {
            case .Success:
                if let value : JSON = JSON(response.result.value!)
                {
                    let holder = String(value["aggregates"]["totals"]["net_sales"]["sum"])
                    self.totalRev = Double(holder)!
                    for (revenueType, data) in value["aggregates"]["groups"]["revenue_category"]
                    {
                        var data = data
                        data["type"] = JSON(revenueType)
                        
                        self.typeData.append(Mapper<OrderType>().map(data.rawString())!)
                        
                    }
                    self.setChart(self.typeData, chart: self.pieChartView)
                }
                
            case .Failure(let error):
                print(error)
            }
            
        }
        
        let params2 : [String:AnyObject] = ["json": labelQuery.rawString(1, options: NSJSONWritingOptions.init(rawValue: 0))!]
        Alamofire.request(.GET, urlString, parameters: params2, encoding: .URL).validate().responseJSON { response in
            print("lalala")
            switch response.result
            {
            case .Success:
                if let value2 : JSON = JSON(response.result.value!)
                {
                    print(value2)
                    
                    self.netSales.center = CGPointMake(100, 99)
                    self.netSales.textAlignment = NSTextAlignment.Center
                    self.netSales.text = "$" + String(value2["aggregates"]["net_sales"]["sum"])
                    self.netSales.textColor = UIColor.whiteColor()
                    
                    self.checks.center = CGPointMake(100, 179)
                    self.checks.textAlignment = NSTextAlignment.Center
                    self.checks.text = String(value2["aggregates"]["net_sales"]["count"])
                    self.checks.textColor = UIColor.whiteColor()
                    
                    self.covers.center = CGPointMake(300, 179)
                    self.covers.textAlignment = NSTextAlignment.Center
                    self.covers.text = String(value2["aggregates"]["covers"]["count"])
                    self.covers.textColor = UIColor.whiteColor()

                    
                    self.comps.center = CGPointMake(100, 279)
                    self.comps.textAlignment = NSTextAlignment.Center
                    self.comps.text = "$" + String(value2["aggregates"]["discounts"]["sum"])
                    self.comps.textColor = UIColor.whiteColor()
                    
                    self.voids.center = CGPointMake(300, 279)
                    self.voids.textAlignment = NSTextAlignment.Center
                    self.voids.text = "$" + String(value2["aggregates"]["voids"]["sum"])
                    self.voids.textColor = UIColor.whiteColor()
                    
                    
                }
                
            case .Failure(let error):
                print(error)
            }
            
        }
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func setChart(data: [OrderType], chart: PieChartView)
    {
        
        var dataEntries: [ChartDataEntry] = []
        var labels: [String] = []
        var x = 0
        var misc = 0.0
        for item in data
        {
            if Double(item.netSalesSum) < totalRev/25
                //this conditional should be a percentage not a fixed value
            {
                misc = misc + Double(item.netSalesSum)
            }
            else
            {
                let dataEntry = ChartDataEntry(value: Double(item.netSalesSum), xIndex: x)
                labels.append(item.type)
                dataEntries.append(dataEntry)
            }
            x = x + 1
        }
        labels.append("Other")
        dataEntries.append(ChartDataEntry(value: misc, xIndex: x))
        let pieChartDataSet = PieChartDataSet(yVals: dataEntries, label: "Sales ($)")
        
        var colors: [UIColor] = []
        
        for i in 1...dataEntries.count
        {
            var color: UIColor
            if i == 1
            {
                color = UIColor.magentaColor()
            }
            else if i == 2
            {
                color = UIColor.blueColor()
            }
            else if i == 3
            {
                color = UIColor.redColor()
            }
            else if i == 4
            {
                color = UIColor.orangeColor()
            }
            else if i == 5
            {
                color = UIColor.purpleColor()
            }
            else {
                let red = Double(arc4random_uniform(256))
                let green = Double(arc4random_uniform(256))
                let blue = Double(arc4random_uniform(256))
                color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
                colors.append(color)
            }
            colors.append(color)
        }
        
        pieChartDataSet.colors = colors
        let pieChartData = PieChartData(xVals: labels, dataSet: pieChartDataSet)
        //pieChartData.setDrawValues(false)
        chart.drawSliceTextEnabled = false
        chart.data = pieChartData
        self.pieChartView.animate(xAxisDuration: 1.5)
        chart.notifyDataSetChanged()
        
    }
    
    var date = ""
    var strDate = ""
    var notChanged = true
    
    @IBOutlet var pieChartView: PieChartView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBAction func datePick(sender:UIDatePicker) {
        notChanged = false
        strDate = String(self.datePicker.date)
        date = strDate.substringToIndex(date.startIndex.advancedBy(10))
        print(strDate)
        delay(0.05){
            self.getSetData(self.date)
            self.pieChartView.setNeedsDisplay()
        }
    }
    
    
    var totalRev = 0.0
    var typeData : [OrderType] = []
    override func viewDidLoad()
    {
        view.backgroundColor = UIColor.darkGrayColor()
        
        var compsLabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
        var voidsLabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
        var checksLabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
        var coversLabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
        var netSalesLabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
        
        netSalesLabel.center = CGPointMake(100, 120)
        netSalesLabel.textAlignment = NSTextAlignment.Center
        netSalesLabel.text = "Net Sales"
        netSalesLabel.textColor = UIColor.lightGrayColor()
        
        checksLabel.center = CGPointMake(100, 200)
        checksLabel.textAlignment = NSTextAlignment.Center
        checksLabel.text = "Checks"
        checksLabel.textColor = UIColor.lightGrayColor()
        
        coversLabel.center = CGPointMake(300, 200)
        coversLabel.textAlignment = NSTextAlignment.Center
        coversLabel.text = "Covers"
        coversLabel.textColor = UIColor.lightGrayColor()
        
        compsLabel.center = CGPointMake(100, 300)
        compsLabel.textAlignment = NSTextAlignment.Center
        compsLabel.text = "Comps"
        compsLabel.textColor = UIColor.redColor()
        
        voidsLabel.center = CGPointMake(300, 300)
        voidsLabel.textAlignment = NSTextAlignment.Center
        voidsLabel.text = "Voids"
        voidsLabel.textColor = UIColor.redColor()
        
        self.view.addSubview(compsLabel)
        self.view.addSubview(voidsLabel)
        self.view.addSubview(checksLabel)
        self.view.addSubview(coversLabel)
        self.view.addSubview(netSalesLabel)
        self.view.addSubview(comps)
        self.view.addSubview(voids)
        self.view.addSubview(checks)
        self.view.addSubview(covers)
        self.view.addSubview(netSales)

        if notChanged {
            date = String(datePicker.date)
            date = date.substringToIndex(date.startIndex.advancedBy(10))
        }
        getSetData(date)
        //        let date : String = "2016-05-01"
        
        //        self.datePicker.addTarget(self, action: Selector("ViewController.datePickerChanged:"), forControlEvents: UIControlEvents.ValueChanged)
        super.viewDidLoad()
        var l: ChartLegend = self.pieChartView.legend
        l.textColor = UIColor.whiteColor()
        l.form = ChartLegend.Form.Circle
        l.formSize = 15.0
        l.position = ChartLegend.Position.LeftOfChartCenter
        l.orientation = ChartLegend.Orientation.Vertical
        l.yEntrySpace = 15
        l.textHeightMax = 25
        l.textWidthMax = 25
        
        self.pieChartView.holeColor = UIColor.darkGrayColor()
        self.pieChartView.delegate = self
        self.pieChartView.animate(xAxisDuration: 3)
        self.pieChartView.descriptionText = "Jue Lan"
        self.pieChartView.descriptionTextColor = UIColor.whiteColor()
        self.pieChartView.backgroundColor = UIColor.darkGrayColor()
        self.pieChartView.noDataText = "Loading..."
        
        
        
        
        //        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        //        let unitsSold = [20.0, 4.0, 6.0, 3.0, 12.0, 16.0, 4.0, 18.0, 2.0, 4.0, 5.0, 4.0]
        //        func setChart(dataPoints: [String], values: [Double]) {
        //
        //            var dataEntries: [ChartDataEntry] = []
        //
        //            for i in 0..<dataPoints.count {
        //                let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
        //                dataEntries.append(dataEntry)
        //            }
        //
        //            let pieChartDataSet = PieChartDataSet(yVals: dataEntries, label: "Units Sold")
        //            let pieChartData = PieChartData(xVals: dataPoints, dataSet: pieChartDataSet)
        //            pieChartView.data = pieChartData
        //        }
        //            setChart(months, values: unitsSold)
        //        setChart(self.typeData)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

/*
 misc code I want to have but am not using rn
 
 */