//
//  AlbumViewModel.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import KVFetcher
import RxCocoa
import RxSwift

class AlbumViewModel: ItemOrAlbumViewModel {
    
    typealias ImageFetcher = QPImageFetcher
    weak var imageManager: PHImageManager!
    private var cellViewModels: [IndexPath: AlbumCellViewModel] = [:]

    var title: String {
        return kind.title
    }
    
    private var collections = [[PHAssetCollection]]()
    private var keyAssetFetcher = KeyAssetFetcher(cacher: .unlimited)
    private var imageFetcher: ImageFetcher.Caching!
    
    init(kind: TabKind, collections: [PHAssetCollection]) {
        //super.init(nibName: nil, bundle: nil)
        let sortedColl = collections.sorted {
            let p0 = $0.assetCollectionSubtype.normalOrder
            let p1 = $1.assetCollectionSubtype.normalOrder
            if p0 != p1 { return p0 < p1 }
            return ($0.localizedTitle ?? "") < ($1.localizedTitle ?? "")
        }
        let fullCollections = sortedColl.filter { $0.estimatedAssetCount != 0 }
        let emptyCollections = sortedColl.filter { $0.estimatedAssetCount == 0 }
        self.collections = [fullCollections, emptyCollections]
        super.init()
        self.kind = kind
        
        //let size: CGSize = .init(width: 200, height: 200)
        imageFetcher = .init(deliveryMode: .fastFormat, cacher: .init(maxCount: 200))
        //imageFetcher = ImageFetcher.Caching(.thumbnail(targetSize: size),
        //                                    cacher: .init(maxCount: 200))
        
        // Load at least 9 albums before appearing
        for (index, collection) in self.collections[0].enumerated() where index < 9 {
            keyAssetFetcher.fetchValue(for: collection, priority: .now, completion: nil)
        }
    }
    
    func countIn(section: Int) -> Int {
        return collections[section].count
    }
    
    
    func cellViewModel(at indexPath: IndexPath) -> AlbumCellViewModel {
        if let existing = cellViewModels[optional: indexPath] {
            return existing
        }
        let new = AlbumCellViewModel(collection: getCollection(at: indexPath),
                                     keyAssetFetcher: keyAssetFetcher,
                                     imageFetcher: imageFetcher)
        cellViewModels[indexPath] = new
        return new
    }
    
    private func getCollection(at indexPath: IndexPath) -> PHAssetCollection {
        return collections[indexPath.section][indexPath.row]
    }
    
    func selectedItemAt(_ indexPath: IndexPath) {
        selectedIndexPath.accept(indexPath)
    }
    
    //var onSelectedItem: (IndexPath) -> Void = {_ in}
    var selectedIndexPath: BehaviorRelay<IndexPath> = .init(value: .init(row: -1, section: -1))
    lazy var selectedCollection = self.selectedIndexPath.asObservable().skip(1).map(getCollection)

}
