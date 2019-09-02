//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//


import Foundation
import UIKit
import Photos
import KVFetcher
import RxSwift
import RxCocoa

extension QuickPicker {
    
    /// He
    /// - allowedMedia: What media is allowed to be picked (image/video/both)
    /// - picking: Selection mode - can be single or multiple (with limit or unlimited).
    /// - customTabKinds: Options that appear in the segmented control (nil = DEFAULT: recently added, favorites, albums, iCloud albums, smartAlbums)
    /// - needsConfirmation: Should display a popup where user can review picked photo(s)
    /// - showsLimit: If limited count, display how many photos remaining or don't
    /// - preselected: Assets that should be selected in advance
    /// - presentFirstOfferMoreLater: Start as picking single item, go onto review screen when item is picked and then offer to pick more items (multiple). Selection has to be set to multple.
    /// - completion: Executes when user finished picking items. Delegate may be used instead.
    internal class ViewModel {
        
        public var config: Config = .random
        
        // MARK: Private
        
        private var imageManager = PHCachingImageManager()
        private var bag = DisposeBag()
        private var toolbarModel: QPToolbarViewModel!
        private var cachedCollectionFetchResults = [PHAssetCollection: PHFetchResult<PHAsset>]()
        private var tabViewModels: [TabKind: TabViewModel] = [:]
        
        // MARK: Calculated
        
        /// Latest selection in the undo stack
        var latestSelection: Set<PHAsset> {
            return selectionStack.value.last ?? []
        }
        
        /// Count of the latest selection
        var selectionCount: Int {
            return latestSelection.count
        }
        
        /// If selection mode is multiple and present first is enabled - offer first one.
        var shouldPresentFirst: Bool {
            return config.presentFirstOfferMoreLater && config.needsConfirmation
                && selectionStack.v.count == 1 && selectionCount == 1
        }
        
        // MARK: - Reactive
        
        lazy var selectionStack: BehaviorRelay<[Set<PHAsset>]> = .init(value: .init())
        lazy var reviewViewModel: BehaviorRelay<ReviewViewModel?> = .init(value: nil)
        lazy var userError: BehaviorRelay<String?> = .init(value: nil)
        lazy var itemViewModel: BehaviorRelay<ItemViewModel?> = .init(value: nil)
        lazy var selectedTabKind: BehaviorRelay<TabKind> = .init(value: .groupRegular)
        lazy var maxItemSize: BehaviorRelay<CGFloat> = .init(value: 100.0)
        
        
        // MARK: Observables
        
        lazy var onFinish: PublishSubject<QuickPicker.Result> = .init()
        lazy var onUndo: PublishSubject<Bool> = .init()
        
        lazy var selection: Observable<Set<PHAsset>> = selectionStack
            .asObservable()
            .map { $0.last ?? [] }
        
        
        // MARK: - Initialization
        
        public init(config: Config, preselected: [PHAsset]?) {
            self.config = config
            setupTabModels()
            setupBindings()
            if let preselected = preselected, !preselected.isEmpty {
                selectionStack.accept([Set(preselected)])
            }
        }
        
        func setupTabModels() {
            for kind in config.tabKinds {
                let result = PHAssetCollection.fetchAssetCollections(with: kind.type,
                                                                     subtype: kind.subtype,
                                                                     options: nil)
                let collections = result.objects(at: .init(0..<result.count))
                if kind.isSingle {
                    let itemViewModel = ItemViewModel(
                        kind: kind,
                        collection: collections.first!,
                        allowedMedia: config.allowedMedia,
                        selectionMode: config.selectionMode,
                        maxItemSize: config.maximumThumbnailSize,
                        delegateSelected: selectionStack,
                        fetchResult: nil
                    )
                    tabViewModels[kind] = itemViewModel
                } else {
                    let albumViewModel = AlbumViewModel(
                        kind: kind,
                        collections: collections
                    )
                    albumViewModel.selectedCollection.bind(onNext: open).disposed(by: bag)
                    tabViewModels[kind] = albumViewModel
                }
            }
        }
        
        func setupBindings() {
            selection
                .bind(onNext: selectedChanged(assets:))
                .disposed(by: bag)
        }
        
        
        // MARK: - Interaction
        
        /// Creates an ItemViewModel object and displays selected collection.
        func open(collection: PHAssetCollection) {
            open(collection: collection, animated: true)
        }
        
        func open(collection: PHAssetCollection, animated: Bool) {
            let ivm = ItemViewModel(kind: selectedTabKind.value,
                                    collection: collection,
                                    allowedMedia: config.allowedMedia,
                                    selectionMode: config.selectionMode,
                                    maxItemSize: config.maximumThumbnailSize,
                                    delegateSelected: selectionStack,
                                    fetchResult: cachedCollectionFetchResults[collection])
            itemViewModel.accept(ivm)
        }
        
        /// RX - Called when selected assets change.
        func selectedChanged(assets: Set<PHAsset>) {
            if config.selectionMode == .single && !assets.isEmpty {
                askConfirmation(with: Array(assets))
            } else if shouldPresentFirst {
                proceed()
            }
        }
        
        func tabViewModel(for kind: TabKind) -> TabViewModel! {
            return tabViewModels[kind]
        }
        
        /// Removes last selection (set) from selectionStack
        public func undo() {
            guard !selectionStack.value.isEmpty else { return }
            let withoutLast = selectionStack.value.removingLast()
            selectionStack.accept(withoutLast)
            onUndo.onNext(true)
        }
        
        /// Dismisses the QuickPicker
        public func cancel() {
            onFinish.onNext(.canceled)
            //delegate?.quickPickerDidCancel(/*self*/)
            //completion?(.canceled)
        }
        
        /// Asks for confirmation, if not needed executes QuickPicker's completion closure
        func proceed() {
            guard !(selectionCount == 0) else { return }
            if config.selectionMode != .single && selectionCount > config.selectionMode.max {
                return userError.accept("Too Many")
            }
            
            let assets = latestSelection.sorted { $0.creationDate! < $1.creationDate! }
            askConfirmation(with: assets)
        }
        
        
        func askConfirmation(with assets: [PHAsset]) {
            guard config.needsConfirmation else { return complete(with: assets) }
            let canAddMore = config.selectionMode != .single && config.presentFirstOfferMoreLater
            reviewViewModel.v = .init(assets: assets, canAddMore: canAddMore) {  result, assets in
                switch result {
                case .wantsMore:
                    break
                case .confirmed:
                    self.complete(with: assets)
                case .canceled:
                    if self.selectionCount == 1 {
                        self.undo()
                    }
                }
            }
        }
        
        
        func complete(with assets: [PHAsset]) {
            //delegate?.quickPicker(/*self, */didFinishPickingAssets: assets)
            //completion?(.finished(assets: assets))
            onFinish.onNext(.finished(assets: assets))
        }
        
        
        /// Gets called when user reenters the app and checks for deleted photos/videos.
        func checkForDeletedAssetsFromUndoStack() {
            var allAssets = Set<PHAsset>()
            let selections = selectionStack.value
            selections.forEach { allAssets.formUnion($0) }
            let deletedAssets = PHAsset.findMissingAssets(in: Array(allAssets))
            guard !deletedAssets.isEmpty else { return }
            let clearedSelections = selections.map { $0.subtracting(deletedAssets) }
            selectionStack.accept(clearedSelections)
        }
        
    }

}
