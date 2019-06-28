//
//  PhoneOrientationTrainingVC.swift
//  Clew
//
//  Created by Terri Liu on 2019/6/28.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit

class PhoneOrientationTrainingVC: UIViewController{
    
    func didReceiveNewCameraPose(transform: simd_float4x4) {
    
         let angleFromVertical = acos(-transform.columns.0.y)
         let feedbackGenerator = UIImpactFeedbackGenerator(style: .light )
         
         if abs(angleFromVertical) < 0.1 {
         Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {_ in
         feedbackGenerator.impactOccurred()
         }
         }
         if abs(angleFromVertical) < 0.5 && abs(angleFromVertical) > 0.1 {
         Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) {_ in
         feedbackGenerator.impactOccurred()
         }
         }
         print("angleFromVertical", angleFromVertical)
}
}
