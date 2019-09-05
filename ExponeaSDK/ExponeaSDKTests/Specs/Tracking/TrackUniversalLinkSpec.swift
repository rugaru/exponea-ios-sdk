//
//  TrackUniversalLinkSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 07/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
import CoreData

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
            context("Track universal link with mock repository") {
                let data: [DataType] = [.projectToken(mockData.projectToken),
                                        .properties(mockData.campaignData),
                                        .timestamp(nil)
                ]
                
                waitUntil(timeout: 3) { done in
                    mockRepo.trackCampaignClick(with: data, for: mockData.customerIds) { (result) in
                        it("Result error should be nil") {
                            expect(result.error).to(beNil())
                        }
                        done()
                    }
                }
            }
            context("Track universal link update session start", closure: {
                db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                let sessionStart: [DataType] = [
                    .projectToken("mytoken"),
                    .properties(["customprop": .string("customval")]),
                    .eventType("session_start")
                ]

                expect {
                    try db.trackEvent(with: sessionStart)
                    return nil
                }.toNot(raiseException())
                
                var objects: [TrackEvent] = []
                expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                expect(objects.count).to(equal(1))

                let campaignData = CampaignData(url: mockData.campaignUrl!)
                expect { try db.updateEvent(withId: objects.first!.objectID, withData: campaignData.utmData)}.toNot(raiseException())
                expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                expect(objects.count).to(equal(1))

                let props = objects.first?.properties as? Set<KeyValueItem>
                let campaignProp = props?.first(where: { $0.key == "utm_campaign" })
                expect(campaignProp?.value as? String).to(equal("mycampaign"))
                }
            )
            context("Track campaign click with immediate flushing within session update threshold", closure: {
                let exponea = MockExponea()
                Exponea.shared = exponea
                Exponea.shared.configure(plistName: "ExponeaConfig")

                exponea.flushingMode = .immediate
                exponea.configuration?.sessionTimeout = 5.0
                // just to be shure, that no session is running
                exponea.trackSessionEnd()
                // track campaign click, session_start should be updated with utm params
                exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)
                var trackEvents: [TrackEvent] = []
                expect { trackEvents = try exponea.fetchTrackEvents() }.toNot(raiseException())
                let sessionStart = trackEvents.first(where: { $0.eventType == "session_start" })
                expect(sessionStart).toNot(beNil())
                let props = sessionStart!.properties as? Set<KeyValueItem>
                let campaignProp = props?.first(where: { $0.key == "utm_campaign" })
                expect(campaignProp?.value as? String).to(equal("mycampaign"))
            })
            context("Track campaign click with immediate flushing after session update threshold", closure: {
                let exponea = MockExponea()
                Exponea.shared = exponea
                Exponea.shared.configure(plistName: "ExponeaConfig")
                
                exponea.flushingMode = .immediate
                exponea.configuration?.sessionTimeout = 8.0
                // just to be shure, that no session is running
                exponea.trackSessionEnd()
                // start the session and wait 5 seconds
                exponea.trackSessionStart()
                sleep(5)

                // track campaign click, session_start should not be updated with utm params
                exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)
                var trackEvents: [TrackEvent] = []
                expect { trackEvents = try exponea.fetchTrackEvents() }.toNot(raiseException())
                let sessionStart = trackEvents.first(where: { $0.eventType == "session_start" })
                expect(sessionStart).toNot(beNil())
                let props = sessionStart!.properties as? Set<KeyValueItem>
                let campaignProp = props?.first(where: { $0.key == "utm_campaign" })
                // session start should not contain utm params
                expect(campaignProp?.value as? String).to(beNil())
            })
        }
    }
}
