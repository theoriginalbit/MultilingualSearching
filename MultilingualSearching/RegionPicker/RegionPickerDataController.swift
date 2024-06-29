//
//  RegionPickerDataController.swift
//  RegionPicker
//
//  Created by Joshua Asbury on 29/6/2024.
//

import Foundation
import class UIKit.UIMenu
import class UIKit.UIDeferredMenuElement
import class UIKit.UIAction

class RegionPickerDataController {
    typealias GroupingBy = RegionPickerViewController.Grouping
    
    private typealias Copy = L10n.RegionPicker
    
    private static let currentSectionID = UUID().uuidString
    private static let unknownSection = "?"
    
    var searchTerm: String? {
        didSet {
            guard searchTerm != oldValue else { return }
            
            // Check if resetting search
            guard let searchTerm, !searchTerm.isEmpty else {
                sections = Self.buildSections(from: dataStore, groupingBy: groupingBy)
                return
            }
            
            // Ok, perform a search
            var result: [RegionPickerItem] = []
            
            for section in Self.buildSections(from: dataStore, groupingBy: .countries, includeCurrent: false) {
                for var item in section.items {
                    guard let title = item.title, let range = title.localizedStandardRange(of: searchTerm) else { continue }
                    item.searchMatchRange = NSRange(range, in: title)
                    result.append(item)
                }
            }
            
            sections = [RegionPickerSection(id: Self.currentSectionID, fixedTitle: "", items: result)]
        }
    }
    
    var groupingBy: GroupingBy {
        didSet {
            if groupingBy != oldValue {
                sections = Self.buildSections(from: dataStore, groupingBy: groupingBy)
            }
        }
    }
    
    var selectedRegionCodeIndexPath: IndexPath? {
        guard let currentSelection else { return nil }
        for (sectionIndex, section) in sections.enumerated() {
            if let itemIndex = section.items.firstIndex(where: { $0.regionCode == currentSelection.regionCode }) {
                return IndexPath(item: itemIndex, section: sectionIndex)
            }
        }
        // Not found
        return nil
    }
    
    @Published var sections: [RegionPickerSection] = []
    
    private var currentSelection: RegionPickerItem?
    
    private let dataStore: RegionDataStore
    
    init(groupingBy: GroupingBy, selectedRegionCode: String?, dataStore: RegionDataStore = .init()) {
        self.dataStore = dataStore
        self.groupingBy = groupingBy
        sections = Self.buildSections(from: dataStore, groupingBy: groupingBy)
        if let selectedRegionCode {
            currentSelection = RegionPickerItem(id: selectedRegionCode, regionCode: selectedRegionCode)
        }
    }
    
    // MARK: API Functions
    
    func groupByMenu() -> UIMenu {
        return UIMenu(title: Copy.GroupingMenu.title, options: [.singleSelection, .displayInline], children: [
            // Create a dynamic menu that shows the selection state of action items based on the current grouping
            UIDeferredMenuElement.uncached { [unowned self] completion in
                completion([
                    UIAction(title: Copy.GroupingMenu.countryName, state: groupingBy == .countries ? .on : .off) { [unowned self] _ in
                        groupingBy = .countries
                    },
                    UIAction(title: Copy.GroupingMenu.continents, state: groupingBy == .continents ? .on : .off) { [unowned self] _ in
                        groupingBy = .continents
                    },
                    UIAction(title: Copy.GroupingMenu.subregions, state: groupingBy == .subregion ? .on : .off) { [unowned self] _ in
                        groupingBy = .subregion
                    },
                ])
            },
        ])
    }
    
    func isItemCurrentSelection(_ item: RegionPickerItem) -> Bool {
        item.regionCode == currentSelection?.regionCode
    }
    
    func indexTitles(_ locale: Locale = .current) -> [String]? {
        // Continents and sub-continents don't have unique first characters
        guard groupingBy == .countries else { return nil }
        // Don't show index titles if the user is searching
        if let searchTerm, !searchTerm.isEmpty { return nil }
        
        var indexTitle: [String] = []
        for section in sections {
            guard let title = section.title else { continue }
            
            if section.id == Self.currentSectionID {
                indexTitle.insert("◆", at: 0)
            } else if let char = title.first {
                indexTitle.append(String(char))
            }
        }
        return indexTitle
    }
    
    // MARK: Helpers
    
    private static func buildSections(from dataStore: RegionDataStore, groupingBy grouping: GroupingBy, includeCurrent: Bool = true) -> [RegionPickerSection] {
        let continents = dataStore.continents
        
        var result: [RegionPickerSection] = []
        
        switch grouping {
        case .continents:
            for continent in continents {
                let items = continent.subregions.lazy
                    .flatMap(\.countries)
                    .map(RegionPickerItem.init(regionIdentifier:))
                    .sorted()
                let identifier = RegionPickerSection(regionIdentifier: continent.identifier, items: items)
                result.append(identifier)
            }
            
        case .subregion:
            for continent in continents {
                for subregion in continent.subregions {
                    let items = subregion.countries.lazy
                        .map(RegionPickerItem.init(regionIdentifier:))
                        .sorted()
                    let identifier = RegionPickerSection(regionIdentifier: subregion.identifier, items: items)
                    result.append(identifier)
                }
            }
            
        case .countries:
            var sections: [String: [RegionPickerItem]] = [:]
            for continent in continents {
                for subregion in continent.subregions {
                    for country in subregion.countries {
                        let country = RegionPickerItem(regionIdentifier: country)
                        let section = if let id = country.title?.prefix(1) {
                            // Fold the diacritics away so that characters like Å are grouped with A
                            String(id).folding(options: .diacriticInsensitive, locale: .current)
                        } else { Self.unknownSection }
                        sections[section, default: []].append(country)
                    }
                }
            }
            for (section, items) in sections {
                let sectionIdentifier = RegionPickerSection(fixedTitle: section, items: items.sorted())
                result.append(sectionIdentifier)
            }
        }
        
        // Ensure the sections are sorted by their title
        result.sort()
        
        // Insert the current region at the top
        if includeCurrent, let currentRegion = Locale.current.region?.identifier {
            let section = RegionPickerSection(id: Self.currentSectionID, fixedTitle: Copy.Sections.current, items: [
                // Append "_Current" to ensure the ID is unique in the list, otherwise it wouldn't
                // show up as the region HAS appeared in another section.
                RegionPickerItem(id: currentRegion + "_Current", regionCode: currentRegion),
            ])
            result.insert(section, at: 0)
        }
        
        return result
    }
}
