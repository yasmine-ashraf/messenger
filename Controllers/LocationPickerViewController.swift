//
//  LocationPickerViewController.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 24/08/2021.
//

import UIKit
import MapKit
import CoreLocation

final class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    private var pin = MKPointAnnotation()
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    init(coordinates: CLLocationCoordinate2D?){
        self.coordinates = coordinates
        isPickable = coordinates == nil
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTapsRequired = 1
            gesture.numberOfTouchesRequired = 1
            map.addGestureRecognizer(gesture)
        }
        else {
            //Just add the annotion. user is viewing a sent location
            guard let coordinates = self.coordinates else {
                return
            }
            self.pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        map.frame = view.bounds
        view.addSubview(map)
       
    }
    @objc func sendButtonTapped() {
        guard let coordinates = coordinates else {
            return
        }
//        MKMapSnapshotter().start(completionHandler: { snapshot, error in
//            guard error == nil,  let snapshotImg = snapshot?.image else {
//                print("MKSnapshot failed")
//                return
//            }
//
//        })
        completion?(coordinates)
        navigationController?.popViewController(animated: true)
    }
    @objc func didTapMap(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: map)
        let coordinates = map.convert(loc, toCoordinateFrom: map)
        self.coordinates = coordinates
        self.pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
}
