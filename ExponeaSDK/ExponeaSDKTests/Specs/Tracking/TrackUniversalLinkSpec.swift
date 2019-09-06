//
//  TrackUniversalLinkSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 07/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import CoreData
import Foundation
import Nimble
import Quick

@testable import ExponeaSDK

class TrackUniversalLinkSpec: QuickSpec {
    override func spec() {
        let inMemoryDescription = NSPersistentStoreDescription()
        inMemoryDescription.type = NSInMemoryStoreType
        var db: DatabaseManager!

        let configuration = try! Configuration(plistName: "ExponeaConfig")
        let mockRepo = MockRepository(configuration: configuration)
        let mockData = MockData()

        describe("Track universal link") {
            context("mock repository") {
                let data: [DataType] = [.projectToken(mockData.projectToken),
                                        .properties(mockData.campaignData),
                                        .timestamp(nil)]

                waitUntil(timeout: 3) { done in
                    mockRepo.trackCampaignClick(with: data, for: mockData.customerIds) { result in
                        it("should have nil result error") {
                            expect(result.error).to(beNil())
                        }
                        done()
                    }
                }
            }
            context("Tracking manager") {
                it("should update session start") {
                    db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                    let sessionStart: [DataType] = [
                        .projectToken("mytoken"),
                        .properties(["customprop": .string("customval")]),
                        .eventType("session_start"),
                    ]

                    expect {
                        try db.trackEvent(with: sessionStart)
                        return nil
                    }.toNot(raiseException())

                    var objects: [TrackEvent] = []
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(1))

                    let campaignData = CampaignData(url: mockData.campaignUrl!)
                    expect {
                        try db.updateEvent(withId: objects.first!.objectID, withData: campaignData.utmData)
                    }.toNot(raiseException())
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(1))

                    let props = objects.first?.properties as? Set<KeyValueItem>
                    let campaignProp = props?.first(where: { $0.key == "utm_campaign" })
                    expect(campaignProp?.value as? String).to(equal("mycampaign"))
                }
                it("should Track campaign click with immediate flushing within session update threshold") {
                    let exponea = MockExponea()
                    Exponea.shared = exponea
                    Exponea.shared.configure(plistName: "ExponeaConfig")

                    // track campaign click, session_start should be updated with utm params
                    exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                    var trackEvents: [TrackEvent] = []
                    expect { trackEvents = try exponea.fetchTrackEvents() }.toNot(raiseException())
                    let sessionStart = trackEvents.first(where: { $0.eventType == "session_start" })
                    expect(sessionStart).notTo(beNil())
                    let props = sessionStart!.properties as? Set<KeyValueItem>
                    let campaignProp = props?.first(where: { $0.key == "utm_campaign" })
                    expect(campaignProp?.value as? String).to(equal("mycampaign"))
                }
                it("should Track campaign click with immediate flushing after session update threshold") {
                    let exponea = MockExponea()
                    Exponea.shared = exponea
                    Exponea.shared.configure(plistName: "ExponeaConfig")

                    sleep(5)

                    // track campaign click, session_start should not be updated with utm params
                    exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                    var trackEvents: [TrackEvent] = []
                    expect { trackEvents = try exponea.fetchTrackEvents() }.toNot(raiseException())
                    let sessionStart = trackEvents.first(where: { $0.eventType == "session_start" })
                    expect(sessionStart).toNot(beNil())
                    let props = sessionStart!.properties as? Set<KeyValueItem>
                    let campaignProp = props?.first(where: { $0.key == "utm_campaign" })
                    expect(campaignProp?.value as? String).to(beNil())
                }
            }
        }
    }
}
