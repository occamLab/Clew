//
//  SiriShortcutsController.swift
//  Clew
//
//  Created by Arwa Alnajashi on 29/06/2021.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import Intents
import IntentsUI
import CoreSpotlight
import MobileCoreServices

///Initialize Siri Shortcuts Types
public let kNewSingleUseRouteType = "com.occamlab.NewSingleUseRoute"
public let kStopRecordingType = "com.occamlab.StopRecording"
public let kStartNavigationType = "com.occamlab.StartNavigation"


class SiriShortcutsController: UIViewController {

    ///Siri ShortCuts Functions
    ///Define the activities that we want users to be able to turn into voice comands, make these activities searchable and predictible.
    
    public static func newSingleUseRouteShortcut() -> NSUserActivity {
      let activity = NSUserActivity(activityType: kNewSingleUseRouteType)
      activity.persistentIdentifier =
        NSUserActivityPersistentIdentifier(kNewSingleUseRouteType)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        
        activity.title = "Start Single Use Route"
        attributes.contentDescription = "Let Clew help you navigate a single route !"
     
       
        activity.suggestedInvocationPhrase = "Start a single use route"

        activity.contentAttributeSet = attributes

      return activity
    }
    
    public static func stopRecordingShortcut() -> NSUserActivity {
      let activity = NSUserActivity(activityType: kStopRecordingType)
      activity.persistentIdentifier =
        NSUserActivityPersistentIdentifier(kStopRecordingType)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        
        activity.title = "Stop Recording Route"
        attributes.contentDescription = "Tell Clew to stop recording the route"
     
       
        activity.suggestedInvocationPhrase = "End the Route"

        activity.contentAttributeSet = attributes

      return activity
    }
    
    public static func startNavigationShortcut() -> NSUserActivity {
      let activity = NSUserActivity(activityType: kStartNavigationType)
      activity.persistentIdentifier =
        NSUserActivityPersistentIdentifier(kStartNavigationType)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        
        activity.title = "Return me back"
        attributes.contentDescription = "Tell Clew to start navigating the route"
     
       
        activity.suggestedInvocationPhrase = "Return me back"

        activity.contentAttributeSet = attributes

      return activity
    }
    
    
    
    
}
