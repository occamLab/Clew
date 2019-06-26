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

    let contentDictioanry = ["App Features":"""
        <h3>Current Version</h3>
        <p>Clew allows you to record routes using your phone that you can then navigate (either in the forward or reverse direction) at a later point in time. Clew can be used in situations where you want to immediately navigate back to your starting location (e.g., if you went somewhere with a sighted guide or if it is harder to navigate the reverse journey) or when you want to remember a route that you are learning so you can navigate it more confidently in the future.  Importantly, Clew does not use your phone's GPS, so it can be used indoors.</p>
        <p>The ability to save routes is a new feature for Clew.</p>
        <h3>Future Versions</h3>
        <p>We are working on a route sharing feature so that you can send routes to other users.</p>
        ""","How well does Clew work?":"""
        <p>Clew relies on the position tracking technology provided by Apple's ARKit. These motion estimates are based on tracking elements in the environment visually (using your phone's camera) and on motion estimates from inertial sensors in your phone. While this technology is advanced, it does not work perfectly. You should expect that over very long routes, particular ones with limited visual features or poor lighting, that the accuracy of the tracking (and hence the app's guidance) will decrease. We have found that Clew works best when you navigate routes along the same direction as they were originally recorded (&quot;Start to End &quot; rather than &quot;End to Start &quot; navigation mode).</p>
        <p>Given the limitations of Clew, you should always use your orientation and mobility skills to ensure your personal safety when using Clew. We are working on additional strategies for improving the accuracy of Clew.</p>
        ""","Recording a route":"""
        <p>As soon as the app launches, the app will present three buttons: saved routes, record route, and create landmark. To record a route that you don't need to save, or if you only want to be able to save the route in the reverse direction, you can simply activate the record button and move along the route you'd like to record. If you want to be able to save the route so that you can receive automatic guidance along it at a later time, activate the create landmark button and follow the procedure for landmark creation and route pausing described later in this document.
        <h3>Properly positioning your phone when using Clew</h3>
        <p>The app's motion estimates are based primarily on analyzing images from your phone's camera. The app will not work unless your phone's rear camera is capturing images of your environment. The app will not work if the phone is in your pocket or if any part of your body is blocking your phone's rear camera. We have found that the app works best when you hold the phone in portrait orientation with the rear camera facing directly ahead of you and the phone oriented vertically. Other orientations can work, but may result in diminished accuracy.</p>
        """]
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
        <!--Loads the Javascript which handles the collapseability and the accessability tags.
        <script>
            //finds all of the collapseable elements in the menu
            var coll = document.getElementsByClassName("collapsible");
            //creates an index counter variable
            var i;
            //updates the accessability labels
            function updateAccessabilityLabels (htmlElement,action){
                //if the user just opened a section
                if (action == "open"){
                    //set the accessability label
                    htmlElement.setAttribute("aria-Label","contract " + htmlElement.innerHTML + " section");
                    return 0
                }
                //if the user is closing the section
                if (action == "close"){
                    //set the accessability label
                    htmlElement.setAttribute("aria-Label","expand " + htmlElement.innerHTML + " section");
                    return 0
                }
            }
            //itterates through all of the collapseable elements
            for (i = 0; i < coll.length; i++) {
                //adds clickable functionality
                coll[i].addEventListener("click", function() {
                    //toggles the active state of the collapseable element
                    this.classList.toggle("active");
                    //grabs a reference to the content
                    var content = this.nextElementSibling;
                    //if the content is displayed
                    if (content.style.display === "block") {
                        //hide the content
                        content.style.display = "none";
                        //change the accessability tag
                        updateAccessabilityLabels(this,"close");
                    } else {
                        //show the content
                        content.style.display = "block";
                        //change the accessability tag
                        updateAccessabilityLabels(this,"open");
                    }
                });
            }
        </script>
        </body>
        </html>
        """
        return result
    }
    
    func loadWebContent(webView: WKWebView){
        let url = Bundle.main.url(forResource: "helpDocsJavascript", withExtension: "js", subdirectory: "help")!
        //let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "help")!
        webView.loadFileURL(url, allowingReadAccessTo: url)
        
        //creates the string of HTML that contains the web content for the help page
        let webContent = compileWebContent()
        ///loads the web content by loading the HTML string provided in the item object
        webView.loadHTMLString(webContent, baseURL: url)
    }
    
}
