//
//  EmbededImageViewController.swift
//  TraxL16
//
//  Created by iMac21.5 on 5/13/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit

class EmbededImageViewController: ImageViewController {
    // MARK: set model
    var waypoint: GPX.Waypoint? {
        didSet {
            //set superclasses model imageURL
            imageURL = waypoint?.imageURL
            title = waypoint?.name
            updateEmbededMap()
        }
    }
    
    var smvc: SimpleMapViewController?
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Embeded Map" {
            smvc = segue.destinationViewController as? SimpleMapViewController
            updateEmbededMap()
        }
    }
    
    func updateEmbededMap () {
        if let mapView = smvc?.mapView {
            mapView.mapType = .Hybrid
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(waypoint!)
            mapView.showAnnotations(mapView.annotations, animated: true)
            mapView.region.span.latitudeDelta = 0.5 //desired zoom level of the map, with smaller delta values corresponding to a higher zoom level
        }
    }
    
}
