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
/// TODO: this is a bit confusing as to what the transformMatrix does that the transform stored with `location` doesn't do.
public struct CurrentCoordinateInfo {
    /// the location of the coordinate info
    public var location: LocationInfo
    /// the 3x3 transform matrix
    public var transformMatrix: Matrix3 = Matrix3.identity
    
    /// Initialize a `CurrentCoordinateInfoObject`
    ///
    /// - Parameters:
    ///   - location: the location to use
    ///   - transMatrix: the transformation matrix to use
    public init(_ location: LocationInfo, transMatrix: Matrix3) {
        self.location = location
        self.transformMatrix = transMatrix
    }
    
    /// Initialize a `CurrentCoordinatedInfoObject`.  This assumes the identity matrix as the transform.
    ///
    /// - Parameter location: the location to use
    public init(_ location: LocationInfo) {
        self.location = location
    }
}

/// Struct to store position information and yaw.  By sub-classing `ARAnchor`, we get specify the 6-DOFs of an ARAnchor while getting the ability to support the secure coding protocol for free.
public class LocationInfo : ARAnchor {
    
    /// This initializes a new `LocationInfo` object based on the specified `ARAnchor`.
    ///
    /// - Parameter anchor: the `ARAnchor` to use for describing the location
    required init(anchor: ARAnchor) {
        self.routeAnchorPoint = RouteAnchorPoint()
        self.whichConstruct = 1
        super.init(anchor: anchor)
    }
    
    /// This initializes a new `LocationInfo` object based on the specified transform.
    ///
    /// TODO: I think we might be able to delete this since all it does is call the super class method.
    /// - Parameter transform: the transform (4x4 matrix) describing the location
    override init(transform: simd_float4x4) {
        self.routeAnchorPoint = RouteAnchorPoint()
        self.whichConstruct = 2
        super.init(transform: transform)
    }
    
    init(frameTransform: simd_float4x4, frameIntrinsics: simd_float4, frameImage: UIImage?) {
        self.routeAnchorPoint = RouteAnchorPoint()
        self.routeAnchorPoint.image = frameImage
        self.routeAnchorPoint.intrinsics = frameIntrinsics
        self.routeAnchorPoint.transform = frameTransform
        self.whichConstruct = 3
        super.init(transform: frameTransform)
    }
    
    /// indicates whether secure coding is supported (it is)
    override public class var supportsSecureCoding: Bool {
        return true
    }

    /// The function required by NSSecureCoding protocol to decode the object
    ///
    /// - Parameter aDecoder: the NSCoder doing the decoding
    required init?(coder aDecoder: NSCoder) {
        if let decodedRouteAnchorPoint = aDecoder.decodeObject(of: RouteAnchorPoint.self, forKey: "routeAnchorPoint") {
            self.routeAnchorPoint = decodedRouteAnchorPoint
        } else {
            self.routeAnchorPoint = RouteAnchorPoint()
            self.routeAnchorPoint.image = nil
            self.routeAnchorPoint.intrinsics = nil
            self.routeAnchorPoint.transform = nil
        }
        self.whichConstruct = 4
        super.init(coder: aDecoder)
    }
    
    /// The function required by NSSecureCoding protocol to encode the object
    /// TODO: I think we might be able to delete this since all it does is call the super class method.
    ///
    /// - Parameter aCoder: the NSCoder doing the encoding
    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(routeAnchorPoint, forKey: "routeAnchorPoint")
    }
    
    public var routeAnchorPoint: RouteAnchorPoint
    public var whichConstruct: Int
    
    public override var description: String {
        return "LocationInfo { RouteAnchorPoint: \(self.routeAnchorPoint), Transform: \(self.transform), WhichConstruct: \(self.whichConstruct)"
    }
    
    /// the translation expressed as a 3-element vector (x, y, z)
    public var translation: Vector3 {
        let translation = self.transform.columns.3
        return Vector3(translation.x, translation.y, translation.z)
    }
    
    /// the Euler angles as a 3 element vector (pitch, yaw, roll)
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
            if abs(sinp) >= 1 {
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

    /// the x translation
    public var x: Float {
        return translation.x
    }
    
    /// the y translation
    public var y: Float {
        return translation.y
    }
    
    /// the z translation
    public var z: Float {
        return translation.z
    }
    
    /// the yaw (in radians)
    public var yaw: Float {
        return eulerAngles.y
    }
}


