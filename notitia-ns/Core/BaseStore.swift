//
//  BaseStore.swift
//  notitia-ns
//
//  Created by Kenny Sofranko on 3/21/24.
//

import RealmSwift

/// Protocol that facilitates
/// first time initialization of realm stores for testing purposes
protocol TestStore {
    /// Called once upon app startup to init. the store for the first time.
    /// Mainly for testing purposes.
    /// - Return Bool: defaults to true, derived classes should override as needed
    func initializeObjects() -> Bool
}

/// Protocol for stores. Stores are the class that enable the reading/writing to Realm Objects.
protocol BaseStore: TestStore {
    var realm: Realm { get }
}

/// Protocol for stores that have a single Realm Object type.
protocol SingleTypedBaseStore: NotitiaBaseStore {
    // swiftlint:disable:next type_name - used in protocol
    associatedtype T: Object
}

/// Extention for SingleTypedBaseStore
extension SingleTypedBaseStore {
    var objects: RealmSwift.Results<T> {
        return realm.objects(T.self)
    }
}
