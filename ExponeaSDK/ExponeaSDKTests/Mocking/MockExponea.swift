//
//  MockExponea.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 17/07/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

import CoreData

final class MockExponea: Exponea {
    private var database: DatabaseManager!
    
    // override Exponea sharedInitializer to add mock database manager insead of coreData
    public override func sharedInitializer(configuration: Configuration) {
        Exponea.logger.log(.verbose, message: "Configuring MockExponea with provided configuration:\n\(configuration)")
        
        do {
            // Create database
            let inMemoryDescription = NSPersistentStoreDescription()
            inMemoryDescription.type = NSInMemoryStoreType
            database = try DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
            
            // Recreate repository
            let repository = ServerRepository(configuration: configuration)
            self.repository = repository
            
            // Finally, configuring tracking manager
            self.trackingManager = TrackingManager(repository: repository,
                                                   database: database,
                                                   userDefaults: MockUserDefaults())
        } catch {
            // Failing gracefully, if setup failed
            Exponea.logger.log(.error, message: """
                Error while creating a database, MockExponea cannot be configured.\n\(error.localizedDescription)
                """)
        }
    }

    public func fetchTrackEvents() throws -> [TrackEvent] {
        return try database.fetchTrackEvent()
    }
}
