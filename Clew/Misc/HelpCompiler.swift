//
//  HelpCompiler.swift
//  Clew
//
//  Created by tad on 6/26/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class HelpCompiler {

    let contentDictioanry = [("\(NSLocalizedString("appFeaturesHeading", comment: "this is a heading in the help documentation. it is also used for the creation of the accessability labels used to inform the user as to how to interact with the help documantatio's accordian menu"))","""
        <h3>\(NSLocalizedString("appFeaturesCurrentVersionHeading", comment: "this is a heading in the help documentation and part of the app features section."))</h3>
        <p>\(NSLocalizedString("appfeaturesCurrentVersionContent", comment: "this is a paragraph in the app features section of the help menu which describes the main features of Clew"))</p>
        <p>\(NSLocalizedString("appFeaturesNewFeaturesContent", comment: "This is a short section which describes the latest features added to the clew app."))</p>
        <h3>\(NSLocalizedString("appFeaturesFutureVersionsHeader", comment: "This is a heading in the app features section of the help documentation."))</h3>
        <p>\(NSLocalizedString("appFeaturesFutureVersionsContent", comment: "this is a paragraph in the app Features section of the help documentation which describes the features which are under development for future versions of the app."))</p>
        """),("\(NSLocalizedString("howWellDoesClewWorkHeader", comment: "This is a section heading in the help documentation menu"))","""
        <p>\(NSLocalizedString("howWellDoesClewWorkContentParagraph1", comment: "This is a paragraph in the How well does Clew work? section of the help documentation. This paragraph describes how the app actually works"))</p>
        <p>\(NSLocalizedString("howWellDoesClewWorkContentParagraph2", comment: "This is a paragraph in the How well does Clew work section of the help documentation. This paragraph describes how users should use CLew to supplement their orientation and mobility skills rather than using the app as a replacement for their traditional. orientation and mobility skills" ))</p>
        """),("\(NSLocalizedString("recordingARouteHeader", comment: "This is a section heading in the help documentation menu"))","""
        <p>\(NSLocalizedString("recordingARouteContent", comment: "This is a paragraph in the recording a route section which describes how to record a single use route"))
        <h3>\(NSLocalizedString("recordingARouteProperPositioningHeading", comment: "This is a heading in the recording a route section of the help documentation."))</h3>
        <p>\(NSLocalizedString("recordingARouteProperPositioningContent", comment: "This is a paragraph in the recording a route section of the help menu. This paragraph describes how to properly hold the phone while recording a route for optimal performance"))</p>
        """),("\(NSLocalizedString("savedRoutesHeader", comment: "This is a section header in the help documentation"))","""
        <p>\(NSLocalizedString("savedRoutesContent", comment: "this is a paragraph in the saved routes section of the help documentation. this paragraph describes the basic functionaliuty of the saved routes feature"))</p>
        <h3>\(NSLocalizedString("savedRoutesLoadingARouteHeader", comment: "This is a header in the saving routes section of the help documentation menu"))</h3>
        <p>\(NSLocalizedString("savedRoutesLoadingARouteContent", comment: "This is a paragraph in the saving routes section of the help menu which describes the process for loading a saved route for navigation."))</p>
        <h3>\(NSLocalizedString("savedRoutesDeletingASavedRouteHeader", comment: "This is a header in the saved routes section of the help documentation"))</h3>
        <p>\(NSLocalizedString("savedRoutesDeletingASavedRouteContent", comment: "This is a paragraph in the saved routes section of the help documentation. This paragraph describes how to delete a saved route."))</p>
        """)]
    func compileWebContent()->String{
        
        var result:String = """
        <!DOCTYPE html>
        <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                    .collapsible {
                        background-color: #777;
                        color: white;
                        cursor: pointer;
                        padding: 18px;
                        width: 100%;
                        border: none;
                        text-align: left;
                        outline: none;
                        font-size: 15px;
                    }
                
                    .active, .collapsible:hover {
                        background-color: #555;
                    }
                
                    .content {
                        padding: 0 18px;
                        display: none;
                        overflow: hidden;
                        background-color: #f1f1f1;
                    }
                </style>
            </head>
            <body>
        """
        
        for (key,value) in contentDictioanry{
            
            let section = """
            <!--creates an accordian menu heading which needs to be exapanded by defualt.-->
            <button class="collapsible" aria-label = "expand \(key) section"> \(key) </button>
            <!-- the content that is hidden goes here -->
            <div class="content">
                \(value)
            </div>
            """
            result = result + section
        }
        result = result + """
        <!--Loads the Javascript which handles the collapseability and the accessability tags.-->
        <script async src="./helpDocsJavascript.js"> </script>
        """
        return result
    }
    
    func loadWebContent(webView: WKWebView){
        let url = Bundle.main.url(forResource: "helpDocsJavascript", withExtension: "js", subdirectory: "help/javascript")!
        //let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "help")!
        webView.loadFileURL(url, allowingReadAccessTo: url)
        
        //creates the string of HTML that contains the web content for the help page
        let webContent = compileWebContent()
        ///loads the web content by loading the HTML string provided in the item object
        webView.loadHTMLString(webContent, baseURL: url)
    }
    
}
