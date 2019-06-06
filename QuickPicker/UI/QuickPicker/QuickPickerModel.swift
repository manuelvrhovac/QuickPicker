//
//  QuickPickerModel.swift
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

public class QuickPickerModel {
    
    static let redColor = UIColor(red: 0.745, green: 0.156, blue: 0.0745, alpha: 1)

    // MARK: - Public Properties
    
    /// If not already using closure, a delegate can be used instead.
    weak var delegate: QuickPickerDelegate?
    
    /// What happens when user picks the photo(s)
    var completion: QuickPicker.Completion?
    
    /// Selection mode can be single or multiple
    var selectionMode: QuickPicker.SelectionMode
    
    /// Options that appear in the segmented control (nil = DEFAULT: recently added, favorites, albums, iCloud albums, smartAlbums)
    var tabs: [TabKind] = []
    
    /// What media is allowed to be picked (image/video/both
    var allowedMedia: QuickPicker.AllowedMedia
    
    /// Displays a popup where user can review picked photo(s)
    public var needsConfirmation: Bool
    
    /// If limited count, display how many photos remaining or don't
    var showsLimit: Bool
    
    /// If picking multiple, go onto review screen as soon as one item is picked. Offer to pick more in review screen.
    public var presentFirstOfferMoreLater: Bool
    
    public var tintColor: UIColor = .orange
    
    private var imageManager = PHCachingImageManager()
    
    private var cachedCollectionFetchResults = [PHAssetCollection: PHFetchResult<PHAsset>]()
    //var recentViewModel: ItemViewModel!
    
    
    var itemOrAlbumViewModels: [TabKind: ItemOrAlbumViewModel] = [:]

    var specialAlbumViewModels: [ItemViewModel] {
        return itemOrAlbumViewModels.valuesAs(ItemViewModel.self).sorted { $0.kind.order > $1.kind.order }
    }

    var albumViewModels: [AlbumViewModel] {
        return itemOrAlbumViewModels.valuesAs(AlbumViewModel.self).sorted { $0.kind.order > $1.kind.order }
    }
    
    
    var bag = DisposeBag()
    var tm: QPToolbarViewModel!
    
    
    // MARK: Reactive VAR
    
    lazy var selectionStack: BehaviorRelay<[Set<PHAsset>]> = .init(value: .init())
    lazy var reviewViewModel: BehaviorRelay<ReviewViewModel?> = .init(value: nil)
    lazy var userError: BehaviorRelay<String?> = .init(value: nil)
    lazy var itemViewModels: BehaviorRelay<[ItemViewModel]> = .init(value: [])
    lazy var selectedAlbumKind: BehaviorRelay<TabKind> = .init(value: .groupRegular)
    
    
    // MARK: Reactive Other
    
    lazy var selection: Observable<Set<PHAsset>> = selectionStack.asObservable().map { $0.last ?? [] }
    lazy var onFinish: PublishSubject<Bool> = .init()
    
    
    // MARK: Calculated
    
    var latestSelection: Set<PHAsset> {
        return selectionStack.value.last ?? []
    }
    
    var selectionCount: Int {
        return latestSelection.count
    }
    
    /// If selection mode is multiple and present first is enabled - offer first one.
    var shouldPresentFirst: Bool {
        return presentFirstOfferMoreLater && needsConfirmation && selectionStack.v.count == 1 && selectionCount == 1
    }
    
    var maxItemSize: BehaviorRelay<CGFloat> = .init(value: 100.0)

    
    // MARK: - Initialization
    
