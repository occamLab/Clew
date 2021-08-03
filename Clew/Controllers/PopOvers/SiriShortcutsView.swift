//
//  File.swift
//  Clew
//
//  Created by Arwa Alnajashi on 09/07/2021.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import SwiftUI

struct shortCutInvPhasee : Identifiable{
    //var id: ObjectIdentifier
    var id = UUID()
    var phase: String
   // var type: String
}



struct siriShortcutsView : View {

    
    var phrases: [shortCutInvPhasee]

    mutating func getShortcuts(){
        let vc = ViewController().voiceShortcuts
        for element in vc {
            phrases.append(shortCutInvPhasee(phase: element.invocationPhrase))
        }
    }
   
   
    
  var body: some View {
    
    List {
      HStack {
        Text("Charmander")
        Text("Fire").foregroundColor(.red)
        let vs = ViewController()
        let shortcuts = vs.voiceShortcuts
        
       
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
