//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import RxSwift
import RxCocoa

class AlbumCellViewModel {
    
    
    /// A fetcher that fetches assets from PHFetchResult.
    weak var keyAssetFetcher: KeyAssetFetcher!
    
    /// ImageFetcher used (maybe image is already cached somewhere)
    weak var imageFetcher: QPImageFetcher!
    
    
    // MARK: Reactive
    
    /// Collection presented
    private(set) var collection: BehaviorRelay<PHAssetCollection>
    
    /// Usually the latest photo in collection (by date)
    lazy private(set) var keyAssetImage: BehaviorRelay<UIImage?> = .init(value: nil)
    
    /// Count: maybe from estimatedAssetCount, later by examining fetch result.
    lazy private(set) var count: BehaviorRelay<Int?> = .init(value: collection.value.countOrNil)
    
    
    // MARK: Observables
    
    lazy private(set) var title: Observable<String> = collection
        .asObservable()
        .map { $0.localizedTitle ?? "" }
    
    lazy private(set) var subtitle: Observable<String?> = count
        .asObservable()
        .map { $0 == nil ? nil : String($0!) + " items" }
    
    lazy private(set) var icon: Observable<UIImage?> = collection
        .asObservable()
        .map { return $0.assetCollectionSubtype.icon?.template }
    
    
    // MARK: - Methods
    
    init(collection: PHAssetCollection, keyAssetFetcher: KeyAssetFetcher, imageFetcher: QPImageFetcher) {
        self.collection = .init(value: collection)
        self.keyAssetFetcher = keyAssetFetcher
        self.imageFetcher = imageFetcher
    }
    
    func fetchAssetAndImage() {
        let subtype = collection.value.assetCollectionSubtype
        if subtype != .smartAlbumAllHidden && subtype.rawValue < 999 {
            keyAssetFetcher.fetchValue(for: collection.value, priority: .now) { value in
                guard let count = value?.count else { return }
                self.count.accept(count)
                guard let keyAsset = value?.keyAsset else { return }
                self.imageFetcher.fetchValue(for: keyAsset, priority: .now) { image in
                    let image = image ?? UIImage(bundleNamed: "placeholder")
                    self.keyAssetImage.accept(image)
                }
            }
        }
        
    }
}
