//
//  ItemView.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import KVFetcher
import RxSwift
import RxCocoa

class ItemOrAlbumViewModel {
    
    var kind: TabKind = .groupRegular
}

class ItemViewModel: ItemOrAlbumViewModel {
    
    typealias ImageFetcher = QPImageFetcher
    
    //static let selectAllButtonImages = ["selectAll", "deselectAll"].map(loadBundledImage).map { $0.template }


    enum PreviewResult {
        case image(_ image: UIImage?)
        case video(_ url: URL!)
    }
    
    // MARK: - Reactive properties:
    
    var bag = DisposeBag()
    
    
    var maxItemSize: BehaviorRelay<[UIUserInterfaceIdiom: CGFloat]?> = .init(value: nil)
    
    var allowedMedia: BehaviorRelay<QuickPicker.AllowedMedia>
    var selectionMode: BehaviorRelay<QuickPicker.SelectionMode>
    var isNewestOnTop: BehaviorRelay<Bool>
    var collection: BehaviorRelay<PHAssetCollection>
    var fetchResult: BehaviorRelay<PHFetchResult<PHAsset>>!
    var selectedAssetsUndoStack: BehaviorRelay<[Set<PHAsset>]> = .init(value: [])
    
    // MARK: Observables
    
    lazy var rxIsAllSelected: Observable<Bool> = selectedAssetsUndoStack.asObservable().map { _ in
        return self.checkAllSelected
    }
    lazy var selectAllButtonImage: Observable<UIImage> = rxIsAllSelected.map { isAllSelected in
        return ItemView.SelectAllButtonImages.image(for: isAllSelected)
    }
    lazy var title: Observable<String> = collection.map { collection in
        return collection.localizedTitle ?? ""
    }
    
    // MARK: - Non-reactive properties
    

    private var imageFetcher: ImageFetcher.Caching!
    private var assetFetcher: QPCachedAssetFetcher!
    private var cellViewModels: [IndexPath: ItemCellViewModel] = [:]
 
    // MARK: Calculated
    
    private var selectedAssets: Set<PHAsset> {
        return selectedAssetsUndoStack.value.last ?? []
    }
    
    var checkAllSelected: Bool {
        // If there's a cell (loaded) that isn't selected then false:
        if cellViewModels.contains(where: { $0.value.isSelected.value == false }) { return false }
        
        // Load assets and check if all are selected:
        let allAssetsHere = assetFetcher.fetchSynchronouslyMultiple(Array(0 ..< fetchResult.v.count))
        
        return Set(allAssetsHere).isSuperset(of: selectedAssets)
    }
    
    var numberOfItems: Int {
        return fetchResult.v.count
    }
    
    var allowsMultipleSelection: Bool {
        return selectionMode.v == .single ? false : true
    }
    
    
    // MARK: - Init
    
    init(kind: TabKind,
         collection: PHAssetCollection,
         allowedMedia: QuickPicker.AllowedMedia,
         selectionMode: QuickPicker.SelectionMode,
         maxItemSize optMaxItemSize: [UIUserInterfaceIdiom: CGFloat]?,
         delegateSelected: BehaviorRelay<[Set<PHAsset>]> = .init(value: .init()),
         fetchResult: PHFetchResult<PHAsset>?,
         isNewestOnTop: Bool = true) {
        self.allowedMedia = .init(value: allowedMedia)
        self.isNewestOnTop = .init(value: isNewestOnTop)
        self.collection = .init(value: collection)
        self.selectionMode = .init(value: selectionMode)
        self.selectedAssetsUndoStack = delegateSelected
        super.init()
        self.kind = kind
        self.reloadCollection()
        self.maxItemSize.accept(optMaxItemSize)
        
        selectedAssetsUndoStack.bind(onNext: updateSelectedCells).disposed(by: bag)
        assetFetcher.fetchSynchronouslyMultiple(Array(0 ..< min(100, self.fetchResult.v.count) ))
    
    }
    
