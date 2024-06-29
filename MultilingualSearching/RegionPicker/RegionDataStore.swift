//
//  RegionDataStore.swift
//  RegionPicker
//
//  Created by Joshua Asbury on 29/6/2024.
//

import Foundation

class RegionDataStore {
    struct Continent {
        let identifier: String
        var subregions: [Subregion]
    }
    
    struct Subregion {
        let identifier: String
        let countries: [String]
    }
    
    let continents: [Continent]
    
    init() {
        continents = Self.loadContinentsData()
    }
    
    static func loadContinentsData() -> [Continent] {
        var continentRelationships: [String: [String]] = [:]
        var subregionRelationships: [String: [String]] = [:]
        
        // Determine all the regions' relationships
        for region in Locale.Region.isoRegions {
            if region.identifier == "001" { continue } // exclude "world" region
            if region.continent == nil {
                continentRelationships[region.identifier] = region.subRegions.map(\.identifier)
            } else if !region.subRegions.isEmpty {
                subregionRelationships[region.identifier] = region.subRegions.map(\.identifier)
            }
        }
        
        // Build the data model, taking the relationship data and representing it as a tree
        var continents: [Continent] = []
        for (continentIdentifier, subregionIdentifiers) in continentRelationships {
            var subregions: [Subregion] = []
            for identifier in subregionIdentifiers {
                let countryIdentifiers = subregionRelationships[identifier, default: []]
                let subregion = Subregion(identifier: identifier, countries: countryIdentifiers)
                subregions.append(subregion)
            }
            let continent = Continent(identifier: continentIdentifier, subregions: subregions)
            continents.append(continent)
        }
        
        return continents
    }
}
