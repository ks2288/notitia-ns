//
//  RealmOptional+Helpers.swift
//  notitia-ns
//
//

import RealmSwift

extension RealmOptional where Value: Comparable {

    /// Determines if the wrapped value is greater than passed in realm optional
    /// Parameters:
    ///     - other: Other RealmOptional to compare with
    ///     - isNilConsideredGreater: Bool value to be returned if one of them is nil, defaults to true.
    func isGreaterThan(_ other: RealmOptional, isNilConsideredGreater: Bool = true) -> Bool {
        if self.value == other.value {
            return false
        } else {
            guard let selfUnwrapped = self.value else {
                return isNilConsideredGreater
            }

            guard let otherUnwrapped = other.value else {
                return !isNilConsideredGreater
            }

            return selfUnwrapped > otherUnwrapped
        }
    }

    /// Determines if the wrapped value is less than passed in realm optional
    /// Parameters:
    ///     - other: Other RealmOptional to compare with
    ///     - isNilConsideredGreater: Bool value to be returned if one of them is nil, defaults to true.
    func isLessThan(_ other: RealmOptional, isNilConsideredLess: Bool = true) -> Bool {
        if self.value == other.value {
            return false
        } else {
            guard let selfUnwrapped = self.value else {
                return isNilConsideredLess
            }

            guard let otherUnwrapped = other.value else {
                return !isNilConsideredLess
            }

            return selfUnwrapped < otherUnwrapped
        }
    }


    // Static convenient functions
    // IMPORTANT NOTE: The comparison result for when one of them is nil is hard coded here as true
    //                 If you need to change it, use the functions above

    static func == (lhs: RealmOptional, rhs: RealmOptional) -> Bool {
        return lhs.value == rhs.value
    }

    static func != (lhs: RealmOptional, rhs: RealmOptional) -> Bool {
        return !(lhs == rhs)
    }

    static func > (lhs: RealmOptional, rhs: RealmOptional) -> Bool {
        return lhs.isGreaterThan(rhs, isNilConsideredGreater: true)
    }

    static func < (lhs: RealmOptional, rhs: RealmOptional) -> Bool {
        return lhs.isLessThan(rhs, isNilConsideredLess: true)
    }

    static func >= (lhs: RealmOptional, rhs: RealmOptional) -> Bool {
        if lhs == rhs {
            return true
        } else {
            return lhs.isGreaterThan(rhs, isNilConsideredGreater: true)
        }
    }

    static func <= (lhs: RealmOptional, rhs: RealmOptional) -> Bool {
        if lhs == rhs {
            return true
        } else {
            return lhs.isLessThan(rhs, isNilConsideredLess: true)
        }
    }
}
