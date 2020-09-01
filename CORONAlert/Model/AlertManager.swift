//
//  AlertManager.swift
//  CORONAlert
//
//  Created by Eddie Char on 8/19/20.
//  Copyright © 2020 Eddie Char. All rights reserved.
//

import Foundation
import CoreLocation

protocol AlertManagerDelegate {
    func alertManager(_ controller: AlertManager, didFetchAlerts alerts: [AlertModel], with annotations: [LocationAnnotation])
    func alertManager(_ controller: AlertManager, didFetchRegions regions: [RegionOnly])
    func alertManager(_ controller: AlertManager, didFailWithError error: Error)
}


struct AlertManager {
    private let headers = [K.rapidapiHost : K.rapidapiHostValue,
                   K.rapidapiKey : rapidAPIKey]
    var delegate: AlertManagerDelegate?

    
    // MARK: - fetchAlerts()
    
    func fetchAlerts(region_province: String? = nil, iso: String? = nil, region_name: String? = nil, city_name: String? = nil, date: String? = nil, q: String? = nil) {
        var urlString = "https://" + headers[K.rapidapiHost]! + "/reports?"
        
        if let region_province = region_province {
            urlString += "region_province=" + region_province + "&"
        }
        if let iso = iso {
            urlString += "iso=" + iso + "&"
        }
        if let region_name = region_name {
            urlString += "region_name=" + region_name + "&"
        }
        if let city_name = city_name {
            urlString += "city_name=" + city_name + "&"
        }
        if let date = date {
            urlString += "date=" + date + "&"
        }
        if let q = q {
            urlString += "q=" + q
        }
        
        performRequest(with: urlString)
    }
        
    private func performRequest(with urlString: String) {
        let request = NSMutableURLRequest(url: NSURL(string: urlString)! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
                
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                self.delegate?.alertManager(self, didFailWithError: error)
                return
            }

            if let data = data {
                if let (model, annotations) = self.parseJSON(data) {
                    self.delegate?.alertManager(self, didFetchAlerts: model, with: annotations)
                }
            }
        }

        dataTask.resume()
    }

    private func parseJSON(_ apiData: Data) -> ([AlertModel], [LocationAnnotation])? {
        let decoder = JSONDecoder()
        
        do {
            let decoderData = try decoder.decode(APIData.self, from: apiData)
            var modelEntries: [AlertModel] = []
            var annotationEntries: [LocationAnnotation] = []
            
            for data in decoderData.data {
                let dateString = data.date
                let totalCases = data.confirmed
                let totalDeaths = data.deaths
                let newCases = data.confirmed_diff
                let newDeaths = data.deaths_diff
                let cfr = data.fatality_rate
                let iso = data.region.iso
                let countryName = data.region.name
                let province = data.region.province
                let provinceLat = data.region.lat
                let provinceLong = data.region.long
                
                //i.e. for US cities only
                for cities in data.region.cities {
                    let cityName = cities.name
                    let cityLat = cities.lat
                    let cityLong = cities.long
                    let cityTotalCases = cities.confirmed
                    let cityTotalDeaths = cities.deaths
                    let cityNewCases = cities.confirmed_diff
                    let cityNewDeaths = cities.deaths_diff
                                        
                    //Only pull in the info if there's valid latitude and longitude coordinates!
                    if let latitude = Double(cityLat ?? "error"), let longitude = Double(cityLong ?? "error") {
                        //Get the AlertModel for the city
                        let model = AlertModel(dateString: dateString, countryCases: Cases(totalCases: totalCases, totalDeaths: totalDeaths, newCases: newCases, newDeaths: newDeaths), cfr: cfr, iso: iso, countryName: countryName, province: province, provinceCoordinates: Coordinates(latitudeString: provinceLat, longitudeString: provinceLong), cityName: cityName, cityCoordinates: Coordinates(latitudeString: cityLat, longitudeString: cityLong), cityCases: Cases(totalCases: cityTotalCases, totalDeaths: cityTotalDeaths, newCases: cityNewCases, newDeaths: cityNewDeaths))
                        modelEntries.append(model)

                        //Get the LocationAnnotation for the city
                        let locationAnnotation = LocationAnnotation(countryName: countryName, provinceName: province, cityName: cityName, riskLevel: model.riskLevel, todaysCases: model.cityCases!.newCasesString, todaysDeaths: model.cityCases!.newDeathsString, totalCases: model.cityCases!.totalCasesString, totalDeaths: model.cityCases!.totalDeathsString, dateToday: model.dateStringFormatted, coordinate: CLLocation(latitude: latitude, longitude: longitude).coordinate)
                        annotationEntries.append(locationAnnotation)
                    }
                }
                
                //Get the models for the province (state) only if there's valid latitude and longitude coordinates!
                if data.region.cities.isEmpty {
                    if let latitude = Double(provinceLat ?? "error"), let longitude = Double(provinceLong ?? "error") {
                        let model = AlertModel(dateString: dateString, countryCases: Cases(totalCases: totalCases, totalDeaths: totalDeaths, newCases: newCases, newDeaths: newDeaths), cfr: cfr, iso: iso, countryName: countryName, province: province, provinceCoordinates: Coordinates(latitudeString: provinceLat, longitudeString: provinceLong), cityName: nil, cityCoordinates: nil, cityCases: nil)
                        modelEntries.append(model)
                        
                        let locationAnnotation = LocationAnnotation(countryName: countryName, provinceName: province, cityName: nil, riskLevel: model.riskLevel, todaysCases: model.countryCases.newCasesString, todaysDeaths: model.countryCases.newDeathsString, totalCases: model.countryCases.totalCasesString, totalDeaths: model.countryCases.totalDeathsString, dateToday: model.dateStringFormatted, coordinate: CLLocation(latitude: latitude, longitude: longitude).coordinate)
                        annotationEntries.append(locationAnnotation)
                    }
                }
            }
            
            return (modelEntries, annotationEntries)
        }
        catch {
            delegate?.alertManager(self, didFailWithError: error)
            return nil
        }
    }

    
    // MARK: - fetchRegions()
    
    func fetchRegions() {
        let urlString = "https://" + headers[K.rapidapiHost]! + "/regions"
        performRequestForRegions(with: urlString)
    }
    
    private func performRequestForRegions(with urlString: String) {
        let request = NSMutableURLRequest(url: NSURL(string: urlString)! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                self.delegate?.alertManager(self, didFailWithError: error)
                return
            }

            if let data = data {
                if let model = self.parseJSONForRegions(data) {
                    self.delegate?.alertManager(self, didFetchRegions: model)
                }
            }
        }
        dataTask.resume()
    }
    
    private func parseJSONForRegions(_ apiData: Data) -> [RegionOnly]? {
        let decoder = JSONDecoder()
        
        do {
            let decoderData = try decoder.decode(APIDataForRegions.self, from: apiData)
            var modelEntries: [RegionOnly] = []
            
            for data in decoderData.data {
                let iso = data.iso
                let name = data.name
                let model = RegionOnly(iso: iso, name: name)
                modelEntries.append(model)
            }
            
            return modelEntries
        }
        catch {
            delegate?.alertManager(self, didFailWithError: error)
            return nil
        }
    }


}
