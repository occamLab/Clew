//
//  TutorialTestViews.swift
//  Clew
//
//  Created by Declan Ketchum on 6/21/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct TutorialScreen<Content: View>: View {
  let content: Content
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  var body: some View {
    content
        //.navigationTitle("CLEW Tutorial", displayMode: .inline)
        .navigationBarItems(
            trailing:
                Button(NSLocalizedString("buttonTexttoExitTutorial", comment: "text of the button that dismisses the tutorial screens")) {
                    NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
                        })
       /* if #available(iOS 14.0, *) {
            Text(" ")
                .navigationTitle("CLEW Tutorial")
                .navigationBarItems(
                    leading:
                        Button("Exit") {
                        
                                },
                    trailing:
                        Button("Next") {})
        } else {
            // Fallback on earlier versions
        }*/
        
    /*.navigationBarTitle(Text(NSLocalizedString("surveyPopoverTitle", comment: "This is the title of the survey popover that is displayed to get feedback")), displayMode: .inline).navigationBarItems(trailing: Button(action: {

    }) { Text(NSLocalizedString("dismissSurvey", comment: "this is the button text that dismisses the survey"))}) */
  }
}


struct TutorialTestView: View {    
    var body: some View {
        NavigationView{

            TutorialScreen{
                    VStack (spacing: 30){
                        Text(NSLocalizedString("tutorialTitleText", comment: "Title of the Clew Tutorial Screen. Top of the first tutorial page"))
                        
                        NavigationLink(destination: OrientPhone()) {Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Text for the tutorial screem for phone position"))}
                        
                        NavigationLink(destination: FindPath()) {Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))}
                        
                        NavigationLink(destination: SignleUse()) {Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))}
                        
                        NavigationLink(destination: SavedRoutes()) {Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))}
                        
                        NavigationLink(destination: FindingSavedRoutes()) {Text(NSLocalizedString( "findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))}
                        
                        NavigationLink(destination: SettingOptions()) {Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))}
                }
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
                    
                    NavigationLink(destination: FindPath()) {Text("Next")}
                
            }
        }
    }
}

struct FindPath: View {
    var body: some View {
        TutorialScreen{
            VStack{
                Text("Finding and Following the Path")
            
                Text("To allow your route to be navigated at a later pointyou need to record an anchor point for the start of your route...")
            
                NavigationLink(destination: SignleUse())  {Text("Next")}
            }
        }
    }
}



struct SignleUse: View {
    var body: some View {
        TutorialScreen{
            VStack{
                Text("Using a Signle Use Route")
                
                NavigationLink(destination: SavedRoutes()) {Text("Next")}
            }
        }
    }
}


struct SavedRoutes: View {
    var body: some View {
        TutorialScreen{
            VStack{
                Text("Saved Routes")
            
                Text("To allow your route to be navigated at a later pointyou need to record an anchor point for the start of your route...")
                
                NavigationLink(destination: AnchorPoints()) {Text("Making Anchor Points")}
                
                NavigationLink(destination: VoiceNotes()) {Text("Recording Voice Notes")}
                
                NavigationLink(destination: FindingSavedRoutes())  {Text("Next")}
            }
        }
    }
}

struct AnchorPoints: View {
    var body: some View {
        TutorialScreen  {
            VStack{
                Text("Making an Anchor Point")
                
                Text("")
                
            }
        }
    }
}

struct VoiceNotes: View {
    var body: some View {
        TutorialScreen  {
            VStack{
                Text("Recording Voice Notes")
                
                Text("When recording a saved route, there is a button on the right that allows you to record a voice note. A voice note is a note you can leave yourself, that will play when you go to use the save route that you are recording. It can be any information that is helpful to you, such as noting where a landmark like a doorway or front desk is as you pass, or instructions for your future self. Later when you go to use a save route the voice notes will appear as speaker icons on your path at the point thye were recorded. As you pass the note will play.")
                
            }
        }
    }
}


struct FindingSavedRoutes: View {
    var body: some View {
        TutorialScreen  {
            VStack{
                Text("Finding Saved Routes")
                
                Text("Once you save a route, it can be found in your Saved Routes List. You can enter the list from the third button on the home screen. From the list click the route that you want to follow, line your phone up with your anchor point and follow the route.")
                
                NavigationLink(destination: SettingOptions()) {Text("Next")}
            }
        }
    }
}


struct SettingOptions: View {
    var body: some View {
        TutorialScreen{
            VStack{
                Text("Settings Options")
                
                Text("")
            }
        }
    }
}





struct TutorialTestViews_Previews: PreviewProvider {
    static var previews: some View {
        TutorialTestView()
    }
}

