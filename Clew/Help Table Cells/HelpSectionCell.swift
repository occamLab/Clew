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

    var section = 1
    
    @IBOutlet weak var webView: WKWebView!
    var webViewHeightConstraint: NSLayoutConstraint?
    
    var item: HelpViewModelItem? {
        didSet {
            guard  let item = item as? HelpViewModelHelpSectionItem else {
                return
            }
            webView.loadHTMLString(item.helpSection, baseURL: Bundle.main.bundleURL)
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            webView.navigationDelegate = self

        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { (height, error) in
            self.webViewHeightConstraint?.constant = (height as! CGFloat)
        })
//
//        webView.frame.size = CGSize(width: webView.scrollView.contentSize.width, height: webView.scrollView.contentSize.height)
//
//        print ("\(webView.scrollView.contentSize.height)  \(webView.frame.size.height)  Blah blah ")
//        frame.size = CGSize(width: webView.scrollView.contentSize.width, height: webView.scrollView.contentSize.height)
//
//        NotificationCenter.default.post(name: Notification.Name("webcontentloaded"), object: section)
        
    }
    
    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        webView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0).isActive = true
        webView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0).isActive = true
        webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true
        webViewHeightConstraint = webView.heightAnchor.constraint(equalToConstant: 200)
        webViewHeightConstraint?.isActive = true
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
