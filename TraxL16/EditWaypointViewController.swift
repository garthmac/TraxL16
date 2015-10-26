//
//  EditWaypointViewController.swift
//  TraxL15
//
//  Created by iMac21.5 on 5/11/15.
//  Copyright (c) 2015 Garth MacKenzie. All rights reserved.
//

import UIKit
import MobileCoreServices

class EditWaypointViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: Public API
    var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }
    
    // MARK: Private Implementation
    private func updateUI() {
        nameTextField?.text = waypointToEdit?.name
        infoTextField?.text = waypointToEdit?.info
        updateImage()
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Image/Camera
    var imageView = UIImageView()
    @IBOutlet weak var imageViewContainer: UIView! {
        didSet { imageViewContainer.addSubview(imageView) } }
    
    @IBAction func takePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .Camera
            //if video check media types
            picker.mediaTypes = [kUTTypeImage as String]
            picker.delegate = self
            picker.allowsEditing = true
            presentViewController(picker, animated: true, completion: nil)
        }
    }
    // MARK: UIImagePickerControllerDelegate, UINavigationControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var image = info[UIImagePickerControllerEditedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        imageView.image = image
        makeRoomForImage()
        saveImageInWaypoint()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func saveImageInWaypoint() {
        if let image = imageView.image { //opposite of contentsForURL()
            if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                let fileManager = NSFileManager() //inst instead of default
                //should store photo in photos but to demo fileSystem
                if let docsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first {
                    let unique = NSDate.timeIntervalSinceReferenceDate()
                    let url = docsDir.URLByAppendingPathComponent("\(unique).jpg")
                    let path = url.absoluteString
                    if imageData.writeToURL(url, atomically: true) {
                        waypointToEdit?.links = [GPX.Link(href: path)] //replace all links
                    }
                }
            }
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
    @IBOutlet weak var infoTextField: UITextField! { didSet { infoTextField.delegate = self } }
    
    
    // MARK: View Controller Lifecycle  
    override func viewDidLoad() {
        super.viewDidLoad()
        infoTextField.becomeFirstResponder()  //so keyboard opens
        updateUI() //in case model got set before viewing
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeTextFields()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = ntfObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
        if let observer = itfObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
    var ntfObserver: NSObjectProtocol?
    var itfObserver: NSObjectProtocol?
    
    func observeTextFields() {
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        ntfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification,
            object: nameTextField, queue:
            queue) { notification in
                if let waypoint = self.waypointToEdit {
                    waypoint.name = self.nameTextField.text
                }
        }
        itfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification,
            object: infoTextField, queue:
            queue) { notification in
                if let waypoint = self.waypointToEdit {
                    waypoint.info = self.infoTextField.text
                }
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Camera
    
    // updates the image at imageURL
    // does so off the main thread
    // then puts a closure back on the main queue
    //   to handle putting the image in the UI
    //   (since we aren't allowed to do UI anywhere but main queue)
    private func updateImage() {
        if let url = waypointToEdit?.imageURL {
            let qos = Int(QOS_CLASS_USER_INITIATED.rawValue)
            dispatch_async(dispatch_get_global_queue(qos, 0)) { [weak self] in
                if let imageData = NSData(contentsOfURL: url) {// this blocks the thread it is on
                    if url == self?.waypointToEdit?.imageURL {
                        if let image = UIImage(data: imageData) {
                            dispatch_async(dispatch_get_main_queue()) {
                                self!.imageView.image = image
                                self!.makeRoomForImage()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func makeRoomForImage() {
        var extraHeight: CGFloat = 0
        if imageView.image?.aspectRatio > 0 {
            if let width = imageView.superview?.frame.size.width {
                let height = width / imageView.image!.aspectRatio
                extraHeight = height - imageView.frame.height
                imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            }
        } else {
            extraHeight = -imageView.frame.height
            imageView.frame = CGRectZero
        }
        preferredContentSize = CGSize(width: preferredContentSize.width, height: preferredContentSize.height + extraHeight)
    }
}

extension UIImage {
    var aspectRatio: CGFloat {
        return size.height != 0 ? size.width / size.height : 0
    }
}