/// Struct to store position and orientation of a keypoint
///
/// Contains:
/// * `location` (`LocationInfo`)
/// * `orientation` (`Vector3` from `VectorMath`)
public struct KeypointInfo {
    /// the location of the keypoint
    public var location: LocationInfo
    /// the orientation of a keypoint is a unit vector that points from the previous keypoint to current keypoint.  The orientation is useful for defining the area where we check off the user as having reached a keypoint
    public var orientation: Vector3 {
        if let currentKeypointLocation = ARSessionManager.shared.getCurrentLocation(of: location), let previousKeypoint = RouteManager.shared.getPreviousKeypoint(to: self), let prevKeypointLocation = ARSessionManager.shared.getCurrentLocation(of: previousKeypoint.location) {
            return Vector3(_: [prevKeypointLocation.x - currentKeypointLocation.x,
                                                 0,
                               prevKeypointLocation.z - currentKeypointLocation.z]).normalized()
        } else {
            return Vector3.x
        }
    }
}

/// An encapsulation of a route Anchor Point, including position, text, and audio information.
public class RouteAnchorPoint: NSObject, NSSecureCoding {
    /// Needs to be declared and assigned true to support `NSSecureCoding`
    public static var supportsSecureCoding = true
    
    /// The position and orientation encoded as an ARAnchor
    public var anchor: ARAnchor?
    /// Text to help user remember the Anchor Point
    public var information: NSString?
    /// The URL to an audio file that contains information to help the user remember a Anchor Point
    public var voiceNote: NSString?
    /// The image associated with the anchor point
    public var imageFileName: NSString?
    public var image: UIImage?
    /// The intrinsics used to take the anchor point image
    public var intrinsics: simd_float4?
    /// The position and orientation as a 4x4 matrix
    public var transform: simd_float4x4?
    private var thumbnailCache: [CGFloat: UIImage] = [:]
    
    public override var description: String {
        return "RouteAnchorPoint { Image: \(String(describing: self.image)), Intrinsics \(self.intrinsics), Transform: \(self.transform)"
    }
    
    /// Initialize the Anchor Point.
    ///
    /// - Parameters:
    ///   - transform: the position and orientation
    ///   - information: textual description
    ///   - voiceNote: URL to auditory description
    public init(anchor: ARAnchor? = nil, information: NSString? = nil, voiceNote: NSString? = nil, imageFileName: NSString? = nil, intrinsics: simd_float4? = nil, transform: simd_float4x4? = nil) {
        self.anchor = anchor
        self.information = information
        self.voiceNote = voiceNote
        self.imageFileName = imageFileName
        self.intrinsics = intrinsics
    }
    
    /// Encode the Anchor Point.
    ///
    /// - Parameter aCoder: the encoder
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(anchor, forKey: "anchor")
        aCoder.encode(information, forKey: "information")
        aCoder.encode(voiceNote, forKey: "voiceNote")
        if imageFileName != nil {
            aCoder.encode(imageFileName, forKey: "image")
        }
        
        if let intrinsics = intrinsics {
            aCoder.encode([intrinsics.x, intrinsics.y, intrinsics.z, intrinsics.w], forKey: "intrinsics")
        }
    }
    
    /// Used to load the anchor point image when it is needed, given the imaguURL is non-nil
    func loadImage() {
        guard let imageFileName = imageFileName else {
            print("Could not find url to load route anchor point image from")
            return
        }
        self.image = UIImage(contentsOfFile: imageFileName.documentURL.path)
    }
    
    /// Decode the Anchor Point.
    ///
    /// - Parameter aDecoder: the decoder
    required convenience public init?(coder aDecoder: NSCoder) {
        var anchor : ARAnchor? = nil
        var information : NSString? = nil
        var voiceNote : NSString? = nil
        var imageFileName : NSString?
        var intrinsics : simd_float4?
        
        if let transformAsARAnchor = aDecoder.decodeObject(of: ARAnchor.self, forKey: "transformAsARAnchor") {
            anchor = transformAsARAnchor
        } else {
            anchor = aDecoder.decodeObject(of: ARAnchor.self, forKey: "anchor")
        }
        information = aDecoder.decodeObject(of: NSString.self, forKey: "information")
        voiceNote = aDecoder.decodeObject(of: NSString.self, forKey: "voiceNote")
        imageFileName = aDecoder.decodeObject(of: NSString.self, forKey: "image")
        
        if let intrinsicsArray = aDecoder.decodeObject(forKey: "intrinsics") as? [Float] {
            intrinsics = simd_float4(intrinsicsArray[0], intrinsicsArray[1], intrinsicsArray[2], intrinsicsArray[3])
        }
        self.init(anchor: anchor, information: information, voiceNote: voiceNote, imageFileName: imageFileName, intrinsics: intrinsics)
    }
    
    func getThumbnail(imageHeight: CGFloat = 100)->UIImage? {
        guard let image = image else {
            return nil
        }
        if let cached = thumbnailCache[imageHeight] {
            return cached
        }
        let imageWidth = image.size.width * imageHeight / image.size.height
        let imageThumbnail = image.imageWithSize(scaledToSize: CGSize(width: imageWidth, height: imageHeight))
        thumbnailCache[imageHeight] = imageThumbnail.rotate(radians: Float.pi/2)?.withRenderingMode(.alwaysOriginal)
        return thumbnailCache[imageHeight]
    }
}

