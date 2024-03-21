//
//  Realm+Helper.swift
//  notitia-ns
//
//

import RealmSwift

/// Extension for Realm to add support for a thread-safe writing/deleting.
/// This is because the original write/delete functions are not thread-safe necessarily,
/// and can cause exceptions.
/// For more details around thread-safety and Realm checkout
/// https://realm.io/blog/obj-c-swift-2-2-thread-safe-reference-sort-properties-relationships/
extension Realm {
    /// tags for the Logger
    fileprivate static let tags: [String] = ["Realm"]
    
    /// DispatchQueue to handle the write operations on.
    fileprivate static var backgroundQueue: DispatchQueue {
        return DispatchQueue(label: "dev.specter.realm.operations",
                             qos: .userInitiated,
                             target: nil)
    }
    
    /// Utility function to reduce the repeated logic in the following sync functions.
    fileprivate func executeOp(tag: String = "Realm",
                               errorHandler: ((_ error: Swift.Error) -> Void)? = nil,
                               execute block: () throws -> Void) {
        Realm.backgroundQueue.sync {
            autoreleasepool {
                do {
                    try block()
                } catch let error {
                    Logger.e("failed with error: \(error)", tags: Realm.tags)
                    errorHandler?(error)
                }
            }
        }
    }
    
    /// Utility function to reduce the repeated logic in the following sync functions.
    @discardableResult
    fileprivate func executeOp(tag: String = "Realm", execute block: () throws -> Void) -> Bool {
        var result = true
        let errorHandler = { (error: Swift.Error) -> Void in
            Logger.e("Error when trying to execute \(tag) operation with error: \(error)")
            result = false
        }
        executeOp(errorHandler: errorHandler, execute: block)
        return result
    }
    
    // MARK: - Add Functions -
    
    /// Convenience function just to add a Realm Object to realm
    ///
    /// - Parameters:
    ///   - object: object to be added
    ///   - update: UpdatePolicy, defaults to throwing error if there is an object with the same primary key
    /// - Returns: true if object was added, false otherwise
    @discardableResult
    func addSync<T>(object: T, update: UpdatePolicy = .error) -> Bool where T: Object {
        executeOp(tag: "AddSync") {
            try self.write {
                self.add(object, update: update)
            }
        }
    }
    
    /// Convenience function just to add a Realm Object to realm
    ///
    /// - Parameters:
    ///   - object: object to be added
    ///   - update: UpdatePolicy, defaults to throwing error if there is an object with the same primary key
    ///   - errorHandler: called when error is thrown
    func addSync<T>(object: T,
                    update: UpdatePolicy = .error,
                    errorHandler: @escaping (_ error: Swift.Error) -> Void) where T: Object {
        executeOp(tag: "AddSync", errorHandler: errorHandler) {
            try self.write {
                self.add(object, update: update)
            }
        }
    }
    
    /// Convenience function just to add a Realm Object to realm
    ///
    /// - Parameters:
    ///   - object: object to be added
    ///   - update: UpdatePolicy, defaults to throwing error if there is an object with the same primary key
    ///   - errorHandler: called when error is thrown
    func addSync<T, C>(objects: C,
                       update: UpdatePolicy = .error) where T: Object, C: Collection, C.Element == T {
        executeOp(tag: "AddSync") {
            try self.write {
                objects.forEach { object in
                    self.add(object, update: update)
                }
            }
        }
    }
    
    /// Convenience function just to add a Realm Object to realm
    ///
    /// - Parameters:
    ///   - object: object to be added
    ///   - update: UpdatePolicy, defaults to throwing error if there is an object with the same primary key
    ///   - errorHandler: called when error is thrown
    func addSync<T, C>(objects: C,
                       update: UpdatePolicy = .error,
                       errorHandler: @escaping (_ error: Swift.Error) -> Void) where T: Object, C: Collection, C.Element == T {
        executeOp(tag: "AddSync", errorHandler: errorHandler) {
            try self.write {
                objects.forEach {
                    self.add($0, update: update)
                }
            }
        }
    }
    
    // MARK: - Write Functions -
    
    // MARK: Single Object
    