    public init(
        allowedMedia: QuickPicker.AllowedMedia,
        picking selectionMode: QuickPicker.SelectionMode,
        tabs: [TabKind]?,
        needsConfirmation: Bool,
        showsLimit: Bool,
        completion: QuickPicker.Completion?
        ) {
        self.completion = completion
        self.allowedMedia = allowedMedia
        self.selectionMode = selectionMode
        self.needsConfirmation = needsConfirmation
        self.showsLimit = showsLimit
        self.presentFirstOfferMoreLater = false
        self.tabs = tabs ?? QPToolbarView.albumKinds
        if self.tabs.count > 6 {
            self.tabs.removeLast(self.tabs.count - 6)
        }
        
        for kind in self.tabs {
            let result = PHAssetCollection.fetchAssetCollections(with: kind.type, subtype: kind.subtype, options: nil)
            let collections = result.objects(at: .init(0..<result.count))
            
            if kind.isSingle {
                let itemViewModel = ItemViewModel(kind: kind,
                                                  collection: collections.first!,
                                                  allowedMedia: allowedMedia,
                                                  selectionMode: selectionMode,
                                                  maxItemSize: [.pad: 150.0, .phone: 100.0],
                                                  delegateSelected: selectionStack,
                                                  fetchResult: nil)
                itemOrAlbumViewModels[kind] = itemViewModel
            } else {
                let albumViewModel = AlbumViewModel(kind: kind,
                                                    collections: collections)
                albumViewModel.selectedCollection.bind(onNext: open).disposed(by: bag)
                albumViewModel.imageManager = imageManager
                itemOrAlbumViewModels[kind] = albumViewModel
            }
        }
        selection.bind(onNext: selectedChanged(assets:)).disposed(by: bag)

        // BACKUP:
            /*
                
            case .recentlyAdded:
                guard let recentCollection = collections.first else { continue }
                let ivm =
                allViewModels.append((kind, ivm))
            case .favorites:
                guard let favCollection = collections.first else { continue }
                let ivm = ItemViewModel(collection: favCollection,
                                        allowedMedia: allowedMedia,
                                        selectionMode: selectionMode,
                                        delegateSelected: selectionStack,
                                        fetchResult: nil)
                allViewModels.append((kind, ivm))
            default:
                let albumViewModel = AlbumViewModel(kind: kind,
                                                    collections: collections)
                albumViewModel.selectedCollection.bind(onNext: open).disposed(by: bag)
                albumViewModel.imageManager = imageManager
                allViewModels.append((kind, albumViewModel))
            }*/
        
        
    }
    
    /// RX - Called when selected assets change.
    func selectedChanged(assets: Set<PHAsset>) {
        if selectionMode == .single && !assets.isEmpty {
            askConfirmation(with: Array(assets))
        } else if shouldPresentFirst {
            proceed()
        }
    }
    
    
    // MARK: - Interaction
    
    /// Creates an ItemViewModel object and displays selected collection.
    func open(collection: PHAssetCollection) { open(collection: collection, animated: true) }
    
    func open(collection: PHAssetCollection, animated: Bool) {
        let ivm = ItemViewModel(kind: selectedAlbumKind.value,
                                collection: collection,
                                allowedMedia: allowedMedia,
                                selectionMode: selectionMode,
                                maxItemSize: [.pad: 150.0, .phone: 100.0],
                                delegateSelected: selectionStack,
                                fetchResult: cachedCollectionFetchResults[collection])
        itemViewModels.acceptAppending(ivm)
    }
    
    /// Removes last selection (set) from selectionStack
    func undo() {
        guard !selectionStack.value.isEmpty else { return }
        let withoutLast = selectionStack.value.removingLast()
        selectionStack.accept(withoutLast)
    }
    
    /// Dismisses the QuickPicker
    func cancel() {
        onFinish.onNext(true)
        delegate?.quickPickerDidCancel(self)
        completion?(QuickPicker.Result.canceled)
    }
    
    /// Asks for confirmation, if not needed executes QuickPicker's completion closure
    func proceed() {
        guard !(selectionCount == 0) else { return }
        if case .multiple(let max) = selectionMode {
            guard selectionCount <= max else {
                userError.accept("Too Many")
                return
            }
        }
        
        let assets = latestSelection.sorted { $0.creationDate! < $1.creationDate! }
        askConfirmation(with: assets)
    }
    
    
    func askConfirmation(with assets: [PHAsset]) {
        guard needsConfirmation else { return complete(with: assets) }
        let canAddMore = selectionMode != .single && presentFirstOfferMoreLater
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
        delegate?.quickPicker(self, didFinishPickingAssets: assets)
        completion?(.finished(assets: assets))
        onFinish.onNext(true)
    }
    
}
