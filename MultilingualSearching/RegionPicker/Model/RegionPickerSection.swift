//
//  RegionPickerSection.swift
//  RegionPicker
//
//  Created by Joshua Asbury on 29/6/2024.
//

struct RegionPickerSection: DisplayableRegion {
    let id: String
    let regionCode: String
    let items: [RegionPickerItem]
    let regionCodeIsAlreadyLocalizedTitle: Bool
    
    init(regionIdentifier: String, items: [RegionPickerItem]) {
        id = regionIdentifier
        regionCode = regionIdentifier
        self.items = items
        regionCodeIsAlreadyLocalizedTitle = false
    }
    
    init(id: String? = nil, fixedTitle: String, items: [RegionPickerItem]) {
        self.id = id ?? fixedTitle
        regionCode = fixedTitle
        self.items = items
        regionCodeIsAlreadyLocalizedTitle = true
    }
}
