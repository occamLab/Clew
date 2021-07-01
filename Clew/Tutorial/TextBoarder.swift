//
//  TextBoarder.swift
//  Clew
//
//  Created by Declan Ketchum on 7/1/21.
//  From Samuel Do's video: https://www.youtube.com/watch?v=MJLoKS1i1oQ
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct TextBoarder: ViewModifier {
    var color: Color
    var lineWidth: Int
    
    func body(content: Content) -> some View {
        applyShadow(content: AnyView(content), lineWidth: lineWidth)
    }
    
    func applyShadow(content: AnyView, lineWidth: Int) -> AnyView{
        if lineWidth == 0{
            return content
        } else {
            return applyShadow(content: AnyView(content.shadow(color: color, radius: 1)), lineWidth: lineWidth-1)
        }
    }
}

extension View {
    func textboarder(color: Color, lineWidth: Int) -> some View {
        self.modifier(TextBoarder(color: color, lineWidth: lineWidth))
    }
}

