//
//  CORONAlertTableViewController.swift
//  CORONAlert
//
//  Created by Eddie Char on 8/19/20.
//  Copyright © 2020 Eddie Char. All rights reserved.
//

import UIKit
import CoreLocation
import StoreKit

class CORONAlertTableViewController: UITableViewController {
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var riskLevelLabel: UILabel!
    @IBOutlet weak var todaysCasesLabel: UILabel!
    @IBOutlet weak var todaysDeathsLabel: UILabel!
    @IBOutlet weak var totalCasesLabel: UILabel!
    @IBOutlet weak var totalDeathsLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var alertManager = AlertManager()
    var alerts: [AlertModel]?
    var filteredAlerts: [AlertModel]?
    var locationAnnotations: [LocationAnnotation]?
    var filteredLocationAnnotations: [LocationAnnotation]?
    var closestCoordinates: Int?
    var filteredClosestCoordinates: Int?


    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertManager.delegate = self
        alertManager.fetchAlerts(date: nil)
        SKPaymentQueue.default().add(self)      //DON'T FORGET THIS!!!!
        
        if isPurchased() {
//            navigationItem.setRightBarButton(nil, animated: true)
        }
        
        getKeys()
    }
    
    
    // MARK: - Update Locations
    
    @IBAction func chooseLocation(_ sender: UIButton) {
        performSegue(withIdentifier: "goMap", sender: self)
    }
    
    @IBAction func resetLocation(_ sender: UIButton) {
        if closestCoordinates != nil {
            let alertController = UIAlertController(title: "Confirm", message: "Reset your current location?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction!) in
                //basically, just rerun the whole process from the beginning.
                self.attemptLocationAccess()
                
                print("Location reset.")
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
        else {
            attemptLocationAccess()
        }
    }
        
    func attemptLocationAccess() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location Services has been disabled. Please enable Location Services under iPhone Settings.")
            return
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            //Pop up the location authorization request alert on first time use.
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
            self.getClosestCoordinates(forLocation: self.locationManager.location)
        default:
            locationManager.requestLocation()
        }
    }
    
    /**
     Determines the closest location from the list of locations in the AlertModel.
     - parameter location: User's current location
     - note: This function iterates through all the AlertModel array items to get the shortest CLLocation distance from the user.
     */
    func getClosestCoordinates(forLocation location: CLLocation?) {
        guard let myLocation = location else {
            print("Unable to determine user's location.")
            return
        }
        
        guard let alerts = alerts, let locationAnnotations = locationAnnotations else {
            print("Alerts array is still empty for some reason. Breaking out of getClosestCoordinates function.")
            return
        }
        
        var shortestDistance: Double?

        for (i, alert) in alerts.enumerated() {
            if let latitude = alert.coordinates.latitude, let longitude = alert.coordinates.longitude {
                let checkCoordinates = CLLocation(latitude: latitude, longitude: longitude)
                let checkDistance = myLocation.distance(from: checkCoordinates)
                
                //Found shortest distance so far. Assign variables, appropriately.
                if shortestDistance == nil || checkDistance < shortestDistance! {
                    shortestDistance = checkDistance
                    closestCoordinates = i
                    
                    //Update UI
                    let (riskDescription, riskColor) = alerts[i].riskLevel
                    view.backgroundColor = riskColor
                    locationLabel.text = alerts[i].locationName
                    dateLabel.text = alerts[i].dateStringFormatted
                    riskLevelLabel.text = riskDescription.uppercased()
                    todaysCasesLabel.text = alerts[i].cases.newCasesString
                    todaysDeathsLabel.text = alerts[i].cases.newDeathsString
                    totalCasesLabel.text = alerts[i].cases.totalCasesString
                    totalDeathsLabel.text = alerts[i].cases.totalDeathsString
                }
            }
        }
        
        //for in-app purchases
        guard let closestCoordinates = closestCoordinates else {
            print("Unable to get closest coordinates.")
            return
        }
        
        guard !isPurchased() else {
            //all locations already purchased!
            showAllLocations()
            return
        }
        
        filteredAlerts = alerts.filter { (alertModel: AlertModel) -> Bool in
            if alertModel.province != "" {
                return alertModel.province == alerts[closestCoordinates].province
            }
            else {
                return alertModel.countryName == alerts[closestCoordinates].countryName
            }
        }
        
        filteredLocationAnnotations = locationAnnotations.filter{ (locationAnnotation: LocationAnnotation) -> Bool in
            if locationAnnotation.provinceName != "" {
                return locationAnnotation.provinceName == locationAnnotations[closestCoordinates].provinceName
            }
            else {
                return locationAnnotation.countryName == locationAnnotations[closestCoordinates].countryName
            }
        }
                
        shortestDistance = nil  //reuse from above
                
        //Again???
        if let filteredAlerts = filteredAlerts {
            for (i, filteredAlert) in filteredAlerts.enumerated() {
                if let latitude = filteredAlert.coordinates.latitude, let longitude = filteredAlert.coordinates.longitude {
                    let checkCoordinates = CLLocation(latitude: latitude, longitude: longitude)
                    let checkDistance = myLocation.distance(from: checkCoordinates)
                    
                    
                    if shortestDistance == nil || checkDistance < shortestDistance! {
                        shortestDistance = checkDistance
                        filteredClosestCoordinates = i
                    }
                }
            }
        }
    
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0.7
    }
    
    //Added this method here to remove one-time warning message.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goMap" {
            let nc = segue.destination as! UINavigationController
            let controller = nc.topViewController as! MapViewController
            controller.delegate = self

            //Set the locationAnnotations[] and initialLocation on the MapViewController()
            if let alerts = filteredAlerts, let locationAnnotations = filteredLocationAnnotations {
                controller.locationAnnotations = locationAnnotations
                
                if let i = filteredClosestCoordinates, let latitude = alerts[i].coordinates.latitude, let longitude = alerts[i].coordinates.longitude {
                    controller.initialLocation = CLLocation(latitude: latitude, longitude: longitude)
                }
            }
        }
    }
    
    
    // MARK: - Secrets.plist
    
    /**
     Gets the RapidAPIKey and ProductID from the Secrets.plist file.
     */
    func getKeys() {
        guard let path = Bundle.main.path(forResource: "Secret", ofType: "plist") else {
            print("Unable to get Secret.plist")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        
        guard let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String:String] else {
            print("Unable to get plist variable.")
            return
        }
        
        print(plist["RapidAPIKey"] ?? "No such key: RapidAPIKey")
        print(plist["ProductID"] ?? "No such key: ProductID")
    }


}


