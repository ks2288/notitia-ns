//
//  NotitiaDataAccessor.swift
//  notitia-ns
//
//  Created by Kenny Sofranko on 3/21/24.
//

import Foundation
import RealmSwift

/// Protocol defining the core methods and their signatures for each DAO
protocol NototiaDataAccessor: ThreadConfined {
    func persistUnmanaged(newObject: Object)
    func removeManaged(object: Object)
    func updateManaged(managedObject: Object,
                       byAttributeName name: String,
                       withAttributeValue value: String) -> Bool
    func fetchManagedList(ofType type: Object.Type,
                          byAttributeName name: String,
                          withAttributeValue value: String) -> Results<Object>?
    func fetchAllManaged(ofType type: Object.Type) -> Results<Object>?
}

/// Core abstraction from which each of the three DAOs will inherit to allow the
/// app to easily access Realm data from any particular module for any purpose
class NotitiaDAO: ObservableObject, NototiaDataAccessor {
    func thaw() -> Self? { return self }
    
    var realm: Realm?
    
    /// ThreadConfined Protocol
    var isInvalidated: Bool
    var isFrozen: Bool
    func freeze() -> Self {
        isFrozen = true
        return self
    }
    
    init() {
        isFrozen = false
        realm = try? Realm()
        isInvalidated = false
    }
    
    /* Realm Data Accessor Protocol */
    
    /// Simple wrapper function to persist a new, unmanaged Realm object
    func persistUnmanaged(newObject: Object) {
        guard isRealmValid() else { return }
        self.realm?.writeSync(object: newObject) { _, _ in
            self.realm?.add(newObject)
        }
    }
    
    /// Deletes a specified object from Realm
    func removeManaged(object: Object) {
        guard isRealmValid() else { return }
        self.realm?.writeSync(object: object) { _, _ in
            self.realm?.delete(object)
        }
    }
    
    /// Updates a managed, referenced object according to a passed KVP and a type
    /// designation
    func updateManaged<T: Object> (managedObject: T,
                                     byAttributeName name: String,
                                     withAttributeValue value: String) -> Bool {
        guard isRealmValid() else { return false }
        var success: Bool = false
        self.realm?.writeSync(object: managedObject) { _, _ in
            managedObject.setValue(value, forKey: name)
            success = true
        }
        return success
    }
    
    /// Generic abstraction for chain-fetching any managed list of Realm objects by type a designation
    /// and a KVP for the desired property/range
    func fetchManagedList<T: Object> (ofType type: T.Type,
                                      byAttributeName name: String,
                                      withAttributeValue value: String) -> Results<T>? {
        guard isRealmValid() else { return nil }
        let predicate = NSPredicate(format: "\(name) = %@", value)
        return realm?.objects(type.self).filter(predicate)
    }
    
    /// Generic abstraction that fetches all managed objects of a specifiedType, if any exist
    func fetchAllManaged<T: Object> (ofType type: T.Type) -> Results<T>? {
        guard isRealmValid() else { return nil }
        return realm?.objects(type.self)
    }
    
    /* Private Util Methods */
    
    /// Checks Realm instance for validity; wrapped to encompass logger
    private func isRealmValid() -> Bool {
        guard self.realm != nil else {
            Logger.i("Realm instance ERROR @\(String(describing: Date()))...")
            return false
        }
        Logger.i("Realm instance SUCCESS @\(String(describing: Date()))...")
        return true
    }
    
    /// Writes to Realm via closure
    static func realmWrite(block: () -> Void) -> Bool {
        let instance: Realm = RealmManagerNS.shared.realm
        do {
            try instance.write(block)
            Logger.i("Realm write SUCCESS @\(String(describing: Date()))...")
            return true
        }
        catch {
            Logger.e("Realm write ERROR @\(String(describing: Date()))...")
        }
        return false
    }
}
