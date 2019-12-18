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
    let contentDictioanry = [("\(NSLocalizedString("appFeaturesHeading", comment: "this is a heading in the help documentation. it is also used for the creation of the accessibility labels used to inform the user as to how to interact with the help documantatio's accordian menu"))","""
        <h3>\(NSLocalizedString("appFeaturesCurrentVersionHeading", comment: "this is a heading in the help documentation and part of the app features section."))</h3>
        <p>\(NSLocalizedString("appfeaturesCurrentVersionContent", comment: "this is a paragraph in the app features section of the help menu which describes the main features of Clew"))</p>
        <h3>\(NSLocalizedString("appFeaturesFutureVersionsHeader", comment: "This is a heading in the app features section of the help documentation."))</h3>
        <p>\(NSLocalizedString("appFeaturesFutureVersionsContent", comment: "this is a paragraph in the app Features section of the help documentation which describes the features which are under development for future versions of the app."))</p>
        """),("\(NSLocalizedString("howWellDoesClewWorkHeader", comment: "This is a section heading in the help documentation menu"))","""
            <p>\(NSLocalizedString("howWellDoesClewWorkContentParagraph1", comment: "This is a paragraph in the How well does Clew work? section of the help documentation. This paragraph describes how the app actually works"))</p>
            <p>\(NSLocalizedString("howWellDoesClewWorkContentParagraph2", comment: "This is a paragraph in the How well does Clew work section of the help documentation. This paragraph describes how users should use CLew to supplement their orientation and mobility skills rather than using the app as a replacement for their traditional. orientation and mobility skills" ))</p>
            """),("\(NSLocalizedString("PausingARouteOrRecordingAAnchorPointHeader", comment: "This is a section heading in the help documentation menu"))","""
            <p>\(NSLocalizedString("PausingARouteOrRecordingAAnchorPointContentParagraph1", comment: "This is a content paragraph in the Pausing a Route or Recording a Anchor Point section of the help menu which talks about why an allignment process is necessary"))</p>
            <p>\(NSLocalizedString("PausingARouteOrRecordingAAnchorPointContentParagraph2", comment: "This is the second paragraph in the Pausing a Route and Recording a Anchor Point section of the help menu. This paragraph discusses the process of creating a Anchor Point including reasoning for why a Anchor Points are necessary and some tips for most effective use of the feature."))</p>
            
            
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
                <h3>\(NSLocalizedString("savedRoutesSharingASavedRouteHeader", comment: "This is a header in the saved routes section of the help documentation"))</h3>
                <p>\(NSLocalizedString("savedRoutesSharingASavedRouteContent", comment: "This is a paragraph in the saved routes section of the help documentation. This paragraph describes how to share a saved route."))</p>
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
                    <p>\(NSLocalizedString("followingARouteCorrectOffsetAutomaticallyContent", comment: "this is a paragraph in the following a route section of the help documentation which describes the functionality of the correct for phone / body offset feature."))</p>
                    """),("\(NSLocalizedString("appSoundsAndTheirMeaningsHeader", comment: "This is a section header in the help documentation"))","""
                        <p>\(NSLocalizedString("appSoundsAndTheirMeaningsContent", comment: "This is a paragraph in the App sounds and their meanings section."))</p>
                        <ul>
                        <li><p>\(NSLocalizedString("appSoundsAndTheirMeaningsNormalMotionTrackingSoundBullet", comment: "This is a bullet point which describes the normal motion tracking sound and its meaning"))</p></li>
                        <li><p>\(NSLocalizedString("appSoundsAndTheirMeaningsMotionTrackingWarningSoundBullet", comment: "This is a bullet point which describes the motion tracking warning sound and its meaning"))</p></li>
                        </ul>
                        """),("\(NSLocalizedString("ratingYourNavigationExperienceHeader", comment: "This is a section header in the help documentation menu"))","""
                            <p>\(NSLocalizedString("ratingYourNavigationExperienceContent", comment: "This is a paragraph in the rating your navigation experiennce section of the help menu."))</p>
                            """),("\(NSLocalizedString("providingFeedbackToTheDevelopmentTeamHeader", comment: "this is a section in the help documentation menu"))","""
                                <p>\(NSLocalizedString("providingFeedbackToTheDevelopmentTeamContent", comment: "This is a paragraph which describes how to send feedback to the development team"))</p>
                                </body>
                                </html>
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
