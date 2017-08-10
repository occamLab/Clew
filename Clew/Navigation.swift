//
//  Navigation.swift
//  ARKitTest
//
//  Created by Chris Seonghwan Yoon & Jeremy Ryan on 7/11/17.
//
//  Navigation class that provides direction information given 2 LocationInfo position
//
import Foundation

public enum PositionState {
    case notAtTarget
    case atTarget
    case closeToTarget
}

public struct DirectionInfo {
    //  Struct for storing relative position of keypoint to user
    public var distance: Float
    public var clockDirection: Int
    public var hapticDirection: Int
    public var targetState = PositionState.notAtTarget
    
    public init(distance: Float, clockDirection: Int, hapticDirection: Int) {
        self.distance = distance
        self.clockDirection = clockDirection
        self.hapticDirection = hapticDirection
    }
}

public let CLockDirections = [12: "Continue straight",
                              1: "Slight right towards 1 o'clock",
                              2: "Slight right towards 2 o'clock",
                              3: "Turn right",
                              4: "Turn towards 4 o'clock",
                              5: "Turn around towards 5 o'clock",
                              6: "Turn around towards 6 o'clock",
                              7: "Turn around towards 7 o'clock",
                              8: "Turn towards 8 o'clock",
                              9: "Turn left",
                              10: "Slight left towards 10 o'clock",
                              11: "Slight left towards 11 o'clock"]

public let HapticDirections = [1: "Continue straight",
                               2: "Slight right",
                               3: "Turn right",
                               4: "Turn around",
                               5: "Turn left",
                               6: "Slight Left",
                               0: "ERROR"]

public let TurnWarnings = [12: "Continue straight ahead",
                           1: "Slight right ahead",
                           2: "Slight right ahead",
                           3: "Right turn ahead",
                           4: "Right turn ahead",
                           5: "",
                           6: "",
                           7: "",
                           8: "Left turn ahead",
                           9: "Left turn ahead",
                           10: "Slight left ahead",
                           11: "Slight left ahead"]

//  Keypoint target dimensions
//  Further instructions will be given to the user once they pass inside
//  this bounding box
public var targetWidth: Scalar = 2
public var targetDepth: Scalar = 0.5
public var targetHeight: Scalar = 3

class Navigation {
    public func getTurnWarningDirections(_ currentLocation: CurrentCoordinateInfo,
                                         curKeypoint: KeypointInfo,
                                         nextKeypoint: KeypointInfo) -> DirectionInfo {
        
        let curKeypointDisplacementX = curKeypoint.location.x - currentLocation.location.x
        let curKeypointDisplacementZ = curKeypoint.location.z - currentLocation.location.z
        var adjustedNextKeypoint = nextKeypoint
        adjustedNextKeypoint.location.x = nextKeypoint.location.x - curKeypointDisplacementX
        adjustedNextKeypoint.location.z = nextKeypoint.location.z - curKeypointDisplacementZ
        
        return getDirections(currentLocation: currentLocation, nextKeypoint: adjustedNextKeypoint)
    }
    
