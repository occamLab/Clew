//
//  Navigation.swift
//  ARKitTest
//
//  Created by Chris Seonghwan Yoon & Jeremy Ryan on 7/11/17.
//
//  Navigation class that provides direction information given 2 LocationInfo position
//

import Foundation
import VectorMath

/// Not sure of description yet
///
/// - notAtTarget
/// - atTarget
/// - closeToTarget
///
/// - TODO: Clarify what this is
public enum PositionState {
    /// user is far from target
    case notAtTarget
    /// user is at target
    case atTarget
    /// user is close to the target
    case closeToTarget
}

/// Struct for storing relative position of keypoint to user
///
/// Contains:
/// * `distance` (`Float`): distance in meters to keypoint
/// * `angleDiff` (`Float`): angle in radians to next keypoint
/// * `clockDirection` (`Int`): description of angle to keypoint in clock position where straight forward is 12
/// * `hapticDirection` (`Int`): description of angle to keypoint to use when haptic feedback is turned on.
/// * `targetState` (case of enum `PositionState`): the state (at, near, or away from target) of the position relative to the keypoint
public struct DirectionInfo {
    /// the distance in meters to keypoint
    public var distance: Float
    /// the ratio of lateral distance to the keypoint when the user passes it if they continue along their current heading versus the maximum allowable
    public var lateralDistanceRatioWhenCrossingTarget: Float
    /// the angle in radians (yaw) to the next keypoint
    public var angleDiff: Float
    /// the description of angle to keypoint in clock position where straight forward is 12
    public var clockDirection: Int
    /// the description of angle to keypoint to use when haptic feedback is turned on.
    public var hapticDirection: Int
    /// the state (at, near, or away from target) of the position relative to the keypoint
    public var targetState = PositionState.notAtTarget
    
    /// Initialize a DirectionInfo object
    ///
    /// - Parameters:
    ///   - distance: the distance to the next keypoint
    ///   - angleDiff: the angle (yaw) to the next keypoint
    ///   - clockDirection: the clock direction to the next keypoint
    ///   - hapticDirection: the state (at, near, or away from target) of the position relative to the keypoint
    public init(distance: Float, angleDiff: Float, clockDirection: Int, hapticDirection: Int, lateralDistanceRatioWhenCrossingTarget: Float) {
        self.distance = distance
        self.angleDiff = angleDiff
        self.clockDirection = clockDirection
        self.hapticDirection = hapticDirection
        self.lateralDistanceRatioWhenCrossingTarget = lateralDistanceRatioWhenCrossingTarget
    }
}

/// Dictionary of clock positions
///
/// * Keys (`Int` from 1 to 12 inclusive): clock position
/// * Values (`String`): corresponding spoken direction (e.g. "Slight right towards 2 o'clock")
public let ClockDirections = [
                              12: NSLocalizedString("straightDirection", comment: "Direction to user to continue moving in forward direction"),
                              1: NSLocalizedString("1o'clockDirection", comment: "direction to the user to turn towards the 1 o'clock direction"),
                              2: NSLocalizedString("2o'clockDirection", comment: "direction to the user to turn towards the 2 o'clock direction"),
                              3: NSLocalizedString("rightDirection", comment: "Direction to the user to make an approximately 90 degree right turn."),
                              4: NSLocalizedString("4o'clockDirection", comment: "direction to the user to turn towards the 4 o'clock direction"),
                              5: NSLocalizedString("5o'clockDirection", comment: "direction to the user to turn towards the 5 o'clock direction"),
                              6: NSLocalizedString("6o'clockDirection", comment: "direction to the user to turn towards the 6 o'clock direction"),
                              7: NSLocalizedString("7o'clockDirection", comment: "direction to the user to turn towards the 7 o'clock direction"),
                              8: NSLocalizedString("8o'clockDirection", comment: "direction to the user to turn towards the 8 o'clock direction"),
                              9: NSLocalizedString("leftDirection", comment: "Direction to the user to make an approximately 90 degree left turn."),
                              10: NSLocalizedString("10o'clockDirection", comment: "direction to the user to turn towards the 10 o'clock direction"),
                              11: NSLocalizedString("11o'clockDirection", comment: "direction to the user to turn towards the 11 o'clock direction")
                             ]

