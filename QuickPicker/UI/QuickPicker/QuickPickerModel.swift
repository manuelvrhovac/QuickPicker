//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import KVFetcher
import RxSwift
import RxCocoa

/// He
/// - allowedMedia: What media is allowed to be picked (image/video/both)
/// - picking: Selection mode - can be single or multiple (with limit or unlimited).
/// - customTabKinds: Options that appear in the segmented control (nil = DEFAULT: recently added, favorites, albums, iCloud albums, smartAlbums)
/// - needsConfirmation: Should display a popup where user can review picked photo(s)
/// - showsLimit: If limited count, display how many photos remaining or don't
/// - preselected: Assets that should be selected in advance
/// - presentFirstOfferMoreLater: Start as picking single item, go onto review screen when item is picked and then offer to pick more items (multiple). Selection has to be set to multple.
/// - completion: Executes when user finished picking items. Delegate may be used instead.
public class QuickPickerViewModel {
    
    /// Selection mode can be single or multiple
    public var selectionMode: SelectionMode
    
    /// What media is allowed to be picked (image/video/both
    public var allowedMedia: AllowedMedia
    
    /// If limited count, display how many photos remaining or don't
    public var showsLimit: Bool
    
    /// Displays a popup where user can review picked photo(s)
    public var needsConfirmation: Bool
    
    /// What happens when user picks the photo(s)
    public var completion: Completion?
    
    /// If not already using closure, a delegate can be used instead.
    weak public var delegate: QuickPickerDelegate?
    
    /// Options that appear in the segmented control (nil = DEFAULT: recently added, favorites, albums, iCloud albums, smartAlbums)
    public var tabKinds: [TabKind] = QPToolbarView.defaultTabKinds
    
    /// If picking multiple, go onto review screen as soon as one item is picked. Offer to pick more in review screen.
    public var presentFirstOfferMoreLater: Bool
    
