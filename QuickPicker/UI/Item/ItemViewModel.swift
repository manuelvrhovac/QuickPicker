//
//  ItemView.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//
/*
import Foundation
import Photos
import KVFetcher
 
 
 
 
 ???
 
 
 /*
 protocol ItemViewModelDelegate: class {
 
 func itemViewModel(_ itemViewModel: ItemViewModel, didSelect selectedItems: [PHAsset], andDeselect deselectedItems: [PHAsset])
 func selection(for itemViewModel: ItemViewModel) -> Set<PHAsset>
 }
 
 extension ItemViewModelDelegate {
 
 func itemViewModel(_ itemViewModel: ItemViewModel, didSelect items: [PHAsset]) {
 self.itemViewModel(itemViewModel, didSelect: true, items: items)
 }
 func itemViewModel(_ itemViewModel: ItemViewModel, didDeselect items: [PHAsset]) {
 self.itemViewModel(itemViewModel, didSelect: false, items: items)
 }
 
 func itemViewModel(_ itemViewModel: ItemViewModel, didSelect select: Bool, items: [PHAsset]) {
 var selected: [PHAsset] = []
 var deselected: [PHAsset] = []
 if select {
 selected = items
 } else {
 deselected = items
 }
 self.itemViewModel(itemViewModel, didSelect: selected, andDeselect: deselected)
 }
 }
 */
 
 ??
 
 
 
 
 

protocol ItemViewModelDelegate: class {
 
    func itemViewModel(_ itemViewModel: ItemViewModel, didSelect selectedItems: [PHAsset], andDeselect deselectedItems: [PHAsset])
    func selectedAssets(for itemViewModel: ItemViewModel) -> Set<PHAsset>
}

extension ItemViewModelDelegate {
 
    func itemViewModel(_ itemViewModel: ItemViewModel, didSelect items: [PHAsset]) {
        self.itemViewModel(itemViewModel, didSelect: true, items: items)
    }
    func itemViewModel(_ itemViewModel: ItemViewModel, didDeselect items: [PHAsset]) {
        self.itemViewModel(itemViewModel, didSelect: false, items: items)
    }
    
    func itemViewModel(_ itemViewModel: ItemViewModel, didSelect select: Bool, items: [PHAsset]) {
        var selected: [PHAsset] = []
        var deselected: [PHAsset] = []
        if select {
            selected = items
        } else {
            deselected = items
        }
        self.itemViewModel(itemViewModel, didSelect: selected, andDeselect: deselected)
    }
}

class ItemViewModel {
    
    
    enum PreviewResult {
        case image(_ image: UIImage?)
        case video(_ url: URL)
    }
    
    weak var delegate: ItemViewModelDelegate!
    
    var allowedMedia: QuickPicker.AllowedMedia
    var selectionMode: QuickPicker.SelectionMode  { didSet {
        onReloadFetchResult()
    } }
    var isNewestOnTop: Bool
    
    var collection: PHAssetCollection
    
    private var imageFetcher: QPImageFetcher.Caching!
    private var fetchResult: PHFetchResult<PHAsset>!{ didSet { onReloadFetchResult() }}
    private var cellViewModels: [IndexPath: ItemCellViewModel] = [:]
    
    private var assetFetcher: QPCachedAssetFetcher!
    
    var onSelectionChanged = {}
    var onReloadFetchResult = {}
    
    
    private var selectedAssets: Set<PHAsset> {
        let cachedAssets = assetFetcher.cacher.cachedResults
        return delegate?.selectedAssets(for: self).intersection(cachedAssets) ?? []
    }
    
    
    var isAllSelected: Bool {
        // If table hasn't loaded all assets then false:
        if assetFetcher.cacher.cachedElements.count != fetchResult.count { return false }
        // If there's a cell (loaded) that isn't selected then false:
        if cellViewModels.contains(where: { $0.value.isSelected.value == false}) { return false }
        // Load assets and check if all are selected:
        let allAssetsHere = (0..<fetchResult.count).map(loadAsset)
        let delegateSelected = delegate!.selectedAssets(for: self)
        return delegateSelected.isSuperset(of: allAssetsHere)
    }
    
    // MARK: - Init
    
    init(collection: PHAssetCollection, allowedMedia: QuickPicker.AllowedMedia, selectionMode: QuickPicker.SelectionMode, fetchResult: PHFetchResult<PHAsset>?, isNewestOnTop: Bool = true) {
        self.allowedMedia = allowedMedia
        self.isNewestOnTop = isNewestOnTop
        self.collection = collection
        self.selectionMode = selectionMode
        self.reloadCollection()
    }
    