/// Dictionary of directions, somehow based on haptic feedback.
///
/// * Keys (`Int` from 0 to 6 inclusive): encoding of haptic feedback
/// * Values (`String`): corresponding spoken direction (e.g. "Slight right")
///
/// - TODO:
///  - Explain the rationale of this division
///  - Consider restructuring this
public let HapticDirections = [
                               1: NSLocalizedString("straightDirection", comment: "Direction to user to continue moving in forward direction"),
                               2: NSLocalizedString("slightRightDirection", comment: "Direction to user to take a slight right turn"),
                               3: NSLocalizedString("rightDirection", comment: "Direction to the user to make an approximately 90 degree right turn."),
                               4: NSLocalizedString("uTurnDirection", comment: "Direction to the user to turn around"),
                               5: NSLocalizedString("leftDirection", comment: "Direction to the user to make an approximately 90 degree left turn."),
                               6: NSLocalizedString("slightLeftDirection", comment: "Direction to user to take a slight left turn"),
                               0: "ERROR"
                              ]

/// Navigation class that provides direction information given 2 LocationInfo position
class Navigation {
    
    /// Keypoint target dimension (width) in meters
    ///
    /// Further instructions will be given to the user once they pass inside this bounding box
    public var targetWidth: Scalar = 2
    
    /// Keypoint target dimension (depth) in meters
    ///
    /// Further instructions will be given to the user once they pass inside this bounding box
    public var targetDepth: Scalar = 0.5
    
    /// Keypoint target dimension (height) in meters
    ///
    /// Further instructions will be given to the user once they pass inside this bounding box
    public var targetHeight: Scalar = 3
    
    /// Keypoint target dimension (width) in meters
    ///
    /// Further instructions will be given to the user once they pass inside this bounding box
    public var lastKeypointTargetWidth: Scalar = 1
    
    /// Keypoint target dimension (depth) in meters
    ///
    /// Further instructions will be given to the user once they pass inside this bounding box
    public var lastKeypointTargetDepth: Scalar = 1
    
    /// Keypoint target dimension (height) in meters
    ///
    /// Further instructions will be given to the user once they pass inside this bounding box
    public var lastKeypointTargetHeight: Scalar = 3
    
    /// The offset between the user's direction of travel (assumed to be aligned with the front of their body and the phone's orientation)
    var headingOffset: Float?
    
    /// control whether to apply the heading offset or not
    public var useHeadingOffset = false
    
    /// Get the heading for the phone suitable for computing directions to the next waypoint.
    ///
    /// The phone's direction is either the projection of its z-axis on the floor plane (x-z plane), or if the phone is lying flatter than 45 degrees, it is the projection of the phone's y-axis.
    /// - Parameter currentLocation: the phone's location
    /// - Returns: the phone's yaw that is used for computation of directions
    public func getPhoneHeadingYaw(currentLocation: CurrentCoordinateInfo)->Float {
        let zVector = Vector3.z * currentLocation.transformMatrix
        let yVector = Vector3.x * currentLocation.transformMatrix
        //  The vector with the lesser vertical component is more flat, so has
        //  a more accurate direction. If the phone is more flat than 45 degrees
        //  the upward vector is used for phone direction; if it is more upright
        //  the outward vector is used.
        var trueVector: Vector3!
        if (abs(zVector.y) < abs(yVector.y)) {
            trueVector = zVector * Matrix3([1, 0, 0, 0, 0, 0, 0, 0, 1])
        } else {
            trueVector = yVector * Matrix3([1, 0, 0, 0, 0, 0, 0, 0, 1])
        }
        return atan2f(trueVector.x, trueVector.z)
    }
    