    /// The tint color of the QuickPicker user interface. Has to be preset before showing!
    public var tintColor: UIColor? = .orange
    
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
        return presentFirstOfferMoreLater && needsConfirmation && selectionStack.v.count == 1 && selectionCount == 1
    }
    
    // MARK: - Reactive
    
    lazy var selectionStack: BehaviorRelay<[Set<PHAsset>]> = .init(value: .init())
    lazy var reviewViewModel: BehaviorRelay<ReviewViewModel?> = .init(value: nil)
    lazy var userError: BehaviorRelay<String?> = .init(value: nil)
    lazy var itemViewModels: BehaviorRelay<[ItemViewModel]> = .init(value: [])
    lazy var selectedTabKind: BehaviorRelay<TabKind> = .init(value: .groupRegular)
    lazy var maxItemSize: BehaviorRelay<CGFloat> = .init(value: 100.0)

    
    // MARK: Observables
    
    lazy var onFinish: PublishSubject<Bool> = .init()
    lazy var onUndo: PublishSubject<Bool> = .init()
    
    lazy var selection: Observable<Set<PHAsset>> = selectionStack
        .asObservable()
        .map { $0.last ?? [] }
    
    
    // MARK: - Initialization
    
    /// Full initializer with all parameters
    /// - parameter allowedMedia: What media is allowed to be picked (image/video/both)
    /// - parameter picking: Selection mode - can be single or multiple (with limit or unlimited).
    /// - parameter customTabKinds: Options that appear in the segmented control (nil = DEFAULT: recently added, favorites, albums, iCloud albums, smartAlbums)
    /// - parameter needsConfirmation: Should display a popup where user can review picked photo(s)
    /// - parameter showsLimit: If limited count, display how many photos remaining or don't
    /// - parameter preselected: Assets that should be selected in advance
    /// - parameter presentFirstOfferMoreLater: Start as picking single item, go onto review screen when item is picked and then offer to pick more items (multiple). Selection has to be set to multple.
    /// - parameter completion: Executes when user finished picking items. Delegate may be used instead.
    public init(
        allowedMedia: AllowedMedia,
        picking selectionMode: SelectionMode,
        customTabKinds: [TabKind]?,
        needsConfirmation: Bool,
        showsLimit: Bool,
        preselected: [PHAsset]?,
        presentFirstOfferMoreLater: Bool,
        tintColor: UIColor?,
        completion: Completion?
        ) {
        self.completion = completion
        self.allowedMedia = allowedMedia
        self.selectionMode = selectionMode
        self.needsConfirmation = needsConfirmation
        self.showsLimit = showsLimit
        self.presentFirstOfferMoreLater = presentFirstOfferMoreLater
        self.tabKinds = customTabKinds ?? QPToolbarView.defaultTabKinds
        self.tintColor = tintColor
        if self.tabKinds.count > 6 {
            self.tabKinds.removeLast(self.tabKinds.count - 6)
        }
        
        setupTabModels()
        setupBindings()
        if let preselected = preselected, !preselected.isEmpty {
            selectionStack.accept([Set(preselected)])
        }
    }
    
    /// Default init method with essential parameters.
    // MARK: - Initialization
    
    /// Full initializer with all parameters
    /// - parameter allowedMedia: What media is allowed to be picked (image/video/both)
    /// - parameter picking: Selection mode - can be single or multiple (with limit or unlimited).
    /// - parameter completion: Executes when user finished picking items. Delegate may be used instead.
    convenience public init(
        allowedMedia: AllowedMedia,
        picking selectionMode: SelectionMode,
        completion: Completion?
        ) {
        self.init(
            allowedMedia: allowedMedia,
            picking: selectionMode,
            customTabKinds: nil,
            needsConfirmation: true,
            showsLimit: true,
            preselected: nil,
            presentFirstOfferMoreLater: true,
            tintColor: nil,
            completion: completion
        )
    }
    
    
    func setupTabModels() {
        for kind in self.tabKinds {
            let result = PHAssetCollection.fetchAssetCollections(with: kind.type,
                                                                 subtype: kind.subtype,
                                                                 options: nil)
            let collections = result.objects(at: .init(0..<result.count))
            guard !collections.isEmpty else {
                fatalError("No collections for \(kind). Maybe no granted access to Photos?")
            }
            
            if kind.isSingle {
                let itemViewModel = ItemViewModel(kind: kind,
                                                  collection: collections.first!,
                                                  allowedMedia: allowedMedia,
                                                  selectionMode: selectionMode,
                                                  maxItemSize: [.pad: 150.0, .phone: 100.0],
                                                  delegateSelected: selectionStack,
                                                  fetchResult: nil)
                tabViewModels[kind] = itemViewModel
            } else {
                let albumViewModel = AlbumViewModel(kind: kind,
                                                    collections: collections)
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
                                allowedMedia: allowedMedia,
                                selectionMode: selectionMode,
                                maxItemSize: [.pad: 150.0, .phone: 100.0],
                                delegateSelected: selectionStack,
                                fetchResult: cachedCollectionFetchResults[collection])
        itemViewModels.acceptAppending(ivm)
    }
    
    /// RX - Called when selected assets change.
    func selectedChanged(assets: Set<PHAsset>) {
        if selectionMode == .single && !assets.isEmpty {
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
        onFinish.onNext(true)
        delegate?.quickPickerDidCancel(self)
        completion?(.canceled)
    }
    
    /// Asks for confirmation, if not needed executes QuickPicker's completion closure
    func proceed() {
        guard !(selectionCount == 0) else { return }
        if selectionMode != .single && selectionCount > selectionMode.max {
            return userError.accept("Too Many")
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


public extension QuickPickerViewModel {
    
    // Result used in Completion Handler
    enum Result {
        case canceled
        case finished(assets: [PHAsset])
    }
    
    typealias Completion = (QuickPickerViewModel.Result) -> Void
    
}


public protocol QuickPickerDelegate: class {
    
    func quickPicker(_ imagePicker: QuickPickerViewModel, didFinishPickingAssets assets: [PHAsset])
    func quickPickerDidCancel(_ imagePicker: QuickPickerViewModel)
}
