//
//  ScanTagView.swift
//  UIKit Clip
//
//  Created by Berwin Lan on 7/30/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct ScanTagView: View {
    var body: some View {
        Text("Please scan NFC tag, or app clip code with Camera or Code Scanner, to open app clip.")
            .foregroundColor(Color.white)
            .font(.largeTitle)
            .padding()
    }
}
