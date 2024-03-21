//
//  RealmManager.swift
//  notitia-ns
//
//  Created by Kenny Sofranko on 3/21/24.
//

import RealmSwift

/// Class to help manage initialization of Realm, open and close Realm instances as well as deletion of Realm files.
class RealmManager {
    
    static let shared = RealmManager()
    
    /// tags for the Logger
    static let tags = ["Realm"]
    
    /// Realm.Configuration to be used when retrieving a Realm instance.
    var config: Realm.Configuration? {
        didSet {
            if let config = config {
                Realm.Configuration.defaultConfiguration = config
            }
        }
    }
    
    /// Realm instance with config as the Realm.Configuration
    var realm: Realm? {
        guard let config = config else {
            return nil
        }
        
        guard let realm = try? Realm(configuration: config) else {
            return nil
        }
        
        realm.autorefresh = true
        realm.refresh()
        return realm
    }
    
    
    /// Static accessor
    fileprivate init(_ config: Realm.Configuration? = nil) {
        // TODO: look into adding a sync flag for that Realm service
        //SyncManager.shared.logLevel = .off
        
        self.config = config
    }
}

// MARK: - Generic Utility functions

extension RealmManager {
    /// Returns true if the realm file exists
    static var fileExists: Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// Returns the URL of the realm file.
    private static var realmURL: URL {
        do {
            return try FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false)
                .appendingPathComponent("default.realm")
        } catch {
            fatalError("Failed finding expected path: \(error)")
        }
    }
    
    /// Returns the path of the realm file.
    private static var path: String {
        return realmURL.path
    }
    
    /// Default migration logic
    private static var defaultMigrationBlock: (Migration, UInt64) -> Void = { (_, oldSchemaVersion) in
        // We haven’t migrated anything yet, so oldSchemaVersion == 0
        if oldSchemaVersion < 1 {
            // Nothing to do!
            // Realm will automatically detect new properties and removed properties
            // And will update the schema on disk automatically
        }
    }
    
    /// Convenience function to create a RealmConfiguration
    static func createConfig(fileURL: URL = RealmManager.realmURL,
                             keyChainIdentifier: String,
                             schemaVersion: UInt64 = 1,
                             deleteRealmIfMigrationNeeded: Bool = true,
                             migrationBlock: @escaping (Migration, UInt64) -> Void = defaultMigrationBlock) -> Realm.Configuration {
        Realm.Configuration(
            fileURL: fileURL,
            encryptionKey: getRealmKey(keyChainIdentifier) as Data,
            schemaVersion: schemaVersion,
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: migrationBlock,
            deleteRealmIfMigrationNeeded: deleteRealmIfMigrationNeeded
        )
    }
    
    /// Delete Realm and associated files.
    func deleteRealm() { // FIXME: NEVPTA-1623: Determine whether this function is needed.
        // this could be static if needed.
        let realmURLs = [
            RealmManager.realmURL,
            RealmManager.realmURL.appendingPathExtension("lock"),
            RealmManager.realmURL.appendingPathExtension("note"),
            RealmManager.realmURL.appendingPathExtension("management")
        ]
        for URL in realmURLs {
            do {
                if RealmManager.fileExists {
                    try FileManager.default.removeItem(at: URL)
                }
            } catch {
                Logger.e("Delete Realm failed", tags: RealmManager.tags)
            }
        }
    }
}

// MARK: - Additional Utility with BaseNotitiaStore usage
extension RealmManager {
    /// BaseNotitiaStores being used in the app.
    var stores: [BaseStore] {
        return []
    }
    
    /// Convenience function for restting the data for the app.
    /// "Reset" as opposed to "delete" since this is meant to set
    /// the state of data in the app instance to a "blank slate".
    func resetData() -> Bool {
        guard let realm = realm else {
            Logger.e("Realm instance is nil", tags: RealmManager.tags)
            return false
        }
        
        realm.deleteAll()
        
        var result = true
        
        for store in stores {
            result = result && store.initializeObjects()
        }
        
        return result
    }
}

// MARK: - Security for Realm
extension RealmManager {
    /// Generate or retrieve key for Realm.
    ///
    /// - Returns: Generated or retrieved 64 byte key.
    private static func getRealmKey(_ keyChainIdentifier: String) -> Data {
        let keychainIdentifierData = keyChainIdentifier.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        // First check in the keychain for an existing key
        var query: [NSString: AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecReturnData: true as AnyObject
        ]
        
        // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
        // See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
        var dataTypeRef: AnyObject?
        var status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
        
        if status == errSecSuccess {
            if let key = dataTypeRef as? NSData {
                return key as Data
            } else {
                Logger.e("Failed to get key, a new key will be created.", tags: tags)
            }
        } else {
            Logger.e("Failed to get key, a new key will be created.", tags: tags)
        }
        
        // No pre-existing key from this application, so generate a new one
        // swiftlint:disable:next force_unwrapping - will not fail
        let keyData = NSMutableData(length: 64)!
        let result = SecRandomCopyBytes(kSecRandomDefault, 64, keyData.mutableBytes.bindMemory(to: UInt8.self, capacity: 64))
        assert(result == 0, "Failed to get random bytes")
        
        // Store the key in the keychain
        query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecValueData: keyData
        ]
        
        // place of actual execution
        status = SecItemAdd(query as CFDictionary, nil)
        assert(status == errSecSuccess, "Failed to insert the new key in the keychain")
        
        return keyData as Data
    }
}