    func reloadCollection() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: !isNewestOnTop)]
        fetchOptions.predicate = {
            guard allowedMedia != .imagesAndVideos else { return nil }
            return .init(format: "mediaType = \(allowedMedia.mediaTypes.first!.rawValue)")
        }()
        
        fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        imageFetcher = .init(deliveryMode: .fastFormat, cacher: .init(maxCount: 1000))
        cellViewModels = [:]
        assetFetcher = .init(phFetchResult: fetchResult, cacher: .unlimited)
        
        precache()
    }
    
    func precache() {
        // Precache 15 assets before showing:
        for row in (0..<fetchResult.count) where row < 15 {
            loadAsset(at: row)
        }
    }
    
    // MARK: - Private
    
    @discardableResult
    private func loadAsset(at row: Int) -> PHAsset {
        return assetFetcher.fetchSynchronously(row, priority: .now)!
    }
    
    @discardableResult
    private func loadAsset(at indexPath: IndexPath) -> PHAsset {
        return loadAsset(at: indexPath.row)
    }
    
    
    // MARK: - Public getters:
    
    func cellModel(for indexPath: IndexPath) -> ItemCellViewModel {
        let asset = loadAsset(at: indexPath)
        let isSelected = delegate?.selectedAssets(for: self).contains(asset) ?? false
        if let existing = cellViewModels[optional: indexPath] {
            existing.isSelected.accept(isSelected)
            return existing
        }
        let isSelectable = true
        let cellViewModel = ItemCellViewModel(item: asset,
                                              isSelected: isSelected,
                                              isSelectable: isSelectable,
                                              selectionStyle: .checkmark,
                                              imageFetcher: imageFetcher)
        cellViewModels[indexPath] = cellViewModel
        return cellViewModel
    }
    
    
    func itemSize(at indexPath: IndexPath) -> CGSize {
        let a = loadAsset(at: indexPath)
        return .init(width: a.pixelWidth, height: a.pixelHeight)
    }
    
    func modifyCells(at indexPathSelectedDict: [IndexPath : Bool]) {
        guard allowsMultipleSelection else { return }
        var assets: (sel: [PHAsset], desel: [PHAsset]) = ([], [])
        for (indexPath, isSelected) in indexPathSelectedDict {
            let cell = cellModel(for: indexPath)
            cell.isSelected.v = isSelected
            let asset = cell.item.value!
            isSelected ? assets.sel.append(asset) : assets.desel.append(asset)
        }
        delegate?.itemViewModel(self, didSelect: assets.sel, andDeselect: assets.desel)
    }
    
    func getPreview(at indexPath: IndexPath, completion: @escaping (PreviewResult) -> Void) {
        let asset = loadAsset(at: indexPath.row)
        switch asset.mediaType {
        case .image:
            imageFetcher.fetchValue(for: asset, priority: .now) { (image) in
                completion(.image(image))
            }
        case .video:
            PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (asset, audioMix, args) in
                let asset = asset as! AVURLAsset
                mainThread {
                    completion(.video(asset.url))
                }
            }
        default: completion(.image(nil))
        }
    }
    
    static let selectAllButtonImages = [UIImage(bundleNamed: "selectAll"), UIImage(bundleNamed: "deselectAll")].map { $0.template}
    var selectAllButtonImage: UIImage {
        return ItemViewModel.selectAllButtonImages[isAllSelected ? 1 : 0]
    }
    
    var numberOfItems: Int {
        return fetchResult?.count ?? 0
    }
    
    var title: String {
        return collection.localizedTitle ?? ""
    }
    
    var allowsMultipleSelection: Bool {
        return selectionMode == .single ? false : true
    }
    
    func tapped(indexPath: IndexPath) {
        let asset = loadAsset(at: indexPath.row)
        let cellViewModel = cellViewModels[indexPath]!
        guard allowsMultipleSelection else {
            delegate?.itemViewModel(self, didSelect: true, items: [asset])
            return
        }
        let wasSelected = delegate.selectedAssets(for: self).contains(cellViewModel.item.value!)
        cellViewModel.isSelected.v = !wasSelected
        delegate?.itemViewModel(self, didSelect: cellViewModel.isSelected.v, items: [asset])
        onSelectionChanged()
    }
    
    
    func selectAll() {
        let allAssets = (0..<numberOfItems).map(loadAsset)
        let shouldSelectAll = !isAllSelected
        cellViewModels.forEach{ $0.value.isSelected.v = shouldSelectAll }
        delegate?.itemViewModel(self, didSelect: shouldSelectAll, items: allAssets)
        onSelectionChanged()
    }
    
    
    
}
*/
