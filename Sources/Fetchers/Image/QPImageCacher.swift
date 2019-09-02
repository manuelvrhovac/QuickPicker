//
//  Created by Manuel Vrhovac on 08/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//


import Foundation
import UIKit
import KVFetcher
import Photos

/// A subclass of KVCacher that has custom initialization to limit the memory by estimating image size in MB.
public class QPImageCacher: KVCacher<PHAsset, UIImage?> {
    
    public init(maxMemory: Double) {
        super.init(limit: .memory(max: maxMemory, valueTransform: QPImageCacher.approxImageSize))
    }
    
    public init(maxCount: Int) {
        super.init(limit: .count(max: maxCount))
    }
    
    static func approxImageSize(image: UIImage?) -> Double {
        guard let image = image else { return 0.0 }
        return Double(image.size.width * image.size.height) * 0.000_002_04
    }
}
