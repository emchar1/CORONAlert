//
//  LocationAnnotation.swift
//  CORONAlert
//
//  Created by Eddie Char on 8/22/20.
//  Copyright © 2020 Eddie Char. All rights reserved.
//

import Foundation
import MapKit

class LocationAnnotation: NSObject, MKAnnotation {
    //MKAnnotation required protocol properties
    let coordinate: CLLocationCoordinate2D
    var title: String? {
        return locationName
    }
    
    //Location properties
    let countryName: String
    let provinceName: String
    let cityName: String?
    let riskLevel: (level: String, color: UIColor)
    let todaysCases: String
    let todaysDeaths: String
    let totalCases: String
    let totalDeaths: String
    let dateToday: String
    
    var locationName: String {
        var name = ""
        if let cityName = cityName {
            name += cityName + ", "
        }
        if provinceName != "" {
            name += provinceName + ", "
        }
        name += countryName
        return name
    }
    var locationNameReversed: String {
        var name = countryName
        if provinceName != "" {
            name += ", " + provinceName
        }
        if let cityName = cityName {
            name += ", " + cityName
        }
        return name
    }

    
    init(countryName: String, provinceName: String, cityName: String?, riskLevel: (String, UIColor), todaysCases: String, todaysDeaths: String, totalCases: String, totalDeaths: String, dateToday: String, coordinate: CLLocationCoordinate2D) {
        self.countryName = countryName
        self.provinceName = provinceName
        self.cityName = cityName
        self.riskLevel = riskLevel
        self.todaysCases = todaysCases
        self.todaysDeaths = todaysDeaths
        self.totalCases = totalCases
        self.totalDeaths = totalDeaths
        self.dateToday = dateToday
        self.coordinate = coordinate

        super.init()
    }
}
