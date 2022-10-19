//
//  TrialManager.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 3/5/21.
//

// TODO: need to do a better job connecting together saved routes and the route that is being navigated (hard to align the two right now)
// TODO: Check into why the frame metadata might be missing from some frames (maybe there is an error condition, or maybe just bad Wifi).  It's weird that all of the images were there but none of the metadata for an entire trial
// TODO: voiceover seems to get sluggish over time.  I'm not sure why though.  It might be CPU throttling or something like that.
// TODO: getting a good anchor image independently of having a perpendicular plane would be good (might require state machine)
// TODO: investigate whether the JPEG compression will corrupt our results

import Foundation
import Firebase
import ARKit

public struct ARFrameDataLog {
    public let timestamp: Double
    public let type: String
    public let jpegData: Data
    public let rawFeaturePoints: [simd_float3]?
    public let projectedFeaturePoints: [CGPoint]?
    public let depthData: [simd_float4]
    public let confData: [ARConfidenceLevel]
    public let planes: [ARPlaneAnchor]
    public let pose: simd_float4x4
    public let intrinsics: simd_float3x3
    public let meshes: [(String, [String: [[Float]]])]?
    
    init(timestamp: Double, type: String, jpegData: Data, rawFeaturePoints: [simd_float3]?, projectedFeaturePoints: [CGPoint]?, confData: [ARConfidenceLevel], depthData: [simd_float4], intrinsics: simd_float3x3, planes: [ARPlaneAnchor], pose: simd_float4x4, meshes: [(String, [String: [[Float]]])]?) {
        self.timestamp = timestamp
        self.type = type
        self.jpegData = jpegData
        self.confData = confData
        self.rawFeaturePoints = rawFeaturePoints
        self.projectedFeaturePoints = projectedFeaturePoints
        self.depthData = depthData
        self.planes = planes
        self.intrinsics = intrinsics
        self.pose = pose
        self.meshes = meshes
    }
    
    func metaDataAsJSON()->Data? {
        // Convert depthData into an array of floats that can be written into JSON
        var depthTable: [[Float]] = []
        for depthDatum in depthData {
            depthTable.append(depthDatum.asArray)
        }
        // Write body of JSON
        let body : [String: Any] = ["timestamp": timestamp, "rawFeaturePoints": (rawFeaturePoints?.map({[$0.x, $0.y, $0.z]})) ?? [], "projectedFeaturePoints": (projectedFeaturePoints?.map({[$0.x, $0.y]})) ?? [], "type": type, "pose": pose.asColumnMajorArray, "intrinsics": intrinsics.asColumnMajorArray, "planes": planes.map({["alignment": $0.alignment == .horizontal ? "horizontal": "vertical", "center": $0.center.asArray, "extent": $0.extent.asArray, "transform": $0.transform.asColumnMajorArray]})]
        if JSONSerialization.isValidJSONObject(body) {
            print("Metadata written into JSON")
            return try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } else {
            // TODO: log this error somewhere
            return nil
        }
    }
    
    func pointCloudToProtoBuf()->Data? {
        var pointCloudProto = Points()
        for (point, conf) in zip(depthData, confData) {
            var pointProto = DirectionAndDepth()
            pointProto.u = point.x
            pointProto.v = point.y
            pointProto.w = point.z
            pointProto.d = point.w
            pointCloudProto.points.append(pointProto)
            pointCloudProto.confidences.append(UInt32(conf.rawValue))
        }
        return try? pointCloudProto.serializedData()
    }
    
    func meshesToProtoBuf()->Data? {
        guard let meshes = meshes else {
            return nil
        }
        var meshesProto = MeshesProto()
        for mesh in meshes {
            var meshProto = MeshProto()
            var columnProtos: [Float4Proto] = []
            for column in mesh.1["transform"]! {
                var columnProto = Float4Proto()
                columnProto.x = column[0]
                columnProto.y = column[1]
                columnProto.z = column[2]
                columnProto.w = column[3]
                columnProtos.append(columnProto)
            }
            meshProto.transform.c1 = columnProtos[0]
            meshProto.transform.c2 = columnProtos[1]
            meshProto.transform.c3 = columnProtos[2]
            meshProto.transform.c4 = columnProtos[3]
            meshProto.id = mesh.0

            for (vert, normal) in zip(mesh.1["vertices"]!, mesh.1["normals"]!) {
                if vert != [] {
                    var vertexProto = VertexProto()
                    vertexProto.x = vert[0]
                    vertexProto.y = vert[1]
                    vertexProto.z = vert[2]
                    vertexProto.u = normal[0]
                    vertexProto.v = normal[1]
                    vertexProto.w = normal[2]
                    meshProto.vertices.append(vertexProto)
                }
            }
            meshesProto.meshes.append(meshProto)
        }
        return try? meshesProto.serializedData()
    }
}
