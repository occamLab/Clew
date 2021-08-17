//
//  CompassHeadingManager.swift
//
//  Created by Paul Ruvolo on 8/14/21.
//

import Foundation
import ARKit
import CoreMotion

class CompassHeadingManager: NSObject, CLLocationManagerDelegate  {
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let sceneView: ARSCNView
    var arrowNode: SCNNode?
    var magneticYaw: Float?
    
    /// Arrow object
    var arrowObject : MDLObject!
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        loadAssets()
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: queue) { motion, error in
            if let motion = motion {
                let rot = motion.attitude.rotationMatrix
                // Note: this is in terms of a different coordinate convention than ARKit uses to describe the device pose

                let coreMotionToARKit = simd_float3x3(simd_float3(0, 1, 0), simd_float3(-1, 0, 0), simd_float3(0, 0, 1))
                let magNorth = coreMotionToARKit * simd_float3(Float(rot.m11), Float(rot.m21), Float(rot.m31))
                let gravity = coreMotionToARKit * simd_float3(Float(rot.m13), Float(rot.m23), Float(rot.m33))
                if let cameraTransform = self.sceneView.session.currentFrame?.camera.transform {
                    let magNorthWorldFrame = (cameraTransform * simd_float4(magNorth, 0)).dropW
                    // magnetic yaw aligns the z-axis with magnetic north
                    self.magneticYaw = atan2(magNorthWorldFrame.x, magNorthWorldFrame.z)
                    print("magYaw", self.magneticYaw)
                    var arrow = matrix_identity_float4x4
                    arrow.columns.3 = cameraTransform.columns.3 - simd_float4(0, 0.5, 0, 0) - 2*simd_normalize(simd_float4(cameraTransform.columns.2.x, 0, cameraTransform.columns.2.z, 0))
                    arrow.columns.0 = simd_float4(magNorthWorldFrame, 0)
                    arrow.columns.2 = simd_float4(0, 1, 0, 0)
                    arrow.columns.1 = -simd_float4(simd_cross(arrow.columns.0.dropW, arrow.columns.2.dropW), 0)
                    let scale = 0.5
                    if self.arrowNode == nil {
                        self.arrowNode = SCNNode(mdlObject: self.arrowObject)
                        for material in self.arrowNode!.geometry!.materials {
                            material.diffuse.contents = UIColor.green
                        }

                        DispatchQueue.main.async {
                            self.sceneView.scene.rootNode.addChildNode(self.arrowNode!)
                            self.arrowNode!.simdTransform = arrow
                            self.arrowNode!.scale = SCNVector3(1*scale, 0.25*scale, 0.25*scale)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.arrowNode!.simdTransform = arrow
                            self.arrowNode!.scale = SCNVector3(1*scale, 0.25*scale, 0.25*scale)
                        }
                    }
                }
            }
        }
    }
    
    /// Load the crumb 3D model
    func loadAssets() {
        let arrowUrl = NSURL(fileURLWithPath: Bundle.main.path(forResource: "arrow", ofType: "obj")!)
        let arrowAsset = MDLAsset(url: arrowUrl as URL)
        arrowObject = arrowAsset.object(at: 0)
    }
}