/// [Deprecated] [Needed to load old routes] An encapsulation of a route landmark, including position, text, and audio information.
class RouteLandmark: NSObject, NSSecureCoding {
    /// Needs to be declared and assigned true to support `NSSecureCoding`
    static var supportsSecureCoding = true
    
    /// The position and orientation as a 4x4 matrix
    public var transform: simd_float4x4?
    /// Text to help user remember the landmark
    public var information: NSString?
    /// The URL to an audio file that contains information to help the user remember a landmark
    public var voiceNote: NSString?
    
    /// Initialize the landmark.
    ///
    /// - Parameters:
    ///   - transform: the position and orientation
    ///   - information: textual description
    ///   - voiceNote: URL to auditory description
    public init(transform: simd_float4x4? = nil, information: NSString? = nil, voiceNote: NSString? = nil) {
        self.transform = transform
        self.information = information
        self.voiceNote = voiceNote
    }
    
    /// Encode the landmark.
    ///
    /// - Parameter aCoder: the encoder
    func encode(with aCoder: NSCoder) {
        if transform != nil {
            aCoder.encode(ARAnchor(transform: transform!), forKey: "transformAsARAnchor")
        }
        aCoder.encode(information, forKey: "information")
        aCoder.encode(voiceNote, forKey: "voiceNote")
    }
    
    /// Decode the landmark.
    ///
    /// - Parameter aDecoder: the decoder
    required convenience init?(coder aDecoder: NSCoder) {
        var transform : simd_float4x4? = nil
        var information : NSString? = nil
        var voiceNote : NSString? = nil
        
        if let transformAsARAnchor = aDecoder.decodeObject(of: ARAnchor.self, forKey: "transformAsARAnchor") {
            transform = transformAsARAnchor.transform
        }
        information = aDecoder.decodeObject(of: NSString.self, forKey: "information")
        voiceNote = aDecoder.decodeObject(of: NSString.self, forKey: "voiceNote")
        self.init(transform: transform, information: information, voiceNote: voiceNote)
    }
}
/// This class encapsulates a route that can be persisted to storage and reloaded as needed.
class SavedRoute: NSObject, NSSecureCoding {
    /// This is needed to use NSSecureCoding
    static var supportsSecureCoding = true
    
    /// The id of the route (should be unique)
    public var id: NSString
    /// The name of the route (as displayed by the `RoutesViewController`)
    public var name: NSString
    /// The date the route was recorded
    public var dateCreated: NSDate
    /// The crumbs that make up the route.  The densely sampled positions (crumbs) are stored and the keypoints (sparser goal positionsare calculated on demand when navigation is requested.
    public var crumbs: [LocationInfo]
    /// The Anchor Point marks the beginning of the route (needed for start to end navigation)
    public var beginRouteAnchorPoint : RouteAnchorPoint
    /// The Anchor Point marks the end of the route (needed for end to start navigation)
    public var endRouteAnchorPoint: RouteAnchorPoint
    /// The Anchor Points used for recording voice notes and other information along the route
    public var intermediateAnchorPoints: [RouteAnchorPoint]

    /// Initialize the route.
    ///
    /// - Parameters:
    ///   - id: the route id
    ///   - name: the route name
    ///   - crumbs: the crumbs for the route
    ///   - dateCreated: the route creation date
    ///   - beginRouteAnchorPoint: the Anchor Point for the beginning of the route (pass a `RouteAnchorPoint` with default initialization if no Anchor Point was recorded at the beginning of the route)
    ///   - endRouteAnchorPoint: the Anchor Point for the end of the route (pass a `RouteAnchorPoint` with default initialization if no Anchor Point was recorded at the end of the route)
    public init(id: NSString, name: NSString, crumbs: [LocationInfo], dateCreated: NSDate = NSDate(), beginRouteAnchorPoint: RouteAnchorPoint, endRouteAnchorPoint: RouteAnchorPoint, intermediateAnchorPoints: [RouteAnchorPoint]) {
        self.id = id
        self.name = name
        self.crumbs = crumbs
        self.dateCreated = dateCreated
        self.beginRouteAnchorPoint = beginRouteAnchorPoint
        self.endRouteAnchorPoint = endRouteAnchorPoint
        self.intermediateAnchorPoints = intermediateAnchorPoints
    }
    
