//
//  AllowedMedia.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 12/06/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos


public struct AllowedMedia: OptionSet {
    
    public let rawValue: Int
    public static let images = AllowedMedia(rawValue: 0)
    public static let videos = AllowedMedia(rawValue: 1)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var mediaTypes: [PHAssetMediaType] {
        switch self {
        case .images: return [.image]
        case .videos: return [.video]
        default: return [.image, .video]
        }
    }
    
    public var image: UIImage {
        switch self {
        case .videos: return UIImage(bundleNamed: "video")
        default: return UIImage(bundleNamed: "photo")
        }
    }
    
    public var fetchPredicate: NSPredicate? {
        if mediaTypes.count != 1 { return nil }
        return .init(format: "mediaType = \(mediaTypes[0].rawValue)")
    }
}
