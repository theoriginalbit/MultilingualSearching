//
//  RegionPickerViewController.swift
//  RegionPicker
//
//  Created by Joshua Asbury on 29/6/2024.
//

import Combine
import UIKit

class RegionPickerViewController: UIViewController, UICollectionViewDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    // MARK: Types
    
    enum Grouping: Equatable {
        case countries
        case continents
        case subregion
    }
    
    protocol Delegate: AnyObject {
        func regionPickerViewController(_ viewController: RegionPickerViewController, didSelectRegionCode regionCode: String)
    }
    
    private class DataSource: UICollectionViewDiffableDataSource<RegionPickerSection, RegionPickerItem> {
        weak var dataController: RegionPickerDataController?
        
        override func indexTitles(for collectionView: UICollectionView) -> [String]? {
            assert(dataController != nil, "DataSource did not have dataController set")
            return dataController?.indexTitles()
        }
        
        override func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
            // This API has always confused me, who would ever have an index view that didn't share the
            // same element order as the titles and section index paths
            IndexPath(item: 0, section: index)
        }
    }
    
    // MARK: Convenience aliases
    
    private typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, RegionPickerItem>
    private typealias HeaderCellRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>
    private typealias Copy = L10n.RegionPicker
    
    // MARK: Properties
    
    private let dataSource: DataSource
    private let searchController = UISearchController()
    private let collectionView: UICollectionView
    private let dataController: RegionPickerDataController
    private let groupByBarButtonItem: UIBarButtonItem
    
    private var dataCancellable: AnyCancellable?
    
    weak var delegate: Delegate?
    
    // MARK: Initialization
    
    init(groupingBy: Grouping = .countries, selectedRegionCode: String? = nil) {
        dataController = RegionPickerDataController(groupingBy: groupingBy, selectedRegionCode: selectedRegionCode)
        groupByBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), menu: dataController.groupByMenu())
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: RegionPickerViewController.createLayout(searchController: searchController))
        
        let cellRegistration = CellRegistration { [unowned dataController] cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            
            // I'd love to use AttributedString here for a nicer API, but it seems to have no way
            // to use a Range<String.Index> as the subscript, which is what is returned by the
            // localizedStandardRange (a.k.a. how search is done)
            let attributedName = NSMutableAttributedString(string: item.title ?? "", attributes: [
                .foregroundColor: item.searchMatchRange == nil ? UIColor.label : UIColor.secondaryLabel,
                .font: UIFont.preferredFont(forTextStyle: .body),
            ])
            if let searchMatchRange = item.searchMatchRange {
                attributedName.addAttribute(.foregroundColor, value: UIColor.systemRed, range: searchMatchRange)
            }
            configuration.attributedText = attributedName
            cell.contentConfiguration = configuration
            cell.accessories = dataController.isItemCurrentSelection(item) ? [.checkmark(displayed: .always)] : []
        }
        dataSource = DataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        })
        
        super.init(nibName: nil, bundle: nil)
        
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        
        // it would be really confusing if we had a close/cancel button ourselves, and
        // then the search bar also pops up a cancel when being edited. So just use the
        // search bar cancel.
        searchController.searchBar.showsCancelButton = true
        
        // Place the search bar in the navigation bar.
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.preferredSearchBarPlacement = .stacked
        
        let headerRegistration = HeaderCellRegistration(elementKind: UICollectionView.elementKindSectionHeader) { [unowned dataSource] headerView, _, indexPath in
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            var configuration = headerView.defaultContentConfiguration()
            configuration.text = section.title
            headerView.contentConfiguration = configuration
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        
        dataSource.dataController = dataController
        collectionView.delegate = self
        
        title = Copy.title
        navigationItem.setLeftBarButton(groupByBarButtonItem, animated: true)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    
    override func loadView() {
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.keyboardDismissMode = .onDragWithAccessory
        view = collectionView
    }
    
    override func viewDidLoad() {
        // Initial data
        applySnapshot(using: dataController.sections, animatingDifferences: false)
        
        // Changes to data
        dataCancellable = dataController.$sections.receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] data in
                applySnapshot(using: data, animatingDifferences: true)
            })
    }
    
    // MARK: Implementation
    
    private func applySnapshot(using sections: [RegionPickerSection], animatingDifferences: Bool) {
        var snapshot = DataSource.Snapshot()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.items, toSection: section)
            snapshot.reconfigureItems(section.items)
        }
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            guard let self else { return }
            // don't scroll to the index path if its the top section, use the scroll to top implementation instead
            if let selectedIndexPath = dataController.selectedRegionCodeIndexPath, selectedIndexPath.section != 0 {
                collectionView.scrollToItem(at: selectedIndexPath, at: .top, animated: animatingDifferences)
            } else {
                // make sure we respect safe areas
                let topInset = collectionView.safeAreaInsets.top
                collectionView.setContentOffset(CGPoint(x: 0, y: -topInset), animated: animatingDifferences)
            }
        }
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer { collectionView.deselectItem(at: indexPath, animated: true) }
        if let item = dataSource.itemIdentifier(for: indexPath) {
            delegate?.regionPickerViewController(self, didSelectRegionCode: item.regionCode)
        }
    }
    
    // MARK: UISearchControllerDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        groupByBarButtonItem.isHidden = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        groupByBarButtonItem.isHidden = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // it would be really confusing if we had a close/cancel button ourselves, and
        // then the search bar also pops up a cancel when being edited. So just use the
        // search bar cancel.
        presentingViewController?.dismiss(animated: true)
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        dataController.searchTerm = searchController.searchBar.text
    }
    
    // MARK: UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: Layout Helper
    
    static func createLayout(searchController: UISearchController) -> UICollectionViewLayout {
        // Use a dynamic provider so the configuration can change based on interaction with search
        return UICollectionViewCompositionalLayout { _, layoutEnvironment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            let searchText = searchController.searchBar.text ?? ""
            if searchText.isEmpty {
                // When the user isn't searching, show section headers
                configuration.headerMode = .supplementary
            }
            return .list(using: configuration, layoutEnvironment: layoutEnvironment)
        }
    }
}
