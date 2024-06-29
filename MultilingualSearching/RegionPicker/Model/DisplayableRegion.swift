//
//  DisplayableRegion.swift
//  RegionPicker
//
//  Created by Joshua Asbury on 29/6/2024.
//

import Foundation

protocol DisplayableRegion: Identifiable, Hashable, Comparable {
    var id: String { get }
    var regionCode: String { get }
    var regionCodeIsAlreadyLocalizedTitle: Bool { get }
}

extension DisplayableRegion {
    var regionCodeIsAlreadyLocalizedTitle: Bool { false }
    
    var title: String? {
        if regionCodeIsAlreadyLocalizedTitle { return regionCode }
        return Locale.current.localizedString(forRegionCode: id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        guard let lhsTitle = lhs.title, let rhsTitle = rhs.title else { return false }
        // Sort ignoring diacritics; e.g. Å would matching A
        return lhsTitle.compare(rhsTitle, options: .diacriticInsensitive, locale: .current) == .orderedAscending
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
