//
//  LocationSearchTableViewController.swift
//  CORONAlert
//
//  Created by Eddie Char on 8/23/20.
//  Copyright © 2020 Eddie Char. All rights reserved.
//

import UIKit

protocol LocationSearchTableViewControllerDelegate {
    func locationSearchTableViewController(_ controller: LocationSearchTableViewController, didSelect location: LocationAnnotation)
}


class LocationSearchTableViewController: UITableViewController {
    var locationAnnotations: [LocationAnnotation]?
    var filteredAnnotations: [LocationAnnotation]?
    var isFilteringEnabled = false
    var delegate: LocationSearchTableViewControllerDelegate?


    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFilteringEnabled ? (filteredAnnotations?.count ?? 0) : (locationAnnotations?.count ?? 0)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)

        cell.textLabel?.font = UIFont(name: "Avenir", size: 14.0)
        cell.textLabel?.text = isFilteringEnabled ? (filteredAnnotations?[indexPath.row].locationNameReversed ?? "null") : (locationAnnotations?[indexPath.row].locationName ?? "null")

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedLocation = isFilteringEnabled ? filteredAnnotations?[indexPath.row] : locationAnnotations?[indexPath.row] {
            delegate?.locationSearchTableViewController(self, didSelect: selectedLocation)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
