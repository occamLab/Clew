//
//  TutorialTestViews.swift
//  Clew
//
//  Created by Declan Ketchum on 6/21/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct TutorialScreen<Content: View>: View {
    @State private var score = 0
  let content: Content
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  var body: some View {
    content
    NavigationView{
        if #available(iOS 14.0, *) {
            Text("Score: \(score)")
                .navigationTitle("CLEW Tutorial")
                .navigationBarItems(
                    leading:
                        Button("Subtract 1") {
                            self.score -= 1
                                },
                    trailing:
                        Button("Add 1") {
                            self.score += 1})
        } else {
            // Fallback on earlier versions
        }
        
    /*.navigationBarTitle(Text(NSLocalizedString("surveyPopoverTitle", comment: "This is the title of the survey popover that is displayed to get feedback")), displayMode: .inline).navigationBarItems(trailing: Button(action: {
        NotificationCenter.default.post(name: Notification.Name("SurveyPopoverReadyToDismiss"), object: nil)
    }) { Text(NSLocalizedString("dismissSurvey", comment: "this is the button text that dismisses the survey"))}) */
    }
  }
}


struct TutorialTestView: View {
    var body: some View {
        TutorialScreen{
                VStack (spacing: 30){
                    
                    
                    NavigationLink(destination: OrientPhone()) {Text("Holding Your Phone")}
                    
                    NavigationLink(destination: SetAnchorPoint()) {Text("Setting an Anchor Point")}
                    
                    NavigationLink(destination: SignleUse()) {Text("Using a Signle Use Route")}

                
            }
        }
    }
}

struct OrientPhone: View {
    var body: some View {
        TutorialScreen {
            VStack{
                Text("Holding Your Phone")
            
                Text("For best expereince using CLEW you will have to hold your phone virtically, dirrectly infront of your chest with the rear camera facing forward. This is because CLEW uses your phones camera to track where you move so that it can take you back along the same route")
                
                NavigationLink(destination: SetAnchorPoint()) {Text("Next")}
            }
            
        }
    }
}

struct SetAnchorPoint: View {
    var body: some View {
            VStack{
                Text("Setting an Anchor Point")
            
                Text("To allow your route to be navigated at a later pointyou need to record an anchor point for the start of your route...")
            
                NavigationLink(destination: SignleUse())  {Text("Next")}
            
        }
    }
}

struct SignleUse: View {
    var body: some View {
        VStack{
            Text("Using a Signle Use Route")
            
            Text("")
        }
    }
}

struct FindingSavedRoutes: View {
    var body: some View {
        VStack{
            Text("Finding Saved Routes")
            
            Text("")
        }
    }
}

struct SettingOptions: View {
    var body: some View {
        VStack{
            Text("Settings Options")
            
            Text("")
        }
    }
}





struct TutorialTestViews_Previews: PreviewProvider {
    static var previews: some View {
        TutorialTestView()
    }
}
