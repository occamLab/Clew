//
//  PathFinder.swift
//  ARKitTest
//
//  Created by Chris Seonghwan Yoon & Jeremy Ryan on 7/11/17.
//
// Pathfinder class calculates turns or "keypoints" given a path array of LocationInfo
//
import Foundation
import VectorMath
import ARKit

/// Struct to store location and transform information
///
/// Contains:
/// * `location` (`LocationInfo`)
/// * `transformMatrix` (`Matrix3` from `VectorMath`)
public struct CurrentCoordinateInfo {
    public var location: LocationInfo
    public var transformMatrix: Matrix3 = Matrix3.identity
    
    public init(_ location: LocationInfo, transMatrix: Matrix3) {
        self.location = location
        self.transformMatrix = transMatrix
    }
    
    public init(_ location: LocationInfo) {
        self.location = location
    }
}

/// Struct to store position information and yaw
///
/// Contains:
/// * `x` (`Float`)
/// * `y` (`Float`)
/// * `z` (`Float`)
/// * `yaw` (`Float`)
public class LocationInfo : ARAnchor {
    
    required init(anchor: ARAnchor) {
        super.init(anchor: anchor)
    }
    
    override init(transform: simd_float4x4) {
        super.init(transform: transform)
    }
    
    override public class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
    
    public var translation: SCNVector3 {
        let translation = self.transform.columns.3
        return SCNVector3(translation.x, translation.y, translation.z)
    }
    
    public var rotation: SCNVector3 {
        let rotation = self.transform.columns.1
        return SCNVector3(rotation.x, rotation.y, rotation.z)
    }
    
    public var eulerAngles: SCNVector3 {
        get {
            // first we get the quaternion from m00...m22
            // see http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
            let qw = sqrt(1 + self.transform.columns.0.x + self.transform.columns.1.y + self.transform.columns.2.z) / 2.0
            let qx = (self.transform.columns.2.y - self.transform.columns.1.z) / (qw * 4.0)
            let qy = (self.transform.columns.0.z - self.transform.columns.2.x) / (qw * 4.0)
            let qz = (self.transform.columns.1.x - self.transform.columns.0.y) / (qw * 4.0)
            
            // then we deduce euler angles with some cosines
            // see https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
            // roll (x-axis rotation)
            let sinr = +2.0 * (qw * qx + qy * qz)
            let cosr = +1.0 - 2.0 * (qx * qx + qy * qy)
            let roll = atan2(sinr, cosr)
            
            // pitch (y-axis rotation)
            let sinp = +2.0 * (qw * qy - qz * qx)
            var pitch: Float
            if fabs(sinp) >= 1 {
                pitch = copysign(Float.pi / 2, sinp)
            } else {
                pitch = asin(sinp)
            }
            
            // yaw (z-axis rotation)
            let siny = +2.0 * (qw * qz + qx * qy)
            let cosy = +1.0 - 2.0 * (qy * qy + qz * qz)
            let yaw = atan2(siny, cosy)
            
            return SCNVector3(pitch, yaw, roll)
        }
    }
    
    public var x: Float {
        return translation.x
    }
    
    public var y: Float {
        return translation.y
    }
    
    public var z: Float {
        return translation.z
    }
    
    public var yaw: Float {
        return eulerAngles.y
    }
    
    func describe() -> String {
        return " " + String(x) + " " + String(y) + " " + String(z) + " " + String(yaw)
    }
}


/// Struct to store position and orientation of a keypoint
///
/// Contains:
/// * `location` (`LocationInfo`)
/// * `orientation` (`Vector3` from `VectorMath`)
public struct KeypointInfo {
    public var location: LocationInfo
    public var orientation: Vector3
}

class SavedRoute: NSObject, NSCoding {
    public var id: NSString
    public var name: NSString
    public var dateCreated: NSDate
    public var crumbs: [LocationInfo]
    public var pausedTransform: simd_float4x4
    
    public init(id: NSString, name: NSString, crumbs: [LocationInfo], dateCreated: NSDate = NSDate(), pausedTransform: simd_float4x4) {
        self.id = id
        self.name = name
        self.crumbs = crumbs
        self.dateCreated = dateCreated
        self.pausedTransform = pausedTransform
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(crumbs, forKey: "crumbs")
        aCoder.encode(dateCreated, forKey: "dateCreated")
        aCoder.encode(ARAnchor(transform: pausedTransform), forKey: "pausedTransformAsARAnchor")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: "id") as? NSString else {
            return nil
        }
        guard let name = aDecoder.decodeObject(forKey: "name") as? NSString else {
            return nil
        }
        guard let crumbs = aDecoder.decodeObject(forKey: "crumbs") as? [LocationInfo] else {
            return nil
        }
        guard let dateCreated = aDecoder.decodeObject(forKey: "dateCreated") as? NSDate else {
            return nil
        }
        guard let pausedTransformAsARAnchor = aDecoder.decodeObject(forKey: "pausedTransformAsARAnchor") as? ARAnchor else {
            return nil
        }
        self.init(id: id, name: name, crumbs: crumbs, dateCreated: dateCreated, pausedTransform: pausedTransformAsARAnchor.transform)
    }
}

/// Pathfinder class calculates turns or "keypoints" given a path array of LocationInfo
class PathFinder {
    
    ///  Maximum width of the breadcrumb path.
    ///
    /// Points falling outside this margin will produce more keypoints, through Ramer-Douglas-Peucker algorithm
    ///
    /// - TODO: Clarify units
    private let pathWidth: Scalar!
    
    private var crumbs: [LocationInfo]
    
