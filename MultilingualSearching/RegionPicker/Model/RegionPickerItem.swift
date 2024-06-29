//
//  RegionPickerItem.swift
//  RegionPicker
//
//  Created by Joshua Asbury on 29/6/2024.
//

import Foundation

struct RegionPickerItem: DisplayableRegion {
    let id: String
    let regionCode: String
    var searchMatchRange: NSRange?
    
    init(id: String, regionCode: String) {
        self.id = id
        self.regionCode = regionCode
    }
    
    init(regionIdentifier: String) {
        id = regionIdentifier
        regionCode = regionIdentifier
    }
}
