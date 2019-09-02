//
//  Created by Manuel Vrhovac on 14/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//


import Foundation
import UIKit
import KVFetcher
import Photos

typealias KeyAssetFetcherTuple = (count: Int, keyAsset: PHAsset?)

/// A subclass of KVFetcher.Caching that fetches both key asset and count of an asset collection.
class KeyAssetFetcher: KVFetcher<PHAssetCollection, KeyAssetFetcherTuple?>.Caching {
    
    override func _executeFetchValue(for key: Key, completion: ValueCompletion!) {
        let collection = key
                
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: true)]
        let result = PHAsset.fetchAssets(in: collection, options: nil)
        if result.count < 1 {
            completion?((result.count, nil))
            return
        }
        let keyAsset = result.lastObject
        completion?((result.count, keyAsset))
        
        thread(background: Thread.isMainThread) {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: true)]
            let result = PHAsset.fetchAssets(in: collection, options: nil)
            if result.count < 1 {
                thread(main: !Thread.isMainThread) {
                    completion?((result.count, nil))
                }
                return
            }
            let keyAsset = result.lastObject
            thread(main: !Thread.isMainThread) {
                completion?((result.count, keyAsset))
            }
        }
    }
    
}