    public func getDirections(currentLocation: CurrentCoordinateInfo, nextKeypoint: KeypointInfo) -> DirectionInfo {
        //  Given the iPhone's current position in odometry and the position of
        //  the next keypoint, returns a DirectionsInfo object about their
        //  relative position.
        //  Transform a unit vector to be pointing upward from the top of the
        //  phone and outward from the front of the phone.
        let zVector = Vector3.z * currentLocation.transformMatrix
        let yVector = Vector3.x * currentLocation.transformMatrix
        var trueVector: Vector3!
        
        //  The vector with the lesser vertical component is more flat, so has
        //  a more accurate direction. If the phone is more flat than 45 degrees
        //  the upward vector is used for phone direction; if it is more upright
        //  the outward vector is used.
        if (abs(zVector.y) < abs(yVector.y)) {
            trueVector = zVector * Matrix3([1, 0, 0, 0, 0, 0, 0, 0, 1])
        } else {
            trueVector = yVector * Matrix3([1, 0, 0, 0, 0, 0, 0, 0, 1])
        }
        let trueYaw = atan2f(trueVector.x, trueVector.z)
        
        //  Distance to next keypoint in meters
        let dist = sqrtf(powf((currentLocation.location.x - nextKeypoint.location.x), 2) +
            powf((currentLocation.location.z - nextKeypoint.location.z), 2))
        
        let angle = atan2f((currentLocation.location.x - nextKeypoint.location.x), (currentLocation.location.z-nextKeypoint.location.z))
        
        let angleDiff = getAngleDiff(angle1: trueYaw, angle2: angle)
        
        let hapticDirection = getHapticDirectionIdx(angle: angleDiff)
        let clockDirection = getClockDirections(angle: angleDiff)
        
        //  Determine the difference in position between the phone and the next
        //  keypoint in the frame of the keypoint.
        let xDiff = Vector3([currentLocation.location.x - nextKeypoint.location.x,
                             currentLocation.location.y - nextKeypoint.location.y,
                             currentLocation.location.z - nextKeypoint.location.z]).dot(nextKeypoint.orientation)
        let yDiff = Vector3([currentLocation.location.x - nextKeypoint.location.x,
                             currentLocation.location.y - nextKeypoint.location.y,
                             currentLocation.location.z - nextKeypoint.location.z]).dot(Vector3.y)
        let zDiff = Vector3([currentLocation.location.x - nextKeypoint.location.x,
                             currentLocation.location.y - nextKeypoint.location.y,
                             currentLocation.location.z - nextKeypoint.location.z]).dot(nextKeypoint.orientation.cross(Vector3.y))
        
        var direction = DirectionInfo(distance: dist, clockDirection: clockDirection, hapticDirection: hapticDirection)
        
        //  Determine whether the phone is inside the bounding box of the keypoint
        if (xDiff <= targetDepth && yDiff <= targetHeight && zDiff <= targetWidth) {
            direction.targetState = .atTarget
        } else if (sqrtf(powf(Float(xDiff), 2) + powf(Float(zDiff), 2)) <= 4) {
            direction.targetState = .closeToTarget
        } else {
            direction.targetState = .notAtTarget
        }
        
        return direction
    }
    
    private func getHapticDirectionIdx(angle: Float) -> Int {
        if (-Float.pi/6 <= angle && angle <= Float.pi/6) {
            return 1
        } else if (Float.pi/6 <= angle && angle <= Float.pi/3) {
            return 2
        } else if (Float.pi/3 <= angle && angle <= (2*Float.pi/3)) {
            return 3
        } else if ((2*Float.pi/3) <= angle && angle <= Float.pi) {
            return 4
        } else if (-Float.pi <= angle && angle <= -(2*Float.pi/3)) {
            return 4
        } else if (-(2*Float.pi/3) <= angle && angle <= -(Float.pi/3)) {
            return 5
        } else if (-Float.pi/3 <= angle && angle <= -Float.pi/6) {
            return 6
        } else {
            return 0
        }
    }
    
    private func getClockDirections(angle: Float) -> Int {
        //  Determine clock direction, from 1-12, based on angle in radians,
        //  where 0 radians is 12 o'clock.
        let a = (angle * (6/Float.pi)) + 12.5
        
        let clockDir = Int(a) % 12
        return clockDir == 0 ? 12 : clockDir
    }
    
    private func getAngleDiff(angle1: Float, angle2: Float) -> Float {
        //  Function to determine the difference between two angles
        let a = angleNormalize(angle: angle1)
        let b = angleNormalize(angle: angle2)
        
        let d1 = a-b
        var d2 = 2*Float.pi - abs(d1)
        if (d1 > 0) {
            d2 = d2 * (-1)
        }
        return abs(d1) < abs(d2) ? d1 : d2
    }
    
    private func angleNormalize(angle: Float) -> Float {
        return atan2f(sinf(angle), cosf(angle))
    }
    
    private func roundToTenths(n: Float) -> Float {
        return roundf(10 * n)/10
    }
}


