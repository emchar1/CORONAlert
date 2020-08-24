//
//  APIData.swift
//  CORONAlert
//
//  Created by Eddie Char on 8/19/20.
//  Copyright © 2020 Eddie Char. All rights reserved.
//

import Foundation


// MARK: - AlertDataForRegions (Region Only)

struct APIDataForRegions: Decodable {
    let data: [RegionOnly]
}

//Also used for AlertModel when getting Region only.
struct RegionOnly: Decodable {
    let iso: String
    let name: String
}


// MARK: - AlertData (Full Report)

struct APIData: Decodable {
    let data: [Country]
}

struct Country: Decodable {
    let date: String
    let confirmed: Int
    let deaths: Int
    let recovered: Int
    let confirmed_diff: Int
    let deaths_diff: Int
    let recovered_diff: Int
    let last_update: String
    let active: Int
    let active_diff: Int
    let fatality_rate: Double
    let region: Region
}

struct Region: Decodable {
    let iso: String
    let name: String
    let province: String
    let lat: String?
    let long: String?
    let cities: [City]
}

struct City: Decodable {
    let name: String
    let date: String
    let fips: Int?
    let lat: String?
    let long: String?
    let confirmed: Int
    let deaths: Int
    let confirmed_diff: Int
    let deaths_diff: Int
    let last_update: String
}
