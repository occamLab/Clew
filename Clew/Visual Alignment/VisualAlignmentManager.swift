//
//  VisualAlignmentManager.swift
//  Clew
//
//  Created by Paul Ruvolo on 11/15/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation

protocol VisualAlignmentManagerDelegate {
    func shouldContinueAlignment()->Bool
    func isPhoneVertical()->Bool?
    func alignmentSuccessful(manualAlignment: simd_float4x4)
    func alignmentFailed(fallbackTransform: simd_float4x4)
}

class VisualAlignmentManager {
    public static var shared = VisualAlignmentManager()
    
    private var alignAnchorPoint: RouteAnchorPoint?
    private var delegate: VisualAlignmentManagerDelegate?
    
    /// keep track of when we last announced trouble with visual alignment
    private var lastVisualAlignmentFailureAnnouncement = Date()
    
    /// the first pose to use as a fallback if visual alignment fails
    private var firstAlignmentPose: simd_float4x4?
    
    /// the relative yaws computed during visual alignment
    private var relativeYaws: [Float] = []
    
    private init() {
        
    }
    
    func doVisualAlignment(delegate: VisualAlignmentManagerDelegate, alignAnchorPoint: RouteAnchorPoint, maxTries: Int, makeAnnouncement: Bool, isTutorial: Bool = false) {
        print("Visual Called")
        reset()
        self.delegate = delegate
        self.alignAnchorPoint = alignAnchorPoint
        doVisualAlignmentHelper(triesLeft: maxTries, makeAnnouncement: makeAnnouncement, isTutorial: isTutorial)
    }
    
