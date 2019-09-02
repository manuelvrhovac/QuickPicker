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


extension UIImage {
    
    static func approximateSize(of image: UIImage) -> Double {
        return Double(image.size.width * image.size.height) * 0.000_002_04
    }
    var approxSize: Double {
        return UIImage.approximateSize(of: self)
    }
}

class ReviewViewModel {
    
    
    typealias Fetcher = QPImageFetcher
    //typealias BlockFetcher = KVBlockFetcher<PHAsset, UIImage>
    
    
    enum PreviewResult {
        case image(_ image: UIImage?)
        case video(_ url: URL)
    }
    
    enum Result {
        case canceled
        case confirmed
        case wantsMore
    }
    
    typealias Completion = (Result, [PHAsset]) -> Void
    

    // MARK: - Properties
    
    var canAddMore: Bool
    var fetchers: (full: QPImageFetcher, thumbnail: QPImageFetcher)!
    var completion: Completion!
    var assets: BehaviorRelay<[PHAsset]> = .init(value: [])
    
    // MARK: Reactive
    
    var image: UIImage?  //{ didSet { onImageChanged() } }
    var currentIndex: BehaviorRelay<Int> = .init(value: 0)
    
    lazy var lastAndCurrentIndex = Observable.zip(currentIndex.asObservable(), currentIndex.asObservable().skip(1))

    var onFinish: PublishSubject<Result> = .init()
    var bag = DisposeBag()
    var itemCellViewModels: [PHAsset: ItemCellViewModel] = [:]

    
    // MARK: Calculated
    
    var numberOfItems: Int {
        return assets.value.count
    }
    
    private var currentAsset: PHAsset {
        return assets.value[min(currentIndex.value, numberOfItems - 1)]
    }
    
    
    // MARK: - Init
    
    init(assets: [PHAsset], canAddMore: Bool, completion: Completion?) {
        self.assets.v = assets
        self.completion = completion
        self.canAddMore = canAddMore
        let fullImageFetcher = QPImageFetcher (
            keys: self.assets.value,
            currentIndex: self.currentIndex.value,
            options: .upcoming(10),
            cacher: .init(maxCount: 20)
        )
        fullImageFetcher.deliveryMode = .highQualityFormat
        
        self.currentIndex
            .bind(onNext: { fullImageFetcher.currentIndex = $0 })
            .disposed(by: bag)
        
        self.assets
            .bind(onNext: { fullImageFetcher.keys = $0 })
            .disposed(by: bag)
        
        fullImageFetcher.displaySize = .init(width: 800, height: 800)
        
        
        /*let fullImageFetcher = PhotosFetcher.Caching.Active(.full(targetSize: .init(width: 800, height: 800)),
                                                           keys: { return self.assets.value },
                                                           currentIndex: { return self.currentIndex.value },
                                                           options: .upcoming(10),
                                                           cacher: .init(maxCount: 20))*/
        fullImageFetcher.startPrefetching()
        
        let thumbnailFetcher = QPImageFetcher(
            deliveryMode: .fastFormat,
            cacher: .init(maxCount: 500)
        )
        
        /*let thumbnailFetcher = PhotosFetcher.Caching(.defaultFastFormat, cacher: .init(maxCount: 5000))*/
        fetchers = (fullImageFetcher, thumbnailFetcher)
        lastAndCurrentIndex.bind(onNext: indexChanged).disposed(by: bag)
    }
    
    
    // MARK: - Reactive methods
    
    
    @objc
    func removeCurrentAsset() {
        guard numberOfItems > 1 else { return finish(.canceled) }
        let index = currentIndex.value
        assets.v = assets.value.filter { $0 !== currentAsset }
        currentIndex.v = min(numberOfItems - 1, index)
    }
    
    func finish(_ result: Result) {
        if result != .wantsMore {
            cleanFetchers()
        }
        onFinish.onNext(result)
        completion?(result, assets.value)
    }
    
    func title(forLanguage language: String = "en") -> String {
        var s = "photos and videos"
        let photos = assets.value.filter { $0.mediaType == .image }.count
        let videos = assets.value.filter { $0.mediaType == .video }.count
        if min(photos, videos) == 0 {
            s = s.replacingOccurrences(of: " and ", with: "")
            s = s.replacing(photos == 0 ? "photos" : "videos", with: "")
            s = s.replacing("os", with: max(videos, photos) == 1 ? "o" : "os")
        }
        s = s.replacing("photos and videos", with: "items")
        return "Review "+s
    }
    
    func itemCellViewModel(atIndex index: Int) -> ItemCellViewModel {
        let asset = assets.value[index]
        if let existing = itemCellViewModels[asset] {
            return existing
        }
        let itemCellViewModel = ItemCellViewModel(item: assets.value[index],
                                                  isSelected: false,
                                                  selectionStyle: .outline,
                                                  imageFetcher: fetchers!.thumbnail)
        itemCellViewModels[asset] = itemCellViewModel
        return itemCellViewModel
    }
    
    
    var countText: String {
        return numberOfItems < 1 ? "" : "\(currentIndex.value + 1) / \(numberOfItems) "
    }
    
    // MARK: - Private methods
    
    
    func indexChanged(lastIndex: Int, index: Int) {
        guard fetchers != nil else { return }
        let lastAsset = assets.value[lastIndex]
        itemCellViewModels[lastAsset]?.isSelected.v = false
        guard numberOfItems > 0 else { return }
        fetchers?.full.cleanQueue()
        itemCellViewModel(atIndex: index).isSelected.accept(true)
    }
    
    private func cleanFetchers() {
        fetchers.full.cacher.removeAllResults()
        fetchers.full.cleanQueue()
        fetchers.full.stopPrefetching()
        fetchers.full = .init(deliveryMode: .fastFormat,
                              cacher: .init(maxCount: 0))
        fetchers.thumbnail = .init(deliveryMode: .fastFormat,
                                   cacher: .init(maxCount: 0))
    }
    
    func getPreview(atIndex index: Int, completion: @escaping (PreviewResult) -> Void) {
        let asset = assets.value[index]
        let index = currentIndex.value
        switch asset.mediaType {
        case .image:
            if let cachedFullImage = fetchers.full.cacher.cachedValue(for: asset) {
                completion(.image(cachedFullImage))
            } else {
                fetchers.thumbnail.fetchValue(for: asset, priority: .now) { image in
                    if index != self.currentIndex.value { return }
                    self.image = image
                    completion(.image(image))
                    self.fetchers.full.cleanQueue()
                    self.fetchers.full.fetchValue(for: asset, priority: .next) { image in
                        if index != self.currentIndex.value { return }
                        completion(.image(image))
                    }
                }
            }
        case .video:
            PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (asset, _, _) in
                guard let asset = asset as? AVURLAsset else { return }
                mainThread {
                    completion(.video(asset.url))
                }
            }
        default: completion(.image(nil))
        }
    }
}
