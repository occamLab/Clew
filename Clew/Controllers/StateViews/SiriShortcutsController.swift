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
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(kNewSingleUseRouteType)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        
        activity.title = NSLocalizedString("startSingleUseRouteRecordingShortcutTitle", comment: "The title to use for the single use route recording Siri shortcut")
        attributes.contentDescription = NSLocalizedString("startSingleUseRouteRecordingShortcutDescription", comment: "The description to use for the single use route recording Siri shortcut")
        activity.suggestedInvocationPhrase = NSLocalizedString("startSingleUseRouteRecordingShortcutSuggestedPhrase", comment: "This is the default invocation phrase suggested to the user for the single use route recording shortcut")
        activity.contentAttributeSet = attributes
        return activity
    }
    
    public static func stopRecordingShortcut() -> NSUserActivity {
        let activity = NSUserActivity(activityType: kStopRecordingType)
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(kStopRecordingType)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        activity.title = NSLocalizedString("stopRecordingShortcutTitle", comment: "The title to use for stopping a route recording")
        attributes.contentDescription = NSLocalizedString("stopRecordingShortcutDescription", comment: "The description to use for the stopping a route recording Siri shortcut")
        activity.suggestedInvocationPhrase = NSLocalizedString("stopRecordingShortcutSuggestedPhrase", comment: "This is the default invocation phrase suggested to the user for the  stop route recording shortcut")
        activity.contentAttributeSet = attributes
        return activity
    }
    
    public static func startNavigationShortcut() -> NSUserActivity {
        let activity = NSUserActivity(activityType: kStartNavigationType)
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(kStartNavigationType)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        
        activity.title = NSLocalizedString("startNavigationShortcutTitle", comment: "The title to use for the starting to navigate a route Siri shortcut")
        attributes.contentDescription = NSLocalizedString("startNavigationShortcutDescription", comment: "The description to use for the starting to navigate a route Siri shortcut")
        activity.suggestedInvocationPhrase = NSLocalizedString("startNavigationShortcutSuggestedPhrase", comment: "This is the default invocation phrase suggested to the user for the start navigation shortcut")
        return activity
    }
}
