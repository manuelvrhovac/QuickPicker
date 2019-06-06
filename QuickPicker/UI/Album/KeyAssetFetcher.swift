//
//  KeyAssetFetcher.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 14/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import KVFetcher
import Photos

/*typealias KeyAssetFetcher = KVBlockFetcher<PHAssetCollection, KeyAssetFetcherTuple>

extension KeyAssetFetcher {
    
    static func fetchClosure(
        f: KeyAssetFetcher.Caching,
        collection: PHAssetCollection,
        completion: KeyAssetFetcher.ValueCompletion?
        ) {
        backgroundThread {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: true)]
            let result = PHAsset.fetchAssets(in: collection, options: nil)
            if result.count < 1 {
                mainThread {
                    completion?((result.count, nil))
                }
                return
            }
            let keyAsset = result.lastObject
            mainThread {
                completion?((result.count, keyAsset))
            }
        }
    }
}*/

typealias KeyAssetFetcherTuple = (count: Int, keyAsset: PHAsset?)

class KeyAssetFetcher: KVFetcher<PHAssetCollection, KeyAssetFetcherTuple>.Caching {
    
    override func _executeFetchValue(for key: Key, completion: ValueCompletion!) {
        let collection = key
        backgroundThread {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: true)]
            let result = PHAsset.fetchAssets(in: collection, options: nil)
            if result.count < 1 {
                mainThread {
                    completion?((result.count, nil))
                }
                return
            }
            let keyAsset = result.lastObject
            mainThread {
                completion?((result.count, keyAsset))
            }
        }
    }
}
