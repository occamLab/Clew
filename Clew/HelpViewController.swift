//
//  HelpViewController.swift
//  Clew
//
//  Created by Paul Ruvolo on 2/16/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import WebKit

/// The view controller for the help dialog.  This is a thin wrapper on top of WKWebView, which displays the main content.
class HelpViewController : UIViewController {
    
    /// The view that displays the help as a webpage
    @IBOutlet var webContent: WKWebView!
    
    /// When the view has loaded, the index.html file will be loaded and rendered by webContent.
    override func viewDidLoad() {
        title = "Clew Help"
        let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "help")!
        webContent.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)
        webContent.load(request)
    }
    
    /// This is called when the view should close.  This method posts a notification "ClewPopoverDismissed" that can be listened to if an object needs to know that the view is being closed.
    @objc func doneWithHelp() {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
    }
}