    /// This method is used when the realm object is not saved in the DB
    ///
    /// - Parameters:
    ///   - object: A Realm Object that derives from ThreadConfined
    ///   - errorHandler: Optional error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    private func writeSyncForUnmanagedObject<T: ThreadConfined>(object: T,
                                                                errorHandler: ((_ error: Swift.Error) -> Void)? = nil,
                                                                block: @escaping (Realm, T?) throws -> Void) {
        executeOp(tag: "UnManagedWriteSync", errorHandler: errorHandler) {
            try self.write {
                try block(self, object)
            }
        }
    }
    
    /// This method is used when the realm object is saved in the DB
    ///
    /// - Parameters:
    ///   - object: A Realm Object that derives from ThreadConfined
    ///   - errorHandler: Optional error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    private func writeSyncForManagedObject<T: ThreadConfined>(object: T,
                                                              errorHandler: ((_ error: Swift.Error) -> Void)? = nil,
                                                              block: @escaping (Realm, T?) throws -> Void) {
        executeOp(tag: "UnManagedWriteSync", errorHandler: errorHandler) {
            let wrappedObject = ThreadSafeReference(to: object)
            let safeObject = self.resolve(wrappedObject)
            try self.write {
                try block(self, safeObject)
            }
        }
    }
    
    /// Writes an object to realm, in a thread-safe manner.
    ///
    /// - Parameters:
    ///   - object: A Realm Object that derives from ThreadConfined
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    @discardableResult
    func writeSync<T: ThreadConfined>(object: T,
                                      block: @escaping (Realm, T?) throws -> Void) -> Bool {
        var result = true
        let errorHandler = { (error: Swift.Error) -> Void in
            Logger.e("Failed to write for object: \(object) with error: \(error)")
            result = false
        }
        if let _ = object.realm {
            writeSyncForManagedObject(object: object,
                                      errorHandler: errorHandler,
                                      block: block)
        } else {
            writeSyncForUnmanagedObject(object: object,
                                        errorHandler: errorHandler,
                                        block: block)
        }
        return result
    }
    
    /// Writes an object to realm, in a thread-safe manner.
    ///
    /// - Parameters:
    ///   - object: A Realm Object that derives from ThreadConfined
    ///   - errorHandler: Error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    func writeSync<T: ThreadConfined>(object: T,
                                      errorHandler: @escaping (_ error: Swift.Error) -> Void,
                                      block: @escaping (Realm, T?) -> Void) {
        if let _ = object.realm {
            writeSyncForManagedObject(object: object,
                                      errorHandler: errorHandler,
                                      block: block)
        } else {
            writeSyncForUnmanagedObject(object: object,
                                        errorHandler: errorHandler,
                                        block: block)
        }
    }
    
    /// Convenience function to do a realm transaction
    ///
    /// - Parameters:
    ///   - elementType: Type of the RealmObject we are working on
    ///   - predicate: Predicate to help filter the objects we are to work on
    ///   - errorHandler: called when error is thrown
    ///   - block: operation to do for the objects that match the elementType and predicate
    @discardableResult
    func writeSync<T>(elementType: T.Type,
                      predicate: NSPredicate,
                      block: @escaping (Realm, T) -> Void) -> Bool where T: Object {
        executeOp(tag: "PredWriteSync") {
            let objects = self.objects(elementType).filter(predicate)
            try self.write {
                objects.forEach {
                    block(self, $0)
                }
            }
        }
    }
    
    /// Convenience function to do a realm transaction
    ///
    /// - Parameters:
    ///   - elementType: Type of the RealmObject we are working on
    ///   - predicate: Predicate to help filter the objects we are to work on
    ///   - errorHandler: called when error is thrown
    ///   - block: operation to do for the objects that match the elementType and predicate
    func writeSync<T>(elementType: T.Type,
                      predicate: NSPredicate,
                      errorHandler: @escaping (_ error: Swift.Error) -> Void,
                      block: @escaping (Realm, T) -> Void) where T: Object {
        executeOp(tag: "UnManagedWriteSync", errorHandler: errorHandler) {
            let objects = self.objects(elementType).filter(predicate)
            try self.write {
                objects.forEach {
                    block(self, $0)
                }
            }
        }
    }
    
    // MARK: Multiple Objects
    
    /// This method is used when the realm object is not saved in the DB
    ///
    /// - Parameters:
    ///   - object: A Realm Object that derives from ThreadConfined
    ///   - errorHandler: Optional error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    private func writeSyncForUnmanagedObjects<T, C>(objects: C,
                                                    errorHandler: ((_ error: Swift.Error) -> Void)? = nil,
                                                    block: @escaping (Realm, T?) -> Void) where T: ThreadConfined,
                                                                                                C: Collection,
                                                                                                C.Element == T {
        executeOp(tag: "MultiUnManagedWriteSync", errorHandler: errorHandler) {
            try self.write {
                objects.forEach {
                    block(self, $0)
                }
            }
        }
    }
    
    /// This method is used when the realm object is saved in the DB
    ///
    /// - Parameters:
    ///   - object: A Realm Object that derives from ThreadConfined
    ///   - errorHandler: Optional error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    private func writeSyncForManagedObjects<T, C>(objects: C,
                                                  errorHandler: ((_ error: Swift.Error) -> Void)? = nil,
                                                  block: @escaping (Realm, T?) -> Void) where T: ThreadConfined,
                                                                                              C: Collection,
                                                                                              C.Element == T {
        executeOp(tag: "ManagedWriteSync", errorHandler: errorHandler) {
            let safeObjects: [T?] = objects.map {
                let wrappedObject = ThreadSafeReference(to: $0)
                return self.resolve(wrappedObject)
            }
            try self.write {
                safeObjects.forEach {
                    block(self, $0)
                }
            }
        }
    }
    
    /// Writes a collection of objects to realm, in a thread-safe manner.
    ///
    /// - Parameters:
    ///   - object: A Realm Object that derives from ThreadConfined
    ///   - errorHandler: Optional error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    func writeSync<T, C>(objects: C,
                         errorHandler: ((_ error: Swift.Error) -> Void)? = nil,
                         block: @escaping (Realm, T?) -> Void) where T: ThreadConfined,
                                                                     C: Collection,
                                                                     C.Element == T {
        var managedObjects = [T]()
        var unmanagedObjects = [T]()
        objects.forEach {
            if $0.realm != nil {
                managedObjects.append($0)
            } else {
                unmanagedObjects.append($0)
            }
        }
        
        if !managedObjects.isEmpty {
            writeSyncForManagedObjects(objects: objects,
                                       errorHandler: errorHandler,
                                       block: block)
        }
        
        if !unmanagedObjects.isEmpty {
            writeSyncForUnmanagedObjects(objects: objects,
                                         errorHandler: errorHandler,
                                         block: block)
        }
    }
    
    // MARK: - Delete Functions -
    
    /// This method is used when the realm objects are to be deleted from DB
    ///
    /// - Parameters:
    ///   - elementType: Type of the objects to be deleted
    ///   - errorHandler: Optional error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    func deleteSyncForManagedObjects<Element: Object>(elementType: Element.Type,
                                                      errorHandler: ((_ error: Swift.Error) -> Void)? = nil) {
        executeOp(tag: "ManagedDeleteSync", errorHandler: errorHandler) {
            let objectsToBeDeleted = self.objects(elementType)
            try self.write {
                self.delete(objectsToBeDeleted)
            }
        }
    }
    
    /// This method is used when the realm objects are to be deleted from DB
    ///
    /// - Parameters:
    ///   - query: Closure to generate the Results that should be deleted.
    ///   - errorHandler: Optional error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    func deleteSyncForManagedObjects<Element: Object>(query: (Realm) -> Results<Element>,
                                                      errorHandler: ((_ error: Swift.Error) -> Void)? = nil) {
        executeOp(tag: "MultiManagedDeleteSync", errorHandler: errorHandler) {
            let objectsToBeDeleted = query(self)
            try self.write {
                self.delete(objectsToBeDeleted)
            }
        }
    }
    
    /// This method is used when the realm objects are to be deleted from DB
    ///
    /// - Parameters:
    ///   - query: Closure to generate the Results that should be deleted.
    ///   - errorHandler: Optional error callback
    ///   - block: The execution block, where the caller will perform their writes to the passed object.
    func deleteSyncForManagedObjects<T: Object>(elementType: T.Type,
                                                predicate: NSPredicate,
                                                errorHandler: ((_ error: Swift.Error) -> Void)? = nil) {
        executeOp(tag: "PredManagedDeleteSync", errorHandler: errorHandler) {
            let objectsToBeDeleted = self.objects(elementType).filter(predicate)
            try self.write {
                self.delete(objectsToBeDeleted)
            }
        }
    }
    
    func resetRealm() {
        executeOp(tag: "Reset") {
            try self.write {
                self.deleteAll()
            }
        }
    }
}

extension Collection where Element: Object {

    /// Convenience method to add all objects to realm
    func addAll(realm: Realm, update: Realm.UpdatePolicy = .error) {
        realm.addSync(objects: self, update: update)
    }
}
