//
//  ViewController.swift
//  IBMDatacapSDKDeskew
//
//  Copyright © 2016 IBM Corporation. All rights reserved.
//

import UIKit

enum Segues:String {
    case Upload = "uploadImage"
}

class ViewController: UIViewController, ICPCameraViewDelegate {
    
    @IBOutlet weak var cameraView:ICPCameraView!
    
    var originalImage:UIImage!
    var modifiedImage:UIImage!
    
    private lazy var imageEngine:ICPImageEngine = {
        return ICPCoreImageImageEngine()
    }()
    
    var processImage:Bool {
        return originalImage == nil && modifiedImage == nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        cameraView?.delegate = self
    }


    @IBAction func takePicture(sender: AnyObject) {
        guard let cameraView = cameraView else { return }
        //To be able to capture an image without a recognisable document, the automaticallyDetectDocuments need to be set to false. This bug will be fixed on release 9.0.1.3
        cameraView.automaticallyDetectDocuments = false
        cameraView.takePhoto()
    }
    
    func cameraView(cameraView: ICPCameraView, didChangeState cameraState: ICPCameraViewState) {
        print("Camera View changed state to: \(cameraState)")
    }
    
    func cameraViewDidDetectDocument(cameraView: ICPCameraView) {
        cameraView.takePhoto()
    }
    
    func cameraView(cameraView: ICPCameraView, didTakeOriginalPhoto originalPhoto: UIImage?, modifiedPhoto: UIImage?) {
        
        guard processImage else { return }
        
        if let originalPhoto = originalPhoto, let modifiedPhoto = modifiedPhoto {
            self.deskewImage(originalPhoto, modifiedImage: modifiedPhoto)
        } else if let originalPhoto = originalPhoto {
            self.deskewImage(originalPhoto, modifiedImage: originalPhoto)
        }
    }
    
    func deskewImage(originalImage:UIImage, modifiedImage:UIImage) {
        
        
        let icpImageEditor = ICPImageEditingController(originaImage: originalImage, modifiedImage: modifiedImage, imageEngine: imageEngine, validator: cameraView?.edgeDetectionValidator) { [weak self] (controller, modifiedImage, imageWasModified) in
            
            guard let sself = self else { return }
            
            sself.originalImage = originalImage
            sself.modifiedImage = modifiedImage
            sself.cameraView?.stopPreview()
            sself.performSegueWithIdentifier(Segues.Upload.rawValue, sender: sself)
        }
        
        let deskewAction = ICPImageEditingAction(actionType: .Deskew)
        icpImageEditor.addImageEditingAction(deskewAction)
        icpImageEditor.runImageEditingActionOnPresentation(deskewAction)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(icpImageEditor, animated: true)
    }
    
    func resetState() {
        self.cameraView?.automaticallyDetectDocuments = true
        self.cameraView?.restartPreview()
        self.originalImage = nil
        self.modifiedImage = nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let uploadController = segue.destinationViewController as? ImageUploadViewController else { return }
        
        uploadController.originalImage = originalImage
        uploadController.modifiedImage = modifiedImage
    }
    
    @IBAction func prepareForUnwind(segue:UIStoryboardSegue) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        resetState()
    }
}

