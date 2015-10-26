//
//  GPXViewController.swift
//  TraxL14
//
//  Created by iMac21.5 on 5/6/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit
import MapKit

    // MARK: - Outlets

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .Satellite
            mapView.delegate = self
        }
    }
    
    // MARK: - Public API
    
    var gpxURL: NSURL? {
        didSet { //if I get a URL, I will load it's waypoints
            clearWaypoints()
            if let url = gpxURL {
                GPX.parse(url) { //, completionHandler
                    if let gpx = $0 {
                        self.handleWaypoints(gpx.waypoints)
                    }
                }
            }
        }
    }

    // MARK: - Waypoints
    
    private func clearWaypoints() {
        if mapView?.annotations != nil {
            mapView.removeAnnotations(mapView.annotations)
        }
    }
    
    private func handleWaypoints(waypoints: [GPX.Waypoint]) {
        mapView.addAnnotations(waypoints)
        mapView.showAnnotations(waypoints, animated: true)
    }
   
    @IBAction func addWaypoint(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            let coordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "Dropped"
//            waypoint.links.append(GPX.Link(href: "https://cs193p.stanford.edu/Images/Panorama.jpg")) // for demo/debug/testing)
            mapView.addAnnotation(waypoint)
        }
    }

    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.AnnotationViewReuseIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view!.canShowCallout = true
        } else {
            view!.annotation = annotation
        }
        view!.draggable = annotation is EditableWaypoint //new test L15
        
        view!.leftCalloutAccessoryView = nil
        view!.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view!.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            } //else 4 lines up
            if annotation is EditableWaypoint {
                view!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure)
            }
        }
        return view  //pin is now created in this delegate func but not shown yet
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let waypoint = view.annotation as? GPX.Waypoint {
            if let _ = waypoint.thumbnailURL {
                if view.leftCalloutAccessoryView == nil {
                    //an Editable image must have been added with the Camera
                    view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
                }
            }
            if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton {
                if let imageData = NSData(contentsOfURL: waypoint.thumbnailURL!) {
                    //blocks main thread!
                    if let image = UIImage(data: imageData) {
                        thumbnailImageButton.setImage(image, forState: .Normal)
                    }
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //performSegue - copy Casini ImageViewController file and storyboard item
        // control drag from Story(Image View - frame button to new IVC
//        performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
        if (control as? UIButton)?.buttonType == UIButtonType.DetailDisclosure {
            mapView.deselectAnnotation(view.annotation, animated: false)
            //edit waypoint
            performSegueWithIdentifier(Constants.EditWaypointSegue, sender: view)
        } else if let waypoint = view.annotation as? GPX.Waypoint {
            if waypoint.imageURL != nil {
                performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
            }
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ShowImageSegue {
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? GPX.Waypoint {
                //note EmbededImageViewController is subclass of ImageViewController and shows small inset map
                if let wpvc = segue.destinationViewController.contentViewController as? EmbededImageViewController {
                    //prepare
                    wpvc.waypoint = waypoint
                } //else no longer needed but leave anyway
                else if let ivc = segue.destinationViewController.contentViewController as? ImageViewController {
                    //prepare
                    ivc.imageURL = waypoint.imageURL
                    ivc.title = waypoint.name
                }
            }
        } else if segue.identifier == Constants.EditWaypointSegue {
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? EditableWaypoint {
                if let ewvc = segue.destinationViewController.contentViewController as? EditWaypointViewController {
                    //prepare
                    if let ppc = ewvc.popoverPresentationController {
                        let coordinatePoint = mapView.convertCoordinate(waypoint.coordinate, toPointToView: mapView)
                        ppc.sourceRect = (sender as! MKAnnotationView).popoverSourceRectForCoordinatePoint(coordinatePoint)
                        let minimumSize = ewvc.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                        ewvc.preferredContentSize = CGSize(width: Constants.EditWaypointPopoverWidth, height: minimumSize.height)
                        ppc.delegate = self
                    }
                    ewvc.waypointToEdit = waypoint
                }
            }
        }
    }
    //Mark: UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.OverFullScreen
    }
    //I like it better without the following blurredBackground
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navCon = UINavigationController(rootViewController: controller.presentedViewController)
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        visualEffectView.frame = navCon.view.bounds
        navCon.view.insertSubview(visualEffectView, atIndex: 0)
        return navCon
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sign up to hear about GPX files arriving
        
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        
        center.addObserverForName(GPXURL.Notification, object: appDelegate, queue: queue) { notification in
            if let url = notification.userInfo![GPXURL.Key] as? NSURL {
                    //set the model
                self.gpxURL = url
            }
        }
        gpxURL = NSURL(string: "https://cs193p.stanford.edu/Vacation.gpx")
                // for demo/debug/testing
    }
    
    // MARK: - Constants
    
    private struct Constants {
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let PartialTrackColor = UIColor.greenColor()
        static let FullTrackColor = UIColor.blueColor().colorWithAlphaComponent(0.5)
        static let TrackLineWidth: CGFloat = 3.0
        static let ZoomCooldown = 1.5
        static let EditWaypointSegue = "Edit Waypoint"
        static let EditWaypointPopoverWidth: CGFloat = 320
    }
    
}

extension UIViewController {
    var contentViewController: UIViewController {
        if let navCon = self as? UINavigationController {
            return navCon.visibleViewController!
        } else {
            return self
        }
    }
}

extension MKAnnotationView {
    func popoverSourceRectForCoordinatePoint(coordinatePoint: CGPoint) -> CGRect {
        var popoverSourceRectCenter = coordinatePoint
        popoverSourceRectCenter.x -= frame.width / 2 - centerOffset.x - calloutOffset.x
        popoverSourceRectCenter.y -= frame.height / 2 - centerOffset.y - calloutOffset.y
        return CGRect(origin: popoverSourceRectCenter, size: frame.size)
    }
}
