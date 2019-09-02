//
//  Created by Manuel Vrhovac on 16/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import KVFetcher

/// A fetcher initialized with PHFetchResult<PHAsset> object. Key is index (Int) and Value is a PHAsset object. Fetching too many PHAsset objects from the PHFetchResult causes lags, so that's why it is loaded dynamically. Automatically caches fetched PHAsset objects.
class QPCachedAssetFetcher: KVFetcher<Int, PHAsset>.Caching {
    
    var result: PHFetchResult<PHAsset>!
    
    // FIXME: remove this
    //private var randomInts = [Int]()
    
    override func _executeFetchValue(for key: Int, completion: ((PHAsset) -> Void)!) {
        guard let result = result, key < result.count else {
            fatalError("No result or key bigger than result!")
        }
        completion(result.object(at: key))
        //completion(result.object(at: randomInts[key]))
    }
    
    convenience init(phFetchResult result: PHFetchResult<PHAsset>, cacher: Cacher) {
        self.init(cacher: cacher)
        self.result = result
        //randomInts = Array( 0 ..< result.count ).shuffled()
    }
}
