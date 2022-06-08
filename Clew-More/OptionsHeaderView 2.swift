//
//  OptionsHeaderView.swift
//  Clew-More
//
//  Created by occamlab on 7/14/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct OptionsHeaderView: View {
    var vc: ViewController
    var body: some View {
        HStack{
            Button(action: {
                self.vc.dismiss(animated: false)
                // TODO: fix this below one, it shows up with a blank screen
                self.vc.present(BurgerMenuViewController(), animated: false)
            }) {
                Image("burgerMenu")
                    .resizable()
                    .frame(maxWidth: UIScreen.main.bounds.size.width/5, maxHeight: UIScreen.main.bounds.size.width/5)
            }
            Text("GORF")
        }
    }
}
