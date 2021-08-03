//
//  File.swift
//  Clew
//
//  Created by Arwa Alnajashi on 09/07/2021.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import SwiftUI


struct Stack {
    private var items: [String] = []
    
    func peek() -> String {
        guard let topElement = items.first else { fatalError("This stack is empty.") }
        return topElement
    }
    
    mutating func pop() -> String {
        return items.removeFirst()
    }
  
    mutating func push(_ element: String) {
        items.insert(element, at: 0)
    }
}



struct shortCutInvocationPhasee : Identifiable{
    //var id: ObjectIdentifier
    var id = UUID()
    var phase: String
    var type: String
   // var type: String
}


//func getShortcuts()->  [shortCutInvocationPhasee]{
//    var phrases: [shortCutInvocationPhasee]
//
//    let vc = ViewController().voiceShortcuts
//    for element in vc {
//        phrases.append(shortCutInvocationPhasee(phase: element.invocationPhrase))
//    }
//    return phrases
//}

struct shortcutRow: View{
    var shortcut: shortCutInvocationPhasee
    var siriShortcutsTypesDico = [kNewSingleUseRouteType : "Single Use Route Siri Shortcut:", kExperimentRouteType: "Experiment Route Siri Shortcut:", kStopRecordingType: "Stop Recording Siri Shortcut:", kStartNavigationType:"Start Navigation Siri Shortcut:"]
    var body: some View{
        Text("\(siriShortcutsTypesDico [shortcut.type] ?? "siri shortcut :  ")\(shortcut.phase) ").foregroundColor(.white).bold()
     
//        Text("\(ViewController.siriShortcutsTypesDico [shortcut.type] ?? "siri shortcut : /n")").foregroundColor(.yellow).bold()
//        Text("\(shortcut.phase) ").foregroundColor(.white)
//
    }
    
}


struct siriShortcutsView : View {

  
   let shortcuts = ViewController.voiceCommandsList
    var body: some View{
        
        List(shortcuts){ shortcut in shortcutRow(shortcut:shortcut)
       
            
        }
    }
    
}

struct siriView : View {

     //   let display = getShortcuts()
    
  
   
   
    
  var body: some View {
    
    List {
      HStack {
        Text("Charmander")
        Text("Fire").foregroundColor(.red)
        let vs = ViewController()
        let shortcuts = vs.voiceShortcuts
        //getShortcuts()
        
       
      }
      HStack {
        Text("Squirtle")
        Text("Water").foregroundColor(.blue)
      }
      HStack {
        Text("Bulbasaur")
        Text("Grass").foregroundColor(.green)
      }
      HStack {
        Text("Pikachu")
        Text("Electric").foregroundColor(.yellow)
      }
    }
  }
}
