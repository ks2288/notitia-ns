//
//  RealmManagerNS.swift
//  notitia-ns
//
//  Created by Kenny Sofranko on 3/21/24.
//

import RealmSwift
import Foundation

/// Generic wrapper for RealmManager.
class RealmManagerNS {
    /// RealmManager instance being used.
    fileprivate let realmManager = RealmManager.shared
    
    /// Reference for singleton use.
    static let shared = RealmManagerNS()
    
    /// Realm configuration with encryption key and schema migration
    fileprivate static let notitiaConfig = RealmManager.createConfig(keyChainIdentifier: "Notitia")
    
    /// Provides a reference to Realm instance.
    /// If realm is nil will cause a preconditionFailure.
    var realm: Realm {
        guard let realm = realmManager.realm else {
            preconditionFailure("Could not retrieve Realm instance")
        }
        return realm
    }
    
    /// Initializer
    fileprivate init() {
        // TODO: look into implementing a sync flag for that service
//        SyncManager.shared.logLevel = .off
        realmManager.config = RealmManagerNS.notitiaConfig
    }
}
