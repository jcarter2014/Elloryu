//
//  ViewController.swift
//  Feb26LyftTest
//
//  Created by John Carter on 2/26/18.
//  Copyright © 2018 Jack Carter. All rights reserved.
//

import UIKit
import LyftSDK
import UberRides
import GoogleMaps
import GooglePlaces
import GooglePlacePicker

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    var currentLatitude: CLLocationDegrees?
    var currentLongitude: CLLocationDegrees?
    
    var finalLatitude: CLLocationDegrees?
    var finalLongitude: CLLocationDegrees?
    
    @IBOutlet weak var ridesButton: UIButton!
    let locationManager = CLLocationManager()
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var destinationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
        
        
        let location: CLLocationCoordinate2D = (locationManager.location?.coordinate)!
        print(location)
        currentLatitude = location.latitude
        currentLongitude = location.longitude
        currentLocationLabel.layer.zPosition = 1
        
        destinationButton.layer.zPosition = 1
        ridesButton.layer.zPosition = 1
        
        mapView.animate(toLocation: location)
        mapView.animate(toZoom: 15)
        self.view.bringSubview(toFront: destinationButton)
        self.view.bringSubview(toFront: ridesButton)

    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        
        let latitude = position.target.latitude
        let longitude = position.target.longitude
        let location: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        currentLatitude = latitude
        currentLongitude = longitude
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemark, error) in
            if error != nil {
                print("There was an error")
            } else {
                if let place = placemark?[0] {
                    self.currentLocationLabel.text = place.name
                }
            }
        }
    }

    func getUberRides() {
        
        let ridesClient = RidesClient()
        let pickupLocation = CLLocation(latitude: currentLatitude!, longitude: currentLongitude!)
        let dropoffLocation = CLLocation(latitude: finalLatitude!, longitude: finalLongitude!)
        let builder = RideParametersBuilder()
        builder.pickupLocation = pickupLocation
        builder.dropoffLocation = dropoffLocation
        
        ridesClient.fetchProducts(pickupLocation: pickupLocation) { products, response in
            guard let uberX = products.filter({$0.productGroup == .uberX}).first else {
                // Handle error, UberX does not exist at this location
                print("UberX does not exist at this location")
                return
            }
            builder.productID = uberX.productID
            ridesClient.fetchRideRequestEstimate(parameters: builder.build(), completion: { rideEstimate, response in
                guard let rideEstimate = rideEstimate else {
                    // Handle error, unable to get an ride request estimate
                    print("Unable to get a ride request estimate")
                    return
                }
                builder.upfrontFare = rideEstimate.fare
                print(builder.upfrontFare)
                print(rideEstimate)
                print(response)
//                ridesClient.requestRide(parameters: builder.build(), completion: { ride, response in
//                    guard let ride = ride else {
//                        // Handle error, unable to request ride
//                        return
//                    }
//                    // Ride has been requested!
//                })
            })
        }
    }
    
    func getLyftRides() {
        
        let pickup = CLLocationCoordinate2D(latitude: currentLatitude!, longitude: currentLongitude!)
        
        let location = pickup
        let destination = CLLocationCoordinate2D(latitude: finalLatitude!, longitude: finalLongitude!)
        
        LyftAPI.rideTypes(at: location) { result in
            result.value?.forEach { rideType in
                print(rideType.displayName)
            }
        }

        LyftAPI.costEstimates(from: pickup, to: destination, rideKind: .Standard) { result in
            result.value?.forEach { costEstimate in
                print("Min: \(costEstimate.estimate!.minEstimate.amount)$")
                print("Max: \(costEstimate.estimate!.maxEstimate.amount)$")
                print("Distance: \(costEstimate.estimate!.distanceMiles) miles")
                print("Duration: \(costEstimate.estimate!.durationSeconds/60) minutes")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func getDestinationAddress(_ sender: Any) {
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    
    @IBAction func getRides(_ sender: Any) {
        
        getUberRides()
        getLyftRides()
    }
}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let address = place.formattedAddress
        destinationButton.setTitle(address, for: .normal)
        finalLatitude = place.coordinate.latitude
        finalLongitude = place.coordinate.longitude
        
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        
        locationManager.startUpdatingLocation()
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

