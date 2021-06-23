//
//  ContentView.swift
//  Clew App Clip
//
//  Created by occamlab on 6/23/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CustomController()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CustomController: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CustomController>) -> UIViewController {
        let storyboard = UIStoryboard(name: "LaunchScreen", bundle: Bundle.init(identifier: "edu.occam.Clew"))
        let controller = storyboard.instantiateViewController(withIdentifier: "Start")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CustomController>) {
        
    }
}
