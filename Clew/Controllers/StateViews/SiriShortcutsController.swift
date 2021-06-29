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
    
    
    
}
