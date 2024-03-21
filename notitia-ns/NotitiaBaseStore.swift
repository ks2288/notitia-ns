//
//  NotitiaBaseStore.swift
//  notitia-ns
//
//  Created by Kenny Sofranko on 3/21/24.
//

import RealmSwift

/// Simple "abstract" base class to to remove boilerplate from stores
open class NotitiaBaseStore: BaseStore {
    
    let realmManager: RealmManagerNS
    
    /// returns Realm? - shortcut for RealmHelper.getRealmInstance()
    var realm: Realm {
        RealmManagerNS.shared.realm
    }
    
    /// Initializer, derived classes should override as needed
    ///
    /// - Parameter realm: realm instance to be used by this store.
    init(realmManager: RealmManagerNS = RealmManagerNS.shared) {
        self.realmManager = realmManager
    }
    
    func initializeObjects() -> Bool {
        return true
    }
}

/// Simple "abstract" base class for stores that handle objects of a given type
open class SingleTypedNotitiaStore<Element>: NotitiaBaseStore, SingleTypedBaseStore where Element: Object {
    // swiftlint:disable:next type_name - used in protocol
    typealias T = Element
}
