//
//  AlertModel.swift
//  CORONAlert
//
//  Created by Eddie Char on 8/19/20.
//  Copyright © 2020 Eddie Char. All rights reserved.
//

import UIKit

struct AlertModel {
    let dateString: String
    
    let countryCases: Cases
    let cfr: Double
    let iso: String
    let countryName: String
    
    let province: String
    let provinceCoordinates: Coordinates
    
    let cityName: String?
    let cityCoordinates: Coordinates?
    let cityCases: Cases?
   
    
    var date: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = K.dateFormat
        return dateFormatter.date(from: dateString)!
    }
    
    var dateStringFormatted: String {
        DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .none)
    }
    
    var locationName: String {
        var name = ""
        if let cityName = cityName {
            name += cityName + ", "
        }
        if province != "" {
            name += province + ", "
        }
        name += countryName
        return name
    }
    
    var coordinates: Coordinates {
        if let cityCoordinates = cityCoordinates {
            return cityCoordinates
        }
        else {
            return provinceCoordinates
        }
    }
    
    var cases: Cases {
        if let cityCases = cityCases {
            return cityCases
        }
        else {
            return countryCases
        }
    }
    
    var riskRate: Double {
        var risk = cases.totalCases == 0 ? 0 : Double(cases.newCases) / Double(cases.totalCases)
        if risk < 0 {
            risk = 0
        }
        return risk
    }
    
    var riskLevel: (String, UIColor) {
        var riskString: String
        var riskColor: UIColor
        
        //Need to update cases...
        switch riskRate * 100 {
        case 0..<0.10:
            riskString = "Safe"
            riskColor = UIColor(named: "safe") ?? UIColor.lightGray
        case 0.10..<0.15:
            riskString = "Low"
            riskColor = UIColor(named: "low1") ?? UIColor.lightGray
        case 0.15..<0.31:
            riskString = "Low"
            riskColor = UIColor(named: "low2") ?? UIColor.lightGray
        case 0.31..<0.70:
            riskString = "Low"
            riskColor = UIColor(named: "low3") ?? UIColor.lightGray
        case 0.70..<1.82:
            riskString = "Medium"
            riskColor = UIColor(named: "medium1") ?? UIColor.lightGray
        case 1.82..<2.89:
            riskString = "Medium"
            riskColor = UIColor(named: "medium2") ?? UIColor.lightGray
        case 2.89..<4.39:
            riskString = "Medium"
            riskColor = UIColor(named: "medium3") ?? UIColor.lightGray
        case 4.39..<10.00:
            riskString = "High"
            riskColor = UIColor(named: "high1") ?? UIColor.lightGray
        case 10.00..<23.14:
            riskString = "High"
            riskColor = UIColor(named: "high2") ?? UIColor.lightGray
        case 23.14..<35.32:
            riskString = "High"
            riskColor = UIColor(named: "high3") ?? UIColor.lightGray
        case _ where riskRate >= 35.32:
            riskString = "Critical"
            riskColor = UIColor(named: "critical") ?? UIColor.lightGray
        default:
            riskString = "Error"
            riskColor = .lightGray
        }

        return (riskString, riskColor)
    }


}

struct Cases {
    let totalCases: Int
    let totalDeaths: Int
    let newCases: Int
    let newDeaths: Int
    
    var totalCasesString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: totalCases))!
    }
    var totalDeathsString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: totalDeaths))!
    }
    var newCasesString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: newCases))!
    }
    var newDeathsString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: newDeaths))!
    }

}

struct Coordinates {
    let latitudeString: String?
    let longitudeString: String?

    var latitude: Double? {
        Double(latitudeString ?? "null")
    }
    var longitude: Double? {
        Double(longitudeString ?? "null")
    }
}
