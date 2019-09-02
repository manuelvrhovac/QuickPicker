//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//


import Foundation
import UIKit
import Photos
import KVFetcher
import RxCocoa
import RxSwift

class AlbumViewModel: TabViewModel {
    
    // MARK: - Properties
    
    private var collections = [[PHAssetCollection]]()
    private var keyAssetFetcher = KeyAssetFetcher(cacher: .unlimited)
    private var imageFetcher: QPImageFetcher!
    private var cellViewModels: [IndexPath: AlbumCellViewModel] = [:]
    
    // MARK: Calculated
    
    override var title: String {
        return kind.title
    }
    
    // MARK: Reactive
    
    var selectedIndexPath: BehaviorRelay<IndexPath> = .init(value: .init(row: -1, section: -1))
    
    // MARK: Observables
    
    lazy var selectedCollection = self.selectedIndexPath
        .asObservable()
        .skip(1)
        .map { self.collections[$0.section][$0.row] }

    // MARK: - Methods
    
    init(kind: TabKind, collections: [PHAssetCollection]) {
        let sortedColl = collections.sorted {
            let p0 = $0.assetCollectionSubtype.nativePhotosOrder
            let p1 = $1.assetCollectionSubtype.nativePhotosOrder
            if p0 != p1 { return p0 < p1 }
            return ($0.localizedTitle ?? "") < ($1.localizedTitle ?? "")
        }
        let fullCollections = sortedColl.filter { $0.estimatedAssetCount != 0 }
        let emptyCollections = sortedColl.filter { $0.estimatedAssetCount == 0 }
        self.collections = [fullCollections, emptyCollections]
        super.init()
        self.kind = kind
        
        imageFetcher = .init(deliveryMode: .fastFormat, cacher: .init(maxCount: 200))

        // Load at least 9 albums before appearing
        for (index, collection) in self.collections[0].enumerated() where index < 9 {
            keyAssetFetcher.fetchSynchronously(collection)
        }
    }
    
    // MARK: - Getters
    
    func countIn(section: Int) -> Int {
        return collections[section].count
    }
    
    func cellViewModel(at indexPath: IndexPath) -> AlbumCellViewModel {
        if let existing = cellViewModels[optional: indexPath] {
            return existing
        }
        let cvm = AlbumCellViewModel(collection: collections[indexPath.section][indexPath.row],
                                     keyAssetFetcher: keyAssetFetcher,
                                     imageFetcher: imageFetcher)
        cellViewModels[indexPath] = cvm
        return cvm
    }
    
    // MARK: - Interaction
    
    func selectedItemAt(_ indexPath: IndexPath) {
        selectedIndexPath.accept(indexPath)
    }
    
}
