//
//  MapViewController.swift
//  CORONAlert
//
//  Created by Eddie Char on 8/20/20.
//  Copyright © 2020 Eddie Char. All rights reserved.
//

import UIKit
import MapKit

protocol MapViewControllerDelegate {
    func mapViewController(_ controller: MapViewController, didSelect location: LocationAnnotation)
    func didRefreshAlerts(_ controller: MapViewController)
}


class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    var locationAnnotations: [LocationAnnotation]?
    var initialLocation: CLLocation!
    var delegate: MapViewControllerDelegate?
    
    //UISearch properties
    let tableViewController = LocationSearchTableViewController()
    var searchController: UISearchController!
    var selectedLocation: LocationAnnotation?
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    var isFilteringEnabled: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshButton.isEnabled = locationAnnotations == nil ? true : false
        
        //Set up the table view controller for the search
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
        tableViewController.locationAnnotations = locationAnnotations
        tableViewController.delegate = self
        searchController = UISearchController(searchResultsController: tableViewController)

        //Set initialLocation to Los Angeles, CA if location services is off or can't get current location.
        if initialLocation == nil {
            initialLocation = CLLocation(latitude: 34.30828379, longitude: -118.2282411)
        }
        
        let regionRadius: CLLocationDistance = 500000
        let initialRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(initialRegion, animated: true)
        mapView.delegate = self
        mapView.addAnnotations(locationAnnotations ?? [])
    }
    
    @IBAction func searchLocation(_ sender: UIBarButtonItem) {
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Location"
        
        present(searchController, animated: true, completion: nil)
    }
    
    @IBAction func refreshAlerts(_ sender: UIBarButtonItem) {
        delegate?.didRefreshAlerts(self)
    }
    
}


extension MapViewController: MKMapViewDelegate {
    //Sets up what happens when you click on the pin.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? LocationAnnotation else {
            return nil
        }

        let identifier = "location"
        var view: MKMarkerAnnotationView

        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        }
        else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: -5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            view.markerTintColor = annotation.riskLevel.1
            view.glyphTintColor = .white

            //Update the content
            let subtitleLabel = UILabel()
            subtitleLabel.font = UIFont(name: "Avenir", size: 12)
            subtitleLabel.text = "\(annotation.dateToday)\nToday's Cases: \(annotation.todaysCases)\nToday's Deaths: \(annotation.todaysDeaths)"
            subtitleLabel.numberOfLines = 0
            view.detailCalloutAccessoryView = subtitleLabel
        }

        return view
    }
    
    //Handle what happens if you click on the callout/detail disclosure.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? LocationAnnotation else {
            return
        }
        
        if searchController.isActive {
            searchController.dismiss(animated: true) {
                print("Dismiss search bar, first!")
            }
        }
        
        delegate?.mapViewController(self, didSelect: annotation)
        
        print("Tapped callout for \(annotation.locationName), \(annotation.coordinate).")
    }
}


// MARK: - LocationSearchTableViewControllerDelegate

extension MapViewController: LocationSearchTableViewControllerDelegate {
    //Zoom into selected county.
    func locationSearchTableViewController(_ controller: LocationSearchTableViewController, didSelect location: LocationAnnotation) {
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let radius = CLLocationDistance(100000)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: radius, longitudinalMeters: radius)
        self.mapView.setRegion(region, animated: true)
        selectedLocation = location
        
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - UI Search Results Updating

extension MapViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        let filteredAnnotations = locationAnnotations?.filter { (location: LocationAnnotation) -> Bool in
            return location.locationNameReversed.lowercased().contains(searchText.lowercased())
        }
        
        //MUST
        tableViewController.filteredAnnotations = filteredAnnotations
        tableViewController.isFilteringEnabled = isFilteringEnabled
        tableViewController.tableView.reloadData()
    }
}


// MARK: - Search Bar Delegate

extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //Dismisses the keyboard.
        searchBar.endEditing(true)
    }
}
