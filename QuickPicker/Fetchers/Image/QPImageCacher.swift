//
//  AssetCacher.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 08/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import KVFetcher
import Photos

public class QPImageCacher: KVCacher_Protocol {
    public typealias Key = PHAsset
    public typealias Value = UIImage
    
    public var _cacheDict: [PHAsset : (value: UIImage, dateAdded: Date)] = [:]
    public var _valueSizeCacheDict: [PHAsset: Double] = [:]
    public var maxAge: Double?
    public var limes: Limes?
    
    public init(maxMemory: Double) {
        self.limes = .memory(max: maxMemory, valueTransform: UIImage.approxImageSize)
    }
    
    public init(maxCount: Int) {
        self.limes = .count(max: maxCount)
    }
}


private extension UIImage {
    
    static func approxImageSize(image: UIImage?) -> Double {
        guard let image = image else { return 0.0 }
        return Double(image.size.width * image.size.height) * 0.000_002_04
    }
    
    var approxImageSize: Double {
        return UIImage.approximateSize(of: self)
    }
}
