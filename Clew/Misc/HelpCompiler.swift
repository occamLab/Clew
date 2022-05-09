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

///and external class which contains the information necessary for loading the help documentation website
class HelpCompiler {
    
    ///creates a dictionry which sets up the HTML structure for all of the help menu sections. the format for a section is (NSLocalizedString describing the section header, html describing section content with NSLocalized strings for relevant sections)
    let contentDictioanry = [("Video Overview","""
        <p>The video below provides a basic overview of how the app functions. The video should be accessible to folks regardless of level of vision, but if any of it is unclear, please submit feedback to us through the \"Give Feedback\" menu.</p>
        <iframe width="560" height="315" src="https://www.youtube.com/embed/cVSaZxoNnZk" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
        """),("Obtaining the NFC Tags","""
            <p>As mentioned in the video overview, in order to register a place with Clew Maps, you must have an NFC tag.  NFC tags can be purchased at a low cost from many online retailers.  Here is <a href=\"https://www.amazon.com/THONSEN-NTAG215-NFC-enabled-Smartphones-Devices/dp/B074M9J5L3/ref=sr_1_5?crid=165E0S0UDPIDG&keywords=NFC+cards&qid=1652107713&sprefix=nfc+car%2Caps%2C297&sr=8-5\">a listing from the US Amazon Store</a> for 25 NFC cards.</p>
           """),("Obtaining the Tag Image of a Tree","""
                <p>As mentioned in the video overview, places in Clew Maps must be marked with both an NFC tag and a special image.  The image contains a picture of a tree with a black and yellow border.  We have PDFs for both <a href=\"https://drive.google.com/file/d/12Qi8qqvU5CoBhHfVSqzVI7dEd4Oks__k/view?usp=sharing\">US Letter Paper</a> and <a href=\"https://drive.google.com/file/d/1agFlpbXz2TYr0WVFXEm1oqco79obSM6U/view?usp=sharing\">A4 Paper</a> available.  It is best to print the images in color, but black and white is okay too.</p>
        """),("Tips for Installing the Image and the NFC Tag","""
                <p>As mentioned in the video overview, you need to install the NFC tag and the image of the tree at the start of any route.  Here are some tips to ehlp you do this well.</p>
                <ul>
                    <li>Choose a location that is easy to find without assistance from the app for your tag.</li>
                    <li>Choose a location that will not move for mounting your tag (e.g., don't choose a movable partition or wall).</li>
                    <li>You can place the NFC card underneath the image of the tree (printed tag), to make it easy to find the tree image once you have scanned the NFC card, but that is not a required.</li>
                    <li>To make the tag easier to find for folks with no functional vision, consider adding tactile indicators around the printed tree image (e.g., bump dot stickers).</li>
                    <li>Make sure not to obscure the printed image of the tree when you install it in your environment.  This image needs to be visible in order for the app to align properly.</li>
                    </ul>
        """),("\(NSLocalizedString("followingARouteHeader", comment: "This is a header for the following a route section of the help documentation."))","""
                    <p>\(NSLocalizedString("followingARouteContent", comment: "This is a paragraph which is in the following a route section of the help documentation."))</p>
                    <h3>\(NSLocalizedString("followingARouteHapticFeedbackHeader", comment: "This is a header inside the following a route section of the help documentation"))</h3>
                    <p>\(NSLocalizedString("followingARouteHapticFeedbackContent", comment: "this is a paragraph in the following a route section of the help documentation which describes the meaning of haptic feedback that the user recieves during navigation."))</p>
                    <h3>\(NSLocalizedString("followingARouteAuditoryBeepsHeader", comment: "This is a header inside the following a route section of the help documentation"))</h3>
                    <p>\(NSLocalizedString("followingARouteAuditoryBeepsContent", comment: "This is a paragraph in the following a route section of the help documentation which describes the menaing of audityory meps during navigation."))</p>
                    </h3>
                    <h3>\(NSLocalizedString("followingARouteSpeechFeedbackHeader", comment: "This is a header inside the following a route section of the help documentation"))</h3>
                    <p>\(NSLocalizedString("followingARouteSpeechFeedbackContent", comment: "this is a paragraph in the following a route section of the help documentation which describes the meaning of auditory speech feedback during navigation."))</p>
                    <h3>\(NSLocalizedString("followingARouteCorrectOffsetAutomaticallyHeader", comment: "This is a header inside the following a route section of the help documentation"))</h3>
                    <p>\(NSLocalizedString("followingARouteCorrectOffsetAutomaticallyContentParagraph1", comment: "this is paragraph 1 in the following a route section of the help documentation which describes the functionality of the correct for phone / body offset feature."))</p>
                    <p>\(NSLocalizedString("followingARouteCorrectOffsetAutomaticallyContentParagraph2", comment: "this is paragraph 2 in the following a route section of the help documentation which describes the functionality of the correct for phone / body offset feature."))</p>

                    """)]
    