// MARK: - MapViewControllerDelegate

extension CORONAlertTableViewController: MapViewControllerDelegate {
    func mapViewController(_ controller: MapViewController, didSelect location: LocationAnnotation) {
        let newCoordinates = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        getClosestCoordinates(forLocation: newCoordinates)
        controller.dismiss(animated: true, completion: nil)
    }
    
    func didRefreshAlerts(_ controller: MapViewController) {
        if let locationAnnotations = filteredLocationAnnotations, controller.locationAnnotations == nil {
            controller.locationAnnotations = locationAnnotations
            controller.mapView.removeAnnotations(locationAnnotations)
            controller.mapView.addAnnotations(locationAnnotations)
            controller.refreshButton.isEnabled = false
            
            print("MapView updated with \(locationAnnotations.count) annotations.")
        }
        else {
            print("Pending update - MapView annotations not updated. Try again later.")
        }
    }
}


// MARK: - AlertManagerDelegate

extension CORONAlertTableViewController: AlertManagerDelegate {
    func alertManager(_ controller: AlertManager, didFetchAlerts alerts: [AlertModel], with annotations: [LocationAnnotation]) {
        self.alerts = alerts
        self.locationAnnotations = annotations
        
        DispatchQueue.main.async {
            self.attemptLocationAccess()
        }
    }
    
    func alertManager(_ controller: AlertManager, didFetchRegions regions: [RegionOnly]) {
        for region in regions {
            print(region)
        }
    }
    
    func alertManager(_ controller: AlertManager, didFailWithError error: Error) {
        print("Error retrieving API data: \(error)")
    }
}


// MARK: - CLLocationManagerDelegate

extension CORONAlertTableViewController: CLLocationManagerDelegate {
    //This is needed so that when user clicks Allow for the first (or everytime they access the app), then note the change and execute the appropriate code!
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            getClosestCoordinates(forLocation: locationManager.location)
        }
        
        if status == .denied || status == .restricted {
            view.backgroundColor = .lightGray
            locationLabel.text = "Error obtaining current location"
            riskLevelLabel.text = "Error"
            todaysCasesLabel.text = "Error"
            todaysDeathsLabel.text = "Error"
            totalCasesLabel.text = "Error"
            totalDeathsLabel.text = "Error"
            closestCoordinates = nil
            filteredClosestCoordinates = nil

            print("Denied.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        view.backgroundColor = .lightGray
        locationLabel.text = "Error obtaining current location"
        riskLevelLabel.text = "Error"
        todaysCasesLabel.text = "Error"
        todaysDeathsLabel.text = "Error"
        totalCasesLabel.text = "Error"
        totalDeathsLabel.text = "Error"
        closestCoordinates = nil
        filteredClosestCoordinates = nil

        print("Error requesting location: \(error.localizedDescription)")
    }
}


// MARK: - In App Purchase

extension CORONAlertTableViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                showAllLocations()
                SKPaymentQueue.default().finishTransaction(transaction)
                navigationItem.setRightBarButton(nil, animated: true)
                print("Transaction successful!")
            case .failed:
                if let error = transaction.error {
                    let errorDescription = error.localizedDescription
                    print("Transaction failed due to error: \(errorDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                showAllLocations()
                SKPaymentQueue.default().finishTransaction(transaction)
                navigationItem.setRightBarButton(nil, animated: true)
                print("Transaction restored.")
            default:
                print("Unknown transaction state.")
            }
        }
    }
    
    func buyAllLocations() {
        guard SKPaymentQueue.canMakePayments() else {
            print("Unable to make payments.")
            return
        }
        
        let paymentRequest = SKMutablePayment()
        paymentRequest.productIdentifier = productID
        SKPaymentQueue.default().add(paymentRequest)
    }
    
    func showAllLocations() {
        UserDefaults.standard.set(true, forKey: productID)
        filteredAlerts = alerts
        filteredLocationAnnotations = locationAnnotations
        filteredClosestCoordinates = closestCoordinates
    }
    
    func isPurchased() -> Bool {
        return UserDefaults.standard.bool(forKey: productID)
    }
    
    @IBAction func makePurchase(_ sender: UIBarButtonItem) {
        buyAllLocations()
    }
}
