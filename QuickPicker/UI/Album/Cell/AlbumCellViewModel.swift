//
//  AlbumCellViewModel.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos

class AlbumCellViewModel {
    
    typealias ImageFetcher = QPImageFetcher
    weak var collection: PHAssetCollection!
    weak var keyAssetFetcher: KeyAssetFetcher.Caching!
    weak var imageFetcher: ImageFetcher.Caching!
    
    var title: String {
        return collection.localizedTitle ?? ""
    }
    
    var subtitle: String? { didSet { onRefreshUI() } }
    var image: UIImage? { didSet { onRefreshUI() } }
    var icon: UIImage?
    //var color: UIColor?
    
    var onRefreshUI: () -> Void = { }
    
    init(collection: PHAssetCollection, keyAssetFetcher: KeyAssetFetcher.Caching, imageFetcher: ImageFetcher.Caching) {
        self.collection = collection
        self.keyAssetFetcher = keyAssetFetcher
        self.imageFetcher = imageFetcher
        
        let count = collection.estimatedAssetCount
        subtitle = count == NSNotFound ? nil : "\(count) items"
        image = nil
        icon = collection.assetCollectionSubtype.icon?.template
    }
    
    
    func fetchAssetAndImage() {
        let subtype = collection.assetCollectionSubtype
        if subtype != .smartAlbumAllHidden && subtype.rawValue < 999 {
            keyAssetFetcher.fetchValue(for: collection, priority: .now) { value in
                guard let count = value?.count else { return }
                self.subtitle = "\(count) items"
                guard let keyAsset = value?.keyAsset else { return }
                self.imageFetcher.fetchValue(for: keyAsset, priority: .now) { image in
                    self.image = image ?? UIImage(bundleNamed: "placeholder")
                }
            }
        }
        
    }
}
