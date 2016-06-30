//
//  ImageUploadViewController.swift
//  IBMDatacapSDKDeskew
//
//  Copyright © 2016 IBM Corporation. All rights reserved.
//

import UIKit

struct SampleDatacapConfiguration {
    @nonobjc static let url = "<IBM Datacap Server URL>"
    @nonobjc static let userName = "<IBM Datacap user name>"
    @nonobjc static let userPassword = "<IBM Datacap user password>"
    @nonobjc static let stationId = "<IBM Datacap station ID>"
    @nonobjc static let stationIndex:Int32 = 0 //Station Index related to that Id
    @nonobjc static let applicationName = "<IBM Datacap application>"
    @nonobjc static let workflowId = "<Application Workflow id>"
    @nonobjc static let workflowIndex:Int32 = 0 //Index related to the selected Application Workflow
    @nonobjc static let jobId = "<Workflow Job Id>"
    @nonobjc static let jobIndex:Int32 = 0 //Index related to the selected Workflow Job
    @nonobjc static let setupDCOName = "<Setup DCO configuration name>"
    @nonobjc static let batchTypeId = "<Batch Type Id>"
    @nonobjc static let documentTypeId = "<Batch document type Id>"
    @nonobjc static let pageTypeId = "<Page Type Id>"
}

class ImageUploadViewController: UIViewController {

    var originalImage:UIImage!
    var modifiedImage:UIImage!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorHeightConstraint: NSLayoutConstraint!
    
    var sessionManager:ICPSessionManager!
    
    var status:String {
        get { return statusLabel?.text ?? "" }
        set { statusLabel?.text = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.hidesBarsOnTap = false
        self.navigationController?.setToolbarHidden(true, animated: false)
        
        status = "Creating document"
        
        guard let originalImage = originalImage, let modifiedImage = modifiedImage else {
            status = "Missing images"
            return
        }
        
        guard let url = NSURL(string: SampleDatacapConfiguration.url) else {
            status = "Invalid URL"
            return
        }
        
        guard let capture = ICPCapture.instanceWithObjectFactoryType(.NonPersistent) else {
            status = "Failed to create Datacap instance"
            return
        }
        guard let objectFactory = capture.objectFactory else {
            status = "Failed to create Datacap database"
            return
        }
        guard let service = capture.objectFactory?.datacapServiceWithBaseURL(url) else {
            status = "Failed to create service"
            return
        }
        
        service.station = objectFactory.stationWithStationId(SampleDatacapConfiguration.stationId, andIndex: SampleDatacapConfiguration.stationIndex, andDescription: "")
        service.application = objectFactory.applicationWithName(SampleDatacapConfiguration.applicationName)
        service.workflow = objectFactory.workflowWithWorkflowId(SampleDatacapConfiguration.workflowId, andIndex: SampleDatacapConfiguration.workflowIndex)
        service.job = objectFactory.jobWithJobId(SampleDatacapConfiguration.jobId, andIndex: SampleDatacapConfiguration.jobIndex)
        service.setupDCO = objectFactory.setupDCOWithName(SampleDatacapConfiguration.setupDCOName)
        
        let urlCredential = NSURLCredential(user: SampleDatacapConfiguration.userName, password: SampleDatacapConfiguration.userPassword, persistence: .ForSession)
        
        let batchType = objectFactory.batchTypeWithTypeId(SampleDatacapConfiguration.batchTypeId, inDatacapService: service)
        let batch = objectFactory.batchWithService(service, type: batchType)
        
        let documentType = objectFactory.documentTypeWithTypeId(SampleDatacapConfiguration.documentTypeId)
        let document = objectFactory.documentWithBatch(batch, type: documentType)
        
        let pageType = objectFactory.pageTypeWithTypeId(SampleDatacapConfiguration.pageTypeId)
        let page = objectFactory.pageWithDocument(document, type: pageType)
        
        page.modifiedImage = modifiedImage
        page.originalImage = originalImage
        
        self.sessionManager = capture.datacapSessionManagerForService(service, withCredential: urlCredential)
        self.sessionManager?.uploadBatch(batch, withProgressBlock: self.progressBlock, andCompletion: self.completion)
    }
    
    func startAnimation() {
        self.activityIndicatorHeightConstraint.constant = 37
        self.activityIndicator.startAnimating()
    }
    
    func stopAnimation() {
        self.activityIndicatorHeightConstraint.constant = 0
        self.activityIndicator.stopAnimating()
    }
    
    
    func progressBlock(progress:Float, object:AnyObject?) {
        status = "Uploading..."
    }
    
    func completion(success:Bool, batch:ICPBatch?, error:NSError?) {
        self.activityIndicator.stopAnimating()
        if let error = error {
            status = "Error on upload: \(error)"
        } else {
            status = "Image uploaded"
        }
    }

}