    func reloadCollection() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: !isNewestOnTop.v)]
        fetchOptions.predicate = allowedMedia.v.fetchPredicate
        let fetchResultValue = PHAsset.fetchAssets(in: collection.v, options: fetchOptions)
        if fetchResult == nil {
            fetchResult = .init(value: fetchResultValue)
        } else {
            fetchResult.accept(fetchResultValue)
        }
        imageFetcher = .init(deliveryMode: .fastFormat, cacher: .init(maxCount: 10_000))
        cellViewModels = [:]
        assetFetcher = .init(phFetchResult: fetchResult.v, cacher: .unlimited)
    }
    
    func updateSelectedCells(selections: [Set<PHAsset>]) {
        guard self.allowsMultipleSelection else { return }
        guard let selected = selections.last, !selected.isEmpty else {
            cellViewModels.values.forEach { $0.isSelected.accept(false) }
            return
        }
        cellViewModels.values.forEach { $0.isSelected.v = selected.contains($0.item.v) }
    }

    
    // MARK: - Modify Selection and Interaction
    
    
    func updateSelectedAssets(add sel: [PHAsset], remove des: [PHAsset]) {
        selectedAssetsUndoStack.acceptAppending(selectedAssets.subtracting(des).union(sel))
    }
    
    
    func modifyCells(at indexPathSelectedDict: [IndexPath: Bool]) {
        guard allowsMultipleSelection else { return }
        let selected = indexPathSelectedDict.filter { $0.value }.map { assetFetcher.fetchSynchronously($0.key.row)! }
        let deselected = indexPathSelectedDict.filter { !$0.value }.map { assetFetcher.fetchSynchronously($0.key.row)! }
        updateSelectedAssets(add: selected, remove: deselected)
    }
    
    func tappedIndexPath(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        let asset = assetFetcher.fetchSynchronously(indexPath.row)!
        let cellViewModel = cellViewModels[indexPath]!
        guard allowsMultipleSelection else {
            updateSelectedAssets(add: [asset], remove: [])
            return
        }
        let wasSelected = selectedAssets.contains(cellViewModel.item.v)
        !wasSelected ? updateSelectedAssets(add: [asset], remove: []) : updateSelectedAssets(add: [], remove: [asset])
    }
    
    
    func selectAll() {
        let shouldSelectAll = !checkAllSelected
        let lastSelected = selectedAssets
        let allAssetsHere = assetFetcher.fetchSynchronouslyMultiple(Array(0..<fetchResult.v.count)) as! [PHAsset]
        let newSelected = shouldSelectAll ? lastSelected.union(allAssetsHere) : lastSelected.subtracting(allAssetsHere)
        selectedAssetsUndoStack.v.append(newSelected)
        for cell in cellViewModels.values {
            cell.isSelected.v = shouldSelectAll
        }
    }
    
    
    // MARK: - Public getters:
    
    func cellModel(for indexPath: IndexPath) -> ItemCellViewModel {
        let asset = assetFetcher.fetchSynchronously(indexPath.row)!
        let isSelected = selectedAssets.contains(asset)
        if let existing = cellViewModels[optional: indexPath] {
            existing.isSelected.accept(isSelected)
            return existing
        }
        let cellViewModel = ItemCellViewModel(item: asset,
                                              isSelected: isSelected,
                                              selectionStyle: .checkmark,
                                              imageFetcher: imageFetcher)
        cellViewModels[indexPath] = cellViewModel
        return cellViewModel
    }
    
    
    func itemSize(at indexPath: IndexPath) -> CGSize {
        let a = assetFetcher.fetchSynchronously(indexPath.row)!
        return .init(width: a.pixelWidth, height: a.pixelHeight)
    }
    
    
    func getPreview(at indexPath: IndexPath, completion: @escaping (PreviewResult) -> Void) {
        let asset = assetFetcher.fetchSynchronously(indexPath.row)!
        switch asset.mediaType {
        case .image:
            imageFetcher.fetchValue(for: asset, priority: .now) { (image) in
                completion(.image(image))
            }
        case .video:
            PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (asset, _, _) in
                mainThread {
                    let url = (asset as? AVURLAsset)?.url
                    completion(.video(url))
                }
            }
        default: completion(.image(nil))
        }
    }
    
}