    ///compiles all of the web content into a giant string of HTML
    func compileWebContent()->String{
        
        ///creates a string which will contain the html for the website and prep it witth the content which is rendered above any content specific to different help sections. this means that this creates the header, css, and loads the website title
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
        font: -apple-system-subheadline;
        }
        
        .active, .collapsible:hover {
        background-color: #555;
        }
        
        .content {
        padding: 0 18px;
        display: none;
        overflow: hidden;
        background-color: #f1f1f1;
        font: -apple-system-body;
        }
        img.image {
        display: block;
        margin-left: auto;
        margin-right: auto;
        width: 40%;
        border-radius: 30px;
        }
        .pageTitle {
        text-align: Center;
        font: -apple-system-headline;
        }
        </style>
        </head>
        <body>
        <img class = "image" src="./clewLogo.png" alt="\(NSLocalizedString("clewAppLogoAccessibilityText", comment: "This is the accessibility text placed over the clew app logo in the help documentation"))">
        <h1 class = "pageTitle"> \(NSLocalizedString("clewHelpTitle", comment: "This is the top heading of the help documentation"))</h1>
        """
        
        ///itterates through the dictionary of help sections and their content
        for (key,value) in contentDictioanry{
            
            //for each section this adds it to the html as a collapseable section with the proper content
            let section = """
            
            <!--creates an accordian menu heading which needs to be exapanded by defualt.-->
            <button class="collapsible" aria-label = "\(key): \(NSLocalizedString("expandSectionAccessibilityTag", comment: "This is a tag that is spoken by the accessibility elements. This tag describes the action a user must take to expand one of the sections in the help documentation"))"> \(key) </button>
            <!-- the content that is hidden goes here -->
            <div class="content">
            \(value)
            </div>
            """
            /// appends the latest section to the stack of sections
            result = result + section
        }
        ///appends the footer information to the html string. this includes adding the javascript for handeling accessibility (included inside this folder rather than a remote javascript file so it can be localized) and the javascript which handels the expanding and contracting menus.
        result = result + """
        <!--Loads the Javascript which handles the accessibility tags.-->
        <script>
        //updates the accessibility labels
        function updateAccessibilityLabels (htmlElement,action){
        //if the user just opened a section
        if (action == "open"){
        //set the accessibility label
        htmlElement.setAttribute("aria-Label", htmlElement.innerHTML + ":" + "\(NSLocalizedString("contractSectionAccessibilityTag", comment: "This is a tag that is spoken by the accessibility elements. This tag describes the action a user must take to collapse one of the sections in the help documentation"))");
        return 0
        }
        //if the user is closing the section
        if (action == "close"){
        //set the accessibility label
        htmlElement.setAttribute("aria-Label",htmlElement.innerHTML + ":" + "\(NSLocalizedString("expandSectionAccessibilityTag", comment: "This is a tag that is spoken by the accessibility elements. This tag describes the action a user must take to expand one of the sections in the help documentation"))");
        return 0
        }
        
        }
        </script>
        
        <!--Loads the Javascript which handles the collapseability-->
        <script async src="./helpDocsJavascript.js"> </script>
        """
        
        ///returns the string which contains the full html for the website
        return result
    }
    
    ///loads the help documentation content into a website
    func loadWebContent(webView: WKWebView){
        //gives access to the resources folder
        let url = Bundle.main.url(forResource: "helpDocsJavascript", withExtension: "js", subdirectory: "help/assets")!
        //let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "help")!
        webView.loadFileURL(url, allowingReadAccessTo: url)
        
        //creates the string of HTML that contains the web content for the help page
        let webContent = compileWebContent()
        ///loads the web content into a website by loading the HTML string provided in the item object
        webView.loadHTMLString(webContent, baseURL: url)
    }
    
}