    /// Determines position of the next keypoint relative to the iPhone's current position.
    ///
    /// - Parameters:
    ///   - currentLocation
    ///   - nextKeypoint
    ///   - isLastKeypoint (true if the keypoint is the last one in the route, false otherwise)
    /// - Returns: relative position of next keypoint as `DirectionInfo` object
    public func getDirections(currentLocation: CurrentCoordinateInfo, nextKeypoint: KeypointInfo, isLastKeypoint: Bool) -> DirectionInfo {
        // these tolerances are set depending on whether it is the last keypoint or not
        let keypointTargetDepth = isLastKeypoint ? lastKeypointTargetDepth : targetDepth
        let keypointTargetHeight = isLastKeypoint ? lastKeypointTargetHeight : targetHeight
        let keypointTargetWidth = isLastKeypoint ? lastKeypointTargetWidth : targetWidth

        let trueYaw  = getPhoneHeadingYaw(currentLocation: currentLocation) + (useHeadingOffset && headingOffset != nil ? headingOffset! : Float(0.0))
        // planar heading vector
        let planarHeading = Vector3([sin(trueYaw), 0, cos(trueYaw)])
        let delta = currentLocation.location.translation - nextKeypoint.location.translation
        let planarDelta = Vector3(delta.x, 0, delta.z)
        let headingProjectedOntoKeypointXDirection = nextKeypoint.orientation.dot(planarHeading)
        
        // Finds angle from "forward"-looking towards the next keypoint in radians. Not sure which direction is negative vs. positive for now.
        let angle = atan2f((currentLocation.location.x - nextKeypoint.location.x), (currentLocation.location.z-nextKeypoint.location.z))
        
        let angleDiff = getAngleDiff(angle1: trueYaw, angle2: angle)
        
        let hapticDirection = getHapticDirection(angle: angleDiff)
        let clockDirection = getClockDirection(angle: angleDiff)
        
        //  Determine the difference in position between the phone and the next
        //  keypoint in the frame of the keypoint.
        let xDiff = delta.dot(nextKeypoint.orientation)
        let yDiff = delta.dot(Vector3.y)
        let zDiff = delta.dot(nextKeypoint.orientation.cross(Vector3.y))
        
        let lateralDistanceRatioWhenCrossingTarget : Float
        if headingProjectedOntoKeypointXDirection <= 0 {
            lateralDistanceRatioWhenCrossingTarget = Float.infinity
        } else {
            lateralDistanceRatioWhenCrossingTarget = (-planarHeading*delta.dot(nextKeypoint.orientation)/headingProjectedOntoKeypointXDirection + currentLocation.location.translation - nextKeypoint.location.translation).length / keypointTargetWidth
        }
        
        var direction = DirectionInfo(distance: planarDelta.length, angleDiff: angleDiff, clockDirection: clockDirection, hapticDirection: hapticDirection, lateralDistanceRatioWhenCrossingTarget: lateralDistanceRatioWhenCrossingTarget)
        
        //  Determine whether the phone is inside the bounding box of the keypoint
        if (xDiff <= keypointTargetDepth && yDiff <= keypointTargetHeight && zDiff <= keypointTargetWidth) {
            direction.targetState = .atTarget
        } else if (sqrtf(powf(Float(xDiff), 2) + powf(Float(zDiff), 2)) <= 4) {
            direction.targetState = .closeToTarget
        } else {
            direction.targetState = .notAtTarget
        }
        
        return direction
    }
    
    /// Divides all possible directional angles into six sections for using with haptic feedback.
    ///
    /// - Parameter angle: angle in radians from straight ahead.
    /// - Returns: `Int` from 0 to 6 inclusive, starting with 1 facing straight forward and continuing clockwise. 0 represents no angle.
    ///
    /// - SeeAlso: `HapticDirections`
    ///
    /// - TODO:
    ///    - potentially rethink this assignment to ints and dictionary.
    ///    - consider making return optional or throw an error rather than returning 0.
    private func getHapticDirection(angle: Float) -> Int {
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
    
    /// Determine clock direction from angle in radians, where 0 radians is 12 o'clock.
    ///
    /// - Parameter angle: input angle to be converted, in radians
    /// - Returns: `Int` between 1 and 12, inclusive, representing clock position
    ///
    /// - SeeAlso: `ClockDirections`
    private func getClockDirection(angle: Float) -> Int {
        //  Determine clock direction, from 1-12, based on angle in radians,
        //  where 0 radians is 12 o'clock.
        let a = (angle * (6/Float.pi)) + 12.5
        
        let clockDir = Int(a) % 12
        return clockDir == 0 ? 12 : clockDir
    }
    
    /// Determines the difference between two angles, in radians
    ///
    /// - Parameters:
    ///   - angle1: the first angle
    ///   - angle2: the second angle
    /// - Returns: the difference between the two angles
    func getAngleDiff(angle1: Float, angle2: Float) -> Float {
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
    
    /// Normalizes an angle in radians to be between -pi and pi
    ///
    /// - Parameter angle: an angle in radians
    /// - Returns: the angle mapped to between -pi and pi
    private func angleNormalize(angle: Float) -> Float {
        return atan2f(sinf(angle), cosf(angle))
    }
    
    /// Computes the average between two angles (accounting for wraparound)
    ///
    /// - Parameters:
    ///   - a: one of the two angles
    ///   - b: the other angle
    /// - Returns: the average fo the angles
    func averageAngle(a: Float, b: Float)->Float {
        return atan2f(sin(b) + sin(a), cos(a) + cos(b))
    }
}


