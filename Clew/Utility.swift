//
//  Utility.swift
//  BreadCrumbsTest
//
//  Created by Chris Seonghwan Yoon on 8/3/17.
//  Copyright © 2017 OccamLab. All rights reserved.
//

import Foundation

/// Round a float to the nearest tenth.  Swift doesn't have a good built-in method for doing this.
///
/// - Parameter n: the number to round
/// - Returns: the number rounded to the nearest tenth
func roundToTenths(_ n: Float) -> Float {
    return roundf(10 * n)/10
}


/// Modulus function (swift's % operator is a remainder function that doesn't work properly for negative numbers
///
/// - Parameters:
///   - a: the number
///   - n: the modulus
/// - Returns: a mod n
func mod(_ a: Int, _ n: Int) -> Int {
    precondition(n > 0, "modulus must be positive")
    let r = a % n
    return r >= 0 ? r : r + n
}

/// A generic RingBuffer that supports some basic operations
class RingBuffer<Element> {
    /// The most recently used slot
    var head = 0
    /// The backing array
    var data: [Element?]

    /// Create the ring buffer with the specified capacity.  Initially, all values will be nil
    ///
    /// - Parameter capacity: the number of slots in the buffer
    public init(capacity: Int) {
        data = [Element?](repeating: nil, count: capacity)
    }

    /// Insert a new element into the buffer
    ///
    /// - Parameter v: the value to insert
    public func insert(_ v: Element) {
        head = mod(head + 1, data.count)
        data[head] = v
    }
    
    /// Get the index in the buffer stored at the specified index.
    ///
    /// - Parameter index: the index to check.  0 means the index most distant from the next insertion point of the buffer.  As index goes up, the data becomes more recent
    /// - Returns: the element stored at the specified index.
    
    /// Get the index in the buffer stored at the specified index.
    ///
    /// - Parameter index: the index to check.  0 means the index most distant from the most recently inserted element into the buffer.  As index goes up, the data becomes more recent.  Index -1 will be the most recently inserted element into the buffer
    /// - Returns: the element stored at the specified index.
    public func get(_ index: Int)->Element? {
        let remappedIndex = mod(index + (head + 1), data.count)
        return data[remappedIndex]
    }
    
    /// Clear the buffer
    public func clear() {
        head = 0
        data = [Element?](repeating: nil, count: capacity)
    }
    
    /// The capacity of the ring buffer
    var capacity: Int {
        return data.count
    }
}
