//
//  voiceCommandView.swift
//  Clew
//
//  Created by Arwa Naj on 15/07/2021.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import SwiftUI
struct shortCutPhrasee : Identifiable{
    //var id: ObjectIdentifier
    var id = UUID()
    var phase: [String]
   // var type: String
}

class VoiceCommandsView: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        //
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //
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
