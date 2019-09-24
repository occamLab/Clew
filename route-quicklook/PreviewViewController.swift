//
//  PreviewViewController.swift
//  route-quicklook
//
//  Created by Dieter Brehm on 8/7/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit
import QuickLook

class PreviewViewController: UIViewController, QLPreviewingController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
        
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.

        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
    
    /*
     * Implement this method if you support previewing files.
     * Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
     *
     */
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {

        handler(nil)
    }
 
    
}
