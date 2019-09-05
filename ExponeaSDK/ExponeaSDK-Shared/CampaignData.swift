//
//  CampaignData.swift
//  ExponeaSDK
//
//  Created by arpad jakab on 08/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct CampaignData {
    let params: [URLQueryItem]
    let url: URL
    init(url: URL) {
        self.url = url
        if let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let _ = components.path,
            let params = components.queryItems  {
            self.params = params
        } else { params = [] }
    }
}