    /// Initializes the PathFinder class and determines the value of `pathWidth`
    ///
    /// - Parameters:
    ///   - crumbs: a list of `LocationInfo` objects representing the trail of breadcrumbs left on the path
    ///   - hapticFeedback: whether or not hapticFeedback is on.
    ///   - voiceFeedBack: whether or not voiceFeedback is on.
    ///
    /// - TODO:
    ///   - Clarify why these magic `pathWidth` values are as they are.
    init(crumbs: [LocationInfo], hapticFeedback: Bool, voiceFeedback: Bool) {
        self.crumbs = crumbs
        if(!hapticFeedback && voiceFeedback) {
            pathWidth = 0.3
        } else {
            pathWidth = 0.3
        }
    }
    
    /// a list of `KeypointInfo` objects representing the important turns in the path.
    public var keypoints: [KeypointInfo] {
        get {
            return getKeypoints(edibleCrumbs: crumbs)
        }
    }
    
    /// Creates a list of keypoints in a path given a list of points dropped several times per second.
    ///
    /// - Parameter edibleCrumbs: a list of `LocationInfo` objects representing the trail of breadcrumbs left on the path.
    /// - Returns: a list of `KeypointInfo` objects representing the turns in the path
    func getKeypoints(edibleCrumbs: [LocationInfo]) -> [KeypointInfo] {
        var keypoints = [KeypointInfo]()
        let firstKeypointLocation = edibleCrumbs.first!
        let firstKeypointOrientation = Vector3.x
        keypoints.append(KeypointInfo(location: firstKeypointLocation, orientation: firstKeypointOrientation))
        
        keypoints += calculateKeypoints(edibleCrumbs: edibleCrumbs)
        
        let lastKeypointLocation = edibleCrumbs.last!
        let lastKeypointOrientation = Vector3(_: [(keypoints.last?.location.x)! - edibleCrumbs.last!.x,
                                                  0,
                                                  (keypoints.last?.location.z)! - edibleCrumbs.last!.z]).normalized()
        keypoints.append(KeypointInfo(location: lastKeypointLocation, orientation: lastKeypointOrientation))
        return keypoints
    }
    
    /// Recursively simplifies a path of points using Ramer-Douglas-Peucker algorithm.
    ///
    /// - Parameter edibleCrumbs: a list of `LocationInfo` objects representing the trail of breadcrumbs left on the path.
    /// - Returns: a list of `KeypointInfo` objects representing the important turns in the path.
    func calculateKeypoints(edibleCrumbs: [LocationInfo]) -> [KeypointInfo] {
        var keypoints = [KeypointInfo]()
        
        let firstCrumb = edibleCrumbs.first
        let lastCrumb = edibleCrumbs.last
        
        //  Direction vector of last crumb in list relative to first
        let pointVector = Vector3.init(_: [(lastCrumb?.x)! - (firstCrumb?.x)!,
                                        (lastCrumb?.y)! - (firstCrumb?.y)!,
                                        (lastCrumb?.z)! - (firstCrumb?.z)!])
        
        //  Vector normal to pointVector, rotated 90 degrees about vertical axis
        let normalVector = Matrix3.init(_: [0, 0, 1,
                                       0, 0, 0,
                                       -1, 0, 0]) * pointVector
        
        let unitNormalVector = normalVector.normalized()
        let unitPointVector = pointVector.normalized()
        
        //  Third orthonormal vector to normalVector and pointVector, used to detect
        //  vertical changes like stairways
        let unitNormalVector2 = unitPointVector.cross(unitNormalVector)
        
        var listOfDistances = [Scalar]()
        
        //  Find maximum distance from the path trajectory among all points
        for crumb in edibleCrumbs {
            let c = Vector3.init([crumb.x - (firstCrumb?.x)!, crumb.y - (firstCrumb?.y)!, crumb.z - (firstCrumb?.z)!])
            let a = c.dot(unitNormalVector2)
            let b = c.dot(unitNormalVector)
            listOfDistances.append(sqrtf(powf(a, 2) + powf(b, 2)))
        }
        
        let maxDistance = listOfDistances.max()
        let maxIndex = listOfDistances.index(of: maxDistance!)
        
        //  If a point is farther from path center than parameter pathWidth,
        //  there must be another keypoint within that stretch.
        if (maxDistance! > pathWidth) {
            
            //  Recursively find all keypoints before the detected keypoint and
            //  after the detected keypoint, and add them in a list with the
            //  detected keypoint.
            let prevKeypoints = calculateKeypoints(edibleCrumbs: Array(edibleCrumbs[0..<(maxIndex!+1)]))
            let postKeypoints = calculateKeypoints(edibleCrumbs: Array(edibleCrumbs[maxIndex!...]))
            
            var prevKeypointLocation = edibleCrumbs.first!
            var prevKeypointOrientation = Vector3.x
            if (!prevKeypoints.isEmpty) {
                keypoints += prevKeypoints
                
                prevKeypointLocation = prevKeypoints.last!.location
                prevKeypointOrientation = prevKeypoints.last!.orientation
            }
            
            let prevKeypoint = KeypointInfo(location: prevKeypointLocation, orientation: prevKeypointOrientation)
            
            let newKeypointLocation = edibleCrumbs[maxIndex!]
            let newKeypointOrientation = Vector3(_: [prevKeypoint.location.x - newKeypointLocation.x,
                                                     0,
                                                     prevKeypoint.location.z - newKeypointLocation.z]).normalized()
            
            
            keypoints.append(KeypointInfo(location: newKeypointLocation, orientation: newKeypointOrientation))
            
            if (!postKeypoints.isEmpty) {
                keypoints += postKeypoints
            }
        }
        
        return keypoints
    }
    
}


