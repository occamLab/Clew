//
//  HelpSectionCell.swift
//  Clew
//
//  Created by tad on 6/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class HelpSectionCell: UITableViewCell,WKNavigationDelegate{

    //MARK: Private variables
    ///describes what section this is in
    var section = 1
    ///describes what the hight of the webview will be
    var webViewHeightConstraint: NSLayoutConstraint?
    
    //MARK: Outlets
    @IBOutlet weak var webView: WKWebView!
    
    //MARK: Set Itam Type
    var item: HelpViewModelItem? {
        didSet {
            guard  let item = item as? HelpViewModelHelpSectionItem else {
                return
            }
            webView.loadHTMLString(item.helpSection, baseURL: Bundle.main.bundleURL)
            
            ///set delegate and remove scrolling
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            webView.navigationDelegate = self

        }
    }
    
    //MARK: on finished navigation
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        ///calculate the height of the webview
        webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { (height, error) in
            ///set height constraint to calculated height
            self.webViewHeightConstraint?.constant = (height as! CGFloat)
        })
        NotificationCenter.default.post(name: Notification.Name("webContentLoaded"), object: (webView.frame.size.height,section))
        print("\(webView.frame.size)Size")
    }
    
    //MARK: create Nib
    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    //MARK: NibDidLoad
    override func awakeFromNib() {
        /// sets the constraints on the web view
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        webView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0).isActive = true
        webView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0).isActive = true
        webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true
        webViewHeightConstraint = webView.heightAnchor.constraint(equalToConstant: 200)
        webViewHeightConstraint?.isActive = true
    }
    
    //MARK: set identifier
    static var identifier: String {
        return String(describing: self)
    }
}
