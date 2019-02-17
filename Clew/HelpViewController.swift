//
//  HelpViewController.swift
//  Clew
//
//  Created by Paul Ruvolo on 2/16/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import WebKit

class HelpViewController : UIViewController {
    
    @IBOutlet var webContent: WKWebView!
    
    override func viewDidLoad() {
        let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "help")!
        webContent.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)
        webContent.load(request)
    }
}