    /// Encodes the object to the specified coder object
    ///
    /// - Parameter aCoder: the object used for encoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(crumbs, forKey: "crumbs")
        aCoder.encode(dateCreated, forKey: "dateCreated")
        aCoder.encode(beginRouteAnchorPoint, forKey: "beginRouteAnchorPoint")
        aCoder.encode(endRouteAnchorPoint, forKey: "endRouteAnchorPoint")
        aCoder.encode(intermediateAnchorPoints, forKey: "intermediateAnchorPoints")
    }
    
    /// Initialize an object based using data from a decoder
    ///
    /// - Parameter aDecoder: the decoder object
    required convenience init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(of: NSString.self, forKey: "id") else {
            return nil
        }
        guard let name = aDecoder.decodeObject(of: NSString.self, forKey: "name") else {
            return nil
        }
        guard let crumbs = aDecoder.decodeObject(of: [].self, forKey: "crumbs") as? [LocationInfo] else {
            return nil
        }
        guard let dateCreated = aDecoder.decodeObject(of: NSDate.self, forKey: "dateCreated") else {
            return nil
        }

        let beginRouteAnchorPoint: RouteAnchorPoint
        if let anchorPoint = aDecoder.decodeObject(of: RouteAnchorPoint.self, forKey: "beginRouteAnchorPoint") {
            beginRouteAnchorPoint = anchorPoint
        } else {
            // check to see if we have a route in the old format
            guard let beginRouteLandmark = aDecoder.decodeObject(of: RouteLandmark.self, forKey: "beginRouteLandmark"), let landmarkTransform = beginRouteLandmark.transform else {
                    return nil
            }
            // convert to the new format
            beginRouteAnchorPoint = RouteAnchorPoint(anchor: ARAnchor(transform: landmarkTransform), information: beginRouteLandmark.information, voiceNote: beginRouteLandmark.voiceNote)
        }
        let endRouteAnchorPoint: RouteAnchorPoint

        if let anchorPoint = aDecoder.decodeObject(of: RouteAnchorPoint.self, forKey: "endRouteAnchorPoint") {
            endRouteAnchorPoint = anchorPoint
        } else {
            // check to see if we have a route in the old format
            guard let endRouteLandmark = aDecoder.decodeObject(of: RouteLandmark.self, forKey: "endRouteLandmark"), let landmarkTransform = endRouteLandmark.transform else {
                return nil
            }
            // convert to the new format
            endRouteAnchorPoint = RouteAnchorPoint(anchor: ARAnchor(transform: landmarkTransform), information: endRouteLandmark.information, voiceNote: endRouteLandmark.voiceNote)
        }
        
        var intermediateRouteAnchorPoints: [RouteAnchorPoint] = []
        if let anchorPoints = aDecoder.decodeObject(of: [].self, forKey: "intermediateAnchorPoints") as? [RouteAnchorPoint] {
            intermediateRouteAnchorPoints = anchorPoints
        }
        self.init(id: id, name: name, crumbs: crumbs, dateCreated: dateCreated, beginRouteAnchorPoint: beginRouteAnchorPoint, endRouteAnchorPoint: endRouteAnchorPoint, intermediateAnchorPoints: intermediateRouteAnchorPoints)
    }
}

/// Pathfinder class calculates turns or "keypoints" given a path array of LocationInfo
class PathFinder {
    
    ///  Maximum width of the breadcrumb path in meters.
    ///
    /// Points falling outside this margin will produce more keypoints, through Ramer-Douglas-Peucker algorithm
    private let pathWidth: Scalar!
    
    /// The crumbs that make up the desired path. These should be ordered with respect to the user's intended direction of travel (start to end versus end to start)
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
        keypoints.append(KeypointInfo(location: firstKeypointLocation))
        
        keypoints += calculateKeypoints(edibleCrumbs: edibleCrumbs)
        
        let lastKeypointLocation = edibleCrumbs.last!
        keypoints.append(KeypointInfo(location: lastKeypointLocation))
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
        let maxIndex = listOfDistances.firstIndex(of: maxDistance!)
        
        //  If a point is farther from path center than parameter pathWidth,
        //  there must be another keypoint within that stretch.
        if (maxDistance! > pathWidth) {
            
            //  Recursively find all keypoints before the detected keypoint and
            //  after the detected keypoint, and add them in a list with the
            //  detected keypoint.
            let prevKeypoints = calculateKeypoints(edibleCrumbs: Array(edibleCrumbs[0..<(maxIndex!+1)]))
            let postKeypoints = calculateKeypoints(edibleCrumbs: Array(edibleCrumbs[maxIndex!...]))
            
            if (!prevKeypoints.isEmpty) {
                keypoints += prevKeypoints
            }
                        
            let newKeypointLocation = edibleCrumbs[maxIndex!]
            keypoints.append(KeypointInfo(location: newKeypointLocation))
            
            if (!postKeypoints.isEmpty) {
                keypoints += postKeypoints
            }
        }
        
        return keypoints
    }
    
}
