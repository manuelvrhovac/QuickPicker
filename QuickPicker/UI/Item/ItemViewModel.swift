//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import KVFetcher
import RxSwift
import RxCocoa

/// Could be either ItemViewModel or AlbumViewModel. Can be put into a tab (segmented control).
class TabViewModel {
    
    var kind: TabKind = .groupRegular
    var title: String {
        return ""
    }
}

class ItemViewModel: TabViewModel {
    
    // MARK: - Properties

    private var imageFetcher: QPImageFetcher!
    private var assetFetcher: QPCachedAssetFetcher
    private var cellViewModels: [IndexPath: ItemCellViewModel] = [:]
    private var bag = DisposeBag()
    private var collection: PHAssetCollection!
    private var allowedMedia: AllowedMedia
    private var selectionMode: SelectionMode
    
    
    // MARK: Calculated
    
    private var latestAssetSelection: Set<PHAsset> {
        return selectedAssetsUndoStack.value.last ?? []
    }
    
    public override var title: String {
        return collection.localizedTitle ?? "Unknown Collection"
    }
    
    var checkAllSelected: Bool {
        // If there's a cell (loaded) that isn't selected then false:
        if cellViewModels.contains(where: { $0.value.isSelected.value == false }) { return false }
        
        // Load assets and check if all are selected:
        let allAssetsHere = assetFetcher[0 ..< fetchResult.v.count]
        
        return Set(allAssetsHere).isSuperset(of: latestAssetSelection)
    }
    
    var numberOfItems: Int {
        return fetchResult.v.count
    }
    
    var allowsMultipleSelection: Bool {
        return selectionMode == .single ? false : true
    }
    
    // MARK: - Reactive
    
    var maxItemSize: BehaviorRelay<[UIUserInterfaceIdiom: CGFloat]?> = .init(value: nil)
    var isNewestOnTop: BehaviorRelay<Bool>
    var fetchResult: BehaviorRelay<PHFetchResult<PHAsset>>!
    var selectedAssetsUndoStack: BehaviorRelay<[Set<PHAsset>]> = .init(value: [])
    
    
    // MARK: Observables
    
    lazy var rxIsAllSelected: Observable<Bool> = selectedAssetsUndoStack.asObservable()
        .map { _ in return self.checkAllSelected }
    
    lazy var selectAllButtonImage: Observable<UIImage> = rxIsAllSelected
        .map { return ItemView.SelectAllButtonImages.image(for: $0) }
    
    
    // MARK: - Init
    
    init(kind: TabKind,
         collection: PHAssetCollection,
         allowedMedia: AllowedMedia,
         selectionMode: SelectionMode,
         maxItemSize optMaxItemSize: [UIUserInterfaceIdiom: CGFloat]?,
         delegateSelected: BehaviorRelay<[Set<PHAsset>]> = .init(value: .init()),
         fetchResult: PHFetchResult<PHAsset>?,
         isNewestOnTop: Bool = true) {
        self.allowedMedia = allowedMedia
        self.isNewestOnTop = .init(value: isNewestOnTop)
        self.collection = collection
        self.selectionMode = selectionMode
        self.selectedAssetsUndoStack = delegateSelected
        self.assetFetcher = .init(phFetchResult: .init(), cacher: .unlimited)
        super.init()
        self.kind = kind
        
        self.reloadCollection()
        self.maxItemSize.accept(optMaxItemSize)
        
        setupBindings()
        
        /// Preload 50 first items
        _ = assetFetcher[0 ..< min(50, self.fetchResult.v.count)]
    }
    
    
    func setupBindings() {
        selectedAssetsUndoStack
            .bind(onNext: updateSelectedCells)
            .disposed(by: bag)
        
        isNewestOnTop
            .map { _ in }
            .bind(onNext: reloadCollection)
            .disposed(by: bag)
    }
    
    func reloadCollection() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: !isNewestOnTop.v)]
        fetchOptions.predicate = allowedMedia.fetchPredicate
        let fetchResultValue = PHAsset.fetchAssets(in: collection, options: fetchOptions)
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
    
    func updateSelectedAssets(adding sel: [PHAsset], removing des: [PHAsset]) {
        let newSelection = latestAssetSelection.subtracting(des).union(sel)
        selectedAssetsUndoStack.acceptAppending(newSelection)
    }
    
    func modifyCells(at indexPathSelectedDict: [IndexPath: Bool]) {
        guard allowsMultipleSelection else { return }
        let selected = indexPathSelectedDict.filter { $0.value }.map { assetFetcher[$0.key.row] }
        let deselected = indexPathSelectedDict.filter { !$0.value }.map { assetFetcher[$0.key.row] }
        updateSelectedAssets(adding: selected, removing: deselected)
    }
    
    func tappedIndexPath(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        let asset = assetFetcher[indexPath.row]
        let cellViewModel = cellViewModels[indexPath]!
        guard allowsMultipleSelection else {
            updateSelectedAssets(adding: [asset], removing: [])
            return
        }
        if !latestAssetSelection.contains(cellViewModel.item.v) {
            updateSelectedAssets(adding: [asset], removing: [])
        } else {
            updateSelectedAssets(adding: [], removing: [asset])
        }
    }
    
    /// Executes in cases of "selectAll" and "deselectAll"
    func selectAll() {
        let shouldSelectAll = !checkAllSelected
        let allAssetsHere = assetFetcher[0 ..< fetchResult.v.count]
        let newSelected = shouldSelectAll
            ? latestAssetSelection.union(allAssetsHere)
            : latestAssetSelection.subtracting(allAssetsHere)
        selectedAssetsUndoStack.v.append(newSelected)
        for cell in cellViewModels.values {
            cell.isSelected.v = shouldSelectAll
        }
    }
    
    
    // MARK: - Public getters:
    
    func cellModel(for indexPath: IndexPath) -> ItemCellViewModel {
        let asset = assetFetcher[indexPath.row] // .fetchSyncrhonously
        let isSelected = latestAssetSelection.contains(asset)
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
        let a = assetFetcher[indexPath.row]
        return .init(width: a.pixelWidth, height: a.pixelHeight)
    }
    
    
    func getPreview(at indexPath: IndexPath, completion: @escaping (PreviewResult) -> Void) {
        let asset = assetFetcher[indexPath.row]
        switch asset.mediaType {
        case .image:
            imageFetcher.fetchValue(for: asset, priority: .now) { (image) in
                completion(.image(image))
            }
        case .video:
            PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { (asset, _, _) in
                mainThread {
                    let url = (asset as? AVURLAsset)?.url
                    completion(.video(url))
                }
            }
        default: completion(.image(nil))
        }
    }
    
}


extension ItemViewModel {
    
    enum PreviewResult {
        case image(_ image: UIImage?)
        case video(_ url: URL!)
    }
}