    private func doVisualAlignmentHelper(triesLeft: Int, makeAnnouncement: Bool = false, isTutorial: Bool = false) {
//        if delegate?.shouldContinueAlignment() != true {
//            print("Cock Blocking")
//            return
//        }
        print("In Helper function")
        print(self.alignAnchorPoint)
        if delegate?.isPhoneVertical() == false {
            // retry later if phone is not vertical
            if -lastVisualAlignmentFailureAnnouncement.timeIntervalSinceNow > ViewController.timeBetweenVisualAlignmentFailureAnnouncements {
                lastVisualAlignmentFailureAnnouncement = Date()
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("holdVerticallyToContinueAlignment", comment: "tell the user that they need to hold their phone vertically for visual alignment to proceed"))
            }
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.25) {
                self.doVisualAlignmentHelper(triesLeft: triesLeft, makeAnnouncement: makeAnnouncement, isTutorial: isTutorial)
            }
            print("not vertical")
            return
        }
        if let alignAnchorPoint = alignAnchorPoint, let alignAnchorPointImage = alignAnchorPoint.image, let alignTransform = alignAnchorPoint.anchor?.transform, let frame = ARSessionManager.shared.currentFrame {
            print("Ok fr")
            if makeAnnouncement {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("visualAlignmentConfirmation", comment: "Announce that visual alignment process has began"))
            }

            DispatchQueue.global(qos: .userInitiated).async {
                let intrinsics = frame.camera.intrinsics
                let capturedUIImage = pixelBufferToUIImage(pixelBuffer: frame.capturedImage)!
                let visualYawReturn = VisualAlignment.visualYaw(alignAnchorPointImage, alignAnchorPoint.intrinsics!, alignTransform, capturedUIImage, simd_float4(intrinsics[0, 0], intrinsics[1, 1], intrinsics[2, 0], intrinsics[2, 1]), frame.camera.transform, Int32(2))
                
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                if self.firstAlignmentPose == nil {
                    self.firstAlignmentPose = frame.camera.transform
                }
                if visualYawReturn.is_valid, abs(visualYawReturn.residualAngle) < 0.01 {
                    let relativeTransform = Self
                        .getRelativeTransform(cameraTransform: frame.camera.transform, alignTransform: alignTransform, visualYawReturn: visualYawReturn)
                    let relativeYaw = atan2(relativeTransform.columns.0.z, relativeTransform.columns.0.x)
                    self.relativeYaws.append(relativeYaw)
                    
                    PathLogger.shared.logAlignmentEvent(alignmentEvent: .successfulVisualAlignmentTrial(transform: frame.camera.transform, nInliers: Int(visualYawReturn.numInliers), nMatches: Int(visualYawReturn.numMatches), yaw: relativeYaw, isTutorial: isTutorial))

                    SoundEffectManager.shared.success()
                } else {
                    PathLogger.shared.logAlignmentEvent(alignmentEvent: .unsuccessfulVisualAlignmentTrial(transform: frame.camera.transform, nInliers: Int(visualYawReturn.numInliers), nMatches: Int(visualYawReturn.numMatches), isTutorial: isTutorial))
                    
                    if self.relativeYaws.isEmpty, triesLeft < ViewController.maxVisualAlignmentRetryCount - 3, -self.lastVisualAlignmentFailureAnnouncement.timeIntervalSinceNow > ViewController.timeBetweenVisualAlignmentFailureAnnouncements {
                        self.lastVisualAlignmentFailureAnnouncement = Date()
                        DispatchQueue.main.async {
                            AnnouncementManager.shared.announce(announcement: NSLocalizedString("havingTroubleVisuallyAligning", comment: "this is announced if visual alignment hasn't succeeded after a while."))
                        }
                    } else {
                        SoundEffectManager.shared.error()
                    }
                }
                if triesLeft > 1 && self.relativeYaws.count < ViewController.requiredSuccessfulVisualAlignmentFrames {
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + (visualYawReturn.is_valid ? 0.25 : 1.0)) {
                        self.doVisualAlignmentHelper(triesLeft: triesLeft-1, isTutorial: isTutorial)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if self.delegate?.shouldContinueAlignment() != true {
                        return
                    }
                    if !self.relativeYaws.isEmpty {
                        let quantizedYaws = self.relativeYaws.map({Int($0*50)})
                        let mostFrequent = mostFrequent(array: quantizedYaws)!
                        var suitableYaws: [Float] = []
                        for relativeYaw in self.relativeYaws {
                            if Int(relativeYaw*50) == mostFrequent.mostFrequent[0] {
                                suitableYaws.append(relativeYaw)
                            }
                        }
                        let consensusYaw: Float
                        // If we don't have more than 2 colliding in the same bucket, fall back on a simple average
                        if mostFrequent.count < 2 {
                            let consensusUnitVec = self.relativeYaws.reduce(simd_float2(repeating: 0.0), { (x,y) in x + simd_float2(cos(y), sin(y))/Float(self.relativeYaws.count)})
                            consensusYaw = atan2(consensusUnitVec.y, consensusUnitVec.x)
                        } else {
                            consensusYaw = suitableYaws.reduce(Float(0.0), { (x,y) in x + y/Float(mostFrequent.count)})
                        }
                        var relativeTransform = simd_float4x4.makeRotate(radians: consensusYaw, 0, 1, 0)
                        relativeTransform.columns.3 = simd_float4(alignTransform.columns.3.dropW - relativeTransform.rotation() * self.firstAlignmentPose!.columns.3.dropW, 1)
                        self.delegate?.alignmentSuccessful(manualAlignment: relativeTransform.inverse)
                        PathLogger.shared.logAlignmentEvent(alignmentEvent: .finalVisualAlignmentSucceeded(transform: relativeTransform.inverse, isTutorial: isTutorial))
                    } else {
                        let alignmentPose = self.firstAlignmentPose ?? matrix_identity_float4x4
                        var visualYawReturnCopy = visualYawReturn
                        visualYawReturnCopy.is_valid = true
                        visualYawReturnCopy.yaw = 0
                        var cameraTransform = frame.camera.transform
                        cameraTransform.columns.3 = alignmentPose.columns.3
                        let relativeTransform = Self.getRelativeTransform(cameraTransform: cameraTransform, alignTransform: alignTransform, visualYawReturn: visualYawReturnCopy)
                        self.delegate?.alignmentFailed(fallbackTransform: relativeTransform)
                        PathLogger.shared.logAlignmentEvent(alignmentEvent: .finalVisualAlignmentFailed(transform: relativeTransform, isTutorial: isTutorial))

                    }
                }
            }
        }
    }
    
    static func getRelativeTransform(cameraTransform: simd_float4x4, alignTransform: simd_float4x4, visualYawReturn: VisualAlignmentReturn)->simd_float4x4 {
        let alignRotation = simd_float3x3(simd_float3(alignTransform[0, 0], alignTransform[0, 1], alignTransform[0, 2]),
                                          simd_float3(alignTransform[1, 0], alignTransform[1, 1], alignTransform[1, 2]),
                                          simd_float3(alignTransform[2, 0], alignTransform[2, 1], alignTransform[2, 2]))
        
        let leveledAlignRotation = visualYawReturn.square_rotation1.inverse * alignRotation;
        
        var leveledAlignPose = leveledAlignRotation.toPose()
        leveledAlignPose[3] = alignTransform[3]
        
        let cameraRotation = cameraTransform.rotation()
        let leveledCameraRotation = visualYawReturn.square_rotation2.inverse * cameraRotation;
        var leveledCameraPose = leveledCameraRotation.toPose()
        leveledCameraPose[3] = cameraTransform[3]
        
        let yawRotation = simd_float4x4.makeRotate(radians: visualYawReturn.yaw, -1, 0, 0)
        
        return leveledCameraPose * yawRotation.inverse * leveledAlignPose.inverse
    }
    
    func reset() {
        relativeYaws = []
        firstAlignmentPose = nil
        delegate = nil
    }
}
