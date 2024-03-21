//
//  CustomAddOrUpdate.swift
//  notitia-ns
//
//  Created by Kenny Sofranko on 3/21/24.
//

import Foundation
import RealmSwift

enum CustomAddOrUpdateError: Error {
    case safeObjectNil
}

/// Simple protocol that just ensures the object can update from a type of itself
/// Note: Use this only if the update logic is not simple(i.e. only update some properties) or
/// you need to utilize one of the extension functions listed in this file.
/// Otherwise just use Realm's UpdatePolicy.
protocol CustomAddOrUpdate {
    func update(other: Self)
}

/// Extension that utilizes CustomAddOrUpdate
extension Realm {
    typealias Handler = (Swift.Error) -> Void
    
    enum AddOrUpdatePolicy {
        case fail
        case useFirst
        case useLast
    }
    
    /// Function that checks if an object exists if so updates existing with object, otherwise adds object as a new one.
    /// - Parameters:
    ///   - object: object to add or update
    ///   - predicate: NSPredicate to query matching objects
    ///   - block: Optional comparison block. If result is true, updates the existing with object, if false does nothing.
    ///   - onMultiple: Policy on how to handle the situation when multiple objects match the predicate condition.
    /// - Returns: false if we fail at any of the steps, true otherwise
    func addOrUpdate<T>(object: T,
                        predicate: NSPredicate,
                        block: ((T, T) -> Bool)? = nil,
                        onMultiple policy: AddOrUpdatePolicy = .fail) -> Bool where T: CustomAddOrUpdate, T: Object {
        let results = self.objects(T.self).filter(predicate)
        
        guard results.count <= 1 || policy != .fail else {
            Logger.e("Found multiple objects for: \(T.self) with a fail policy so failing")
            return false
        }
        
        if let existing = (policy == .fail ? results.first : results.last) {
            if block?(object, existing) != false {
                return self.safeUpdate(existing: existing, with: object)
            } else {
                return true
            }
        } else {
            return self.addSync(object: object)
        }
    }
    
    /// Function that checks if an object with the primary key equal to the one provided exists.
    /// If it does, updates it. Otherwise just creates a new one.
    /// Note: We use the primary key of the object, so the object must have a primary key designated.
    /// - Parameters:
    ///   - object: object to add or update
    ///   - block: Optional comparison block. If result is true, updates the existing with object, if false does nothing.
    /// - Returns: false if we fail at any of the steps, true otherwise
    func addOrUpdate<T>(object: T, block: ((T, T) -> Bool)? = nil) -> Bool where T: CustomAddOrUpdate, T: Object {
        
        guard let primaryKey = T.primaryKey() else {
            Logger.e("Object being used must have a primaryKey!")
            return false
        }
        
        // So check if the object exists already
        if let existing = self.object(ofType: T.self, forPrimaryKey: object.value(forKey: primaryKey)) {
            if block?(object, existing) != false {
                return safeUpdate(existing: existing, with: object)
            } else {
                return true
            }
        } else { // Otherwise create it newly
            return addSync(object: object)
        }
    }
    
    /// Convenience function that updates existing with object
    ///
    /// - Parameters:
    ///   - existing: existing object
    ///   - with object: object to update existing with
    func safeUpdate<T>(existing: T, with object: T) -> Bool where T: CustomAddOrUpdate, T: Object {
        self.writeSync(object: existing) { (safeRealm, safeObject) in
            if let safeObject = safeObject {
                safeObject.update(other: object)
            } else {
                throw CustomAddOrUpdateError.safeObjectNil
            }
        }
    }
    
    /// Convenience function that updates existing with object
    ///
    /// - Parameters:
    ///   - existing: existing object
    ///   - with object: object to update existing with
    ///   - errorHandler: called if any errors occur in the process
    func safeUpdate<T>(existing: T,
                       with object: T,
                       errorHandler: @escaping (_ error: Swift.Error) -> Void) where T: CustomAddOrUpdate, T: Object {
        self.writeSync(object: existing, errorHandler: errorHandler) { (safeRealm, safeObject) in
            if let safeObject = safeObject {
                safeObject.update(other: object)
            } else {
                errorHandler(CustomAddOrUpdateError.safeObjectNil)
            }
        }
    }
}
