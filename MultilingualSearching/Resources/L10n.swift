//
//  L10n.swift
//  RegionPicker
//
//  Created by Joshua Asbury on 29/6/2024.
//

enum L10n {
    enum Main {
        static var noRegionSelected: String {
            String(localized: "main.noRegionSelected", defaultValue: "No region selected")
        }
        
        static var showRegionPicker: String {
            String(localized: "main.showRegionPicker", defaultValue: "Show region picker")
        }
    }
    
    enum RegionPicker {
        static var title: String {
            String(localized: "regionPicker.title", defaultValue: "Select your region")
        }
        
        enum Sections {
            static var current: String {
                String(localized: "regionPicker.sections.deviceCurrent", defaultValue: "Device Current")
            }
        }
        
        enum GroupingMenu {
            static var title: String {
                String(localized: "regionPicker.groupingMenu.title", defaultValue: "Group by")
            }
            
            static var continents: String {
                String(localized: "regionPicker.groupingMenu.continents", defaultValue: "Continents")
            }
            
            static var subregions: String {
                String(localized: "regionPicker.groupingMenu.subregions", defaultValue: "Subregions")
            }
            
            static var countryName: String {
                String(localized: "regionPicker.groupingMenu.countryName", defaultValue: "Country name")
            }
        }
    }
}
