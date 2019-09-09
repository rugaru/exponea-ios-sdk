//
//  TrackEventSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 13/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Nimble
import Quick

@testable import ExponeaSDK

class TrackingManagerSpec: QuickSpec {
    override func spec() {
        describe("Tracking manager") {
            context("updateLastEvent") {
                var trackingManager: TrackingManager!

                beforeEach {
                    let configuration = try! Configuration(plistName: "TrackingManagerUpdate")
                    let mockRepo = MockRepository(configuration: configuration)
                    let database = try! MockDatabaseManager()

                    trackingManager = TrackingManager(repository: mockRepo,
                                                      database: database,
                                                      userDefaults: UserDefaults())
                }

                it("should do nothing without events") {
                    let updateData = DataType.properties(["testkey": .string("testvalue")])
                    expect {
                        try trackingManager.updateLastPendingEvent(ofType: Constants.EventTypes.sessionStart,
                                                            with: updateData)
                    }.notTo(raiseException())
                }

                it("should update event") {
                    let updateData = DataType.properties(["testkey": .string("testvalue")])
                    expect {
                        try trackingManager.track(EventType.sessionEnd, with: [])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.updateLastPendingEvent(ofType: Constants.EventTypes.sessionEnd,
                                                            with: updateData)
                    }.notTo(raiseException())
                    let event = try! trackingManager.database.fetchTrackEvent().first!
                    let insertedData = event.properties?.first(
                        where: { item in (item as! KeyValueItem).key == "testkey" }
                    ) as? KeyValueItem
                    expect { insertedData?.value as? String }.to(equal("testvalue"))
                }

                it("should only update last event") {
                    let updateData = DataType.properties(["testkey": .string("testvalue")])
                    expect {
                        try trackingManager.track(EventType.sessionEnd,
                                                  with: [DataType.properties(["order": .string("1")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.track(EventType.sessionEnd,
                                                  with: [DataType.properties(["order": .string("2")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.track(EventType.sessionEnd,
                                                  with: [DataType.properties(["order": .string("3")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.updateLastPendingEvent(ofType: Constants.EventTypes.sessionEnd,
                                                            with: updateData)
                    }.notTo(raiseException())
                    let events = try! trackingManager.database.fetchTrackEvent()
                    events.forEach { event in
                        if event.eventType == Constants.EventTypes.sessionEnd {
                            let order = event.properties?.first(
                                where: { item in (item as! KeyValueItem).key == "order" }
                            ) as! KeyValueItem
                            let insertedData = event.properties?.first(
                                where: { item in (item as! KeyValueItem).key == "testkey" }
                            ) as? KeyValueItem
                            if order.value as! String == "3" {
                                expect { insertedData?.value as? String }.to(equal("testvalue"))
                            } else {
                                expect { insertedData }.to(beNil())
                            }
                        }
                    }
                }

                it("should update multiple events if there are multiple project tokens") {
                    let updateData = DataType.properties(["testkey": .string("testvalue")])
                    expect {
                        try trackingManager.track(EventType.sessionStart,
                                                  with: [DataType.properties(["order": .string("1")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.track(EventType.sessionStart,
                                                  with: [DataType.properties(["order": .string("2")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.track(EventType.sessionStart,
                                                  with: [DataType.properties(["order": .string("3")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.updateLastPendingEvent(ofType: Constants.EventTypes.sessionStart,
                                                            with: updateData)
                    }.notTo(raiseException())
                    let events = try! trackingManager.database.fetchTrackEvent()
                    events.forEach { event in
                        if event.eventType == Constants.EventTypes.sessionStart {
                            let order = event.properties?.first(
                                where: { item in (item as! KeyValueItem).key == "order" }
                            ) as! KeyValueItem
                            let insertedData = event.properties?.first(
                                where: { item in (item as! KeyValueItem).key == "testkey" }
                            ) as? KeyValueItem
                            if order.value as! String == "3" {
                                expect { insertedData?.value as? String }.to(equal("testvalue"))
                            } else {
                                expect { insertedData }.to(beNil())
                            }
                        }
                    }
                }
            }
        }
    }
}
