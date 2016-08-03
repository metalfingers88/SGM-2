//
//  ViewController.swift
//  SGM 3
//  Salido God Mode - 3
//  Created by Charlie Vogel on 8/1/16.
//  Available at https://github.com/metalfingers88
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
    var salesDiff = UILabel(frame: CGRectMake(0, 0, 200, 20))
    var diffLabel = UILabel(frame: CGRectMake(0, 0, 200, 20))
    
    var today = false
    //today is a boolean that determines whether or not the selected day is the current business day
    var day = 0
    var diff = 0.0
    var toDateSum = 0.0
    var wkAgoSum = 0.0
    func getSetData(date: NSDate)
    {
        /*The below block of code figures out if it's today or not. However, might be bugged since datepicker.date is an exact date
         and time and so is NSDate(), so while they might match up to be the same day, today will be false unless they're the same
         down to the millisecond
         */
        if datePicker.date == NSDate()
        {
            today = true
        }
        
        var wkRespond = false
        var tdRespond = false
        diff = 0.0
        toDateSum = 0.0
        wkAgoSum = 0.0
//        print(self.datePicker.date)
        var strDate = String(date)
        var wkAgo = date.dateByAddingTimeInterval(-7*60*60*24)
        wkAgoDate = String(wkAgo)
        wkAgoDate = wkAgoDate.substringToIndex(wkAgoDate.startIndex.advancedBy(10))
        strDate = strDate.substringToIndex(strDate.startIndex.advancedBy(10))
        
        
        self.typeData = []
        self.totalRev = 0.0
        
        
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.Hour, fromDate: date)
        let dayComponents = calendar.components(.Weekday, fromDate: datePicker.date)
        day = dayComponents.weekday
        
        let baseUrl : String = "https://ss-reporting-stg.herokuapp.com/v1"
        let endpoint : String = "/checks/"
        
        let chartQuery : JSON = [
            "filters": [
                "location_id": ["5668c1854da481000a000025"],
                "closed_on_business_day" : [strDate]
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
            "closed_on_business_day" : [strDate]
        ],
        "aggregates": [
            "fields": [
            "net_sales": ["sum","count"],
            "covers": ["count"],
            "discounts": ["sum"],
            "voids": ["sum"]
                        ]
        ]
        ]
        
        let toDateQuery : JSON = [
            "filters": [
                "location_id": ["5668c1854da481000a000025"],
                "closed_on_business_day" : [strDate]
            ],
            "aggregates": [
                "fields": [
            "net_sales":["sum"]],
                "buckets":["field":"closed_at","interval":"hour","collapse_on":"day"]]]
        
        let comparisonQuery : JSON = [
            "filters": [
                "location_id": ["5668c1854da481000a000025"],
                "closed_on_business_day" : [wkAgoDate]
            ],
            "aggregates": [
                "fields": [
                    "net_sales":["sum"]],
                "buckets":["field":"closed_at","interval":"hour","collapse_on":"day"]]]

        
        let urlString = baseUrl + endpoint
        let params : [String:AnyObject] = ["json": chartQuery.rawString(1, options: NSJSONWritingOptions.init(rawValue: 0))!]
        Alamofire.request(.GET, urlString, parameters: params, encoding: .URL).validate().responseJSON { response in
//            print("lalala")
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
        let toDateParams : [String:AnyObject] = ["json": toDateQuery.rawString(1, options: NSJSONWritingOptions.init(rawValue: 0))!]
        Alamofire.request(.GET, urlString, parameters: toDateParams, encoding: .URL).validate().responseJSON { response in
            //            print("lalala")
            switch response.result
            {
            case .Success:
                if let value3 : JSON = JSON(response.result.value!)
                {
                    if self.today {
                    var cont = true
                    var i = 0
                    while cont {
                        let myDateFormatter = NSDateFormatter()
                        myDateFormatter.dateFormat = "E, dd MMM yyyy HH:mm:ss Z"
                        var stringDate = String(value3["aggregates"]["buckets"][i]["key"])
                        stringDate = String(stringDate.characters.dropLast())
                        stringDate = "Fri, 31 Dec 1999 " + stringDate + " +0000"
                        let toDate = myDateFormatter.dateFromString(stringDate)
                        let unitFlags: NSCalendarUnit = [.Hour, .Day, .Month, .Year]
                        let toDateComponents = NSCalendar.currentCalendar().components(unitFlags, fromDate: toDate!)
//                        print(value3["aggregates"]["buckets"][i]["values"]["net_sales"]["sum"])
                        if toDateComponents.hour == components.hour
                        {
                            cont = false
                        }
                        else {
                            var stringValue = String(value3["aggregates"]["buckets"][i]["values"]["net_sales"]["sum"])
//                            print("\(i). " + stringValue)
                            self.toDateSum = self.toDateSum + Double(stringValue)!
//                            print("tatata")
                             i += 1
                        }
                        }
                        }
                    else {
                        var stringValue = String(value3["aggregates"]["totals"]["net_sales"]["sum"])
                        self.toDateSum = Double(stringValue)!
                    }
                    tdRespond = true
                }
                
            case .Failure(let error):
                print(error)
            }
            
        }
        
        let wkAgoParams : [String:AnyObject] = ["json": comparisonQuery.rawString(1, options: NSJSONWritingOptions.init(rawValue: 0))!]
        Alamofire.request(.GET, urlString, parameters: wkAgoParams, encoding: .URL).validate().responseJSON { response in
            //            print("lalala")
            switch response.result
            {
            case .Success:
                if let value4 : JSON = JSON(response.result.value!)
                {
                    if self.today {
                    var cont = true
                    var i = 0
                    while cont {
                        let myDateFormatter = NSDateFormatter()
                        myDateFormatter.dateFormat = "E, dd MMM yyyy HH:mm:ss Z"
                        var stringDate = String(value4["aggregates"]["buckets"][i]["key"])
                        stringDate = String(stringDate.characters.dropLast())
                        stringDate = "Fri, 31 Dec 1999 " + stringDate + " +0000"
                        let toDate = myDateFormatter.dateFromString(stringDate)
                        let unitFlags: NSCalendarUnit = [.Hour, .Day, .Month, .Year]
                        let wkAgoComponents = NSCalendar.currentCalendar().components(unitFlags, fromDate: toDate!)
                        if wkAgoComponents.hour == components.hour
                        {
                            cont = false
                        }
                        else {
                            var stringValue = String(value4["aggregates"]["buckets"][i]["values"]["net_sales"]["sum"])
//                            print("\(i). " + stringValue)
                            self.wkAgoSum = self.wkAgoSum + Double(stringValue)!
//                          print("lalala")
                            i += 1
                            }
                        }
                }
                else {
                    var stringValue = String(value4["aggregates"]["totals"]["net_sales"]["sum"])
                    self.wkAgoSum = Double(stringValue)!
                }

                    wkRespond = true
                    }
            case .Failure(let error):
                print(error)
            }
            
        }

        
        
        let labelParams : [String:AnyObject] = ["json": labelQuery.rawString(1, options: NSJSONWritingOptions.init(rawValue: 0))!]
        Alamofire.request(.GET, urlString, parameters: labelParams, encoding: .URL).validate().responseJSON { response in
//            print("lalala")
            switch response.result
            {
            case .Success:
                if let value2 : JSON = JSON(response.result.value!)
                {
//                    print(value2)
                    
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
            
            self.diffLabel.center = CGPointMake(300, 120)
            self.diffLabel.textAlignment = NSTextAlignment.Center
            var diffTxt = "vs. Previous "
            if self.day == 1
            {
                diffTxt = diffTxt + "Sunday"
            }
            else if self.day == 2
            {
                diffTxt = diffTxt + "Monday"
            }
            else if self.day == 3
            {
                diffTxt = diffTxt + "Tuesday"
            }
            else if self.day == 4
            {
                diffTxt = diffTxt + "Wednesday"
            }
            else if self.day == 5
            {
                diffTxt = diffTxt + "Thursday"
            }
            else if self.day == 6
            {
                diffTxt = diffTxt + "Friday"
            }
            else
            {
                diffTxt = diffTxt + "Saturday"
            }
            
            self.diffLabel.text = diffTxt
            self.diffLabel.textColor = UIColor.lightGrayColor()
            
//          need to delay to ensure that toDateSum and wkAgoSum are set before finding diff
            self.delay(0.05){
            if tdRespond && wkRespond {
            print(self.toDateSum)
            print(self.wkAgoSum)
//            print(self.diff)
            self.diff = self.toDateSum - self.wkAgoSum
            print(self.diff)
            var absDiff = abs(self.diff)
            self.salesDiff.center = CGPointMake(300, 99)
            self.salesDiff.textAlignment = NSTextAlignment.Center
            self.delay(0.05){
            if self.wkAgoSum > self.toDateSum {
                self.salesDiff.text = "$ \(absDiff) ▼"
                self.salesDiff.textColor = UIColor.redColor()
            }
            else
            {
                self.salesDiff.text = "$ \(absDiff) ▲"
                self.salesDiff.textColor = UIColor.greenColor()
            }
            self.toDateSum = 0.0
            self.wkAgoSum = 0.0
            self.diff = 0.0
            }
            self.canRefresh = true
            }
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
    
    var date = NSDate()
    var wkAgoDate = ""
    var notChanged = true
    var anChart = true
    
    
    @IBOutlet var pieChartView: PieChartView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    
    var canRefresh = true
    @IBAction func buttonRefresh(sender: UIButton) {
        if canRefresh {
            anChart = false
            canRefresh = false
            self.getSetData(self.date)
            anChart = true
        }
        
    }
    
    @IBAction func datePick(sender:UIDatePicker) {
        notChanged = false
        
        date = self.datePicker.date
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
        self.view.addSubview(salesDiff)
        self.view.addSubview(diffLabel)
        if notChanged {
            date = datePicker.date
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
        if anChart {
            self.pieChartView.animate(xAxisDuration: 3)
        }
        else {
            self.pieChartView.animate(xAxisDuration: 0)
        }
        
        self.pieChartView.descriptionText = "Jue Lan"
        self.pieChartView.descriptionTextColor = UIColor.whiteColor()
        self.pieChartView.backgroundColor = UIColor.darkGrayColor()
        self.pieChartView.noDataText = "Loading..."
        }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

/*
 misc code I want to have but am not using rn
 
 */