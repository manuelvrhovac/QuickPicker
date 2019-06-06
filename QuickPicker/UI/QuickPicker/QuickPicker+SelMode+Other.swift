//
//  QuickPicker+SelMode+Other.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 05/06/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos

extension QuickPicker {
    
    public enum Result {
        case canceled
        case finished(assets: [PHAsset])
    }
}

extension QuickPicker {
    
    public typealias Completion = (QuickPicker.Result) -> Void
}

extension QuickPicker {
    
    public enum SelectionMode: Equatable {
        case single
        case multiple(max: Int)
        case multipleUnlimited
        public static var random: SelectionMode { return [.single, .multiple(max: 1000), .multipleUnlimited].random! }
        /// single=1, multiptle=max, multipleUnlimited=0
        var max: Int {
            switch self {
            case .multiple(let m): return m
            default: return .max
            }
        }
        var hasMax: Bool {
            return self != .single && self != .multipleUnlimited
        }
    }
}

extension QuickPicker {
    
    
    public struct AllowedMedia: OptionSet {
        
        public let rawValue: Int
        public static let images = AllowedMedia(rawValue: 0)
        public static let videos = AllowedMedia(rawValue: 1)
        public static let imagesAndVideos: AllowedMedia = [.images, .videos]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        var mediaTypes: [PHAssetMediaType] {
            switch self {
            case .images: return [.image]
            case .videos: return [.video]
            default: return [.image, .video]
            }
        }
        
        var image: UIImage {
            switch self {
            case .videos: return UIImage(bundleNamed: "video")
            default: return UIImage(bundleNamed: "photo")
            }
        }
        
        public static var random: AllowedMedia {
            return [.images, .videos, .imagesAndVideos].random!
        }
        
        
        var fetchPredicate: NSPredicate? {
            if contains(.images) && contains(.videos) { return nil }
            switch self {
            case .images: return .init(format: "mediaType = \(PHAssetMediaType.image.rawValue)")
            case .videos: return .init(format: "mediaType = \(PHAssetMediaType.video.rawValue)")
            default: return nil
            }
        }
    }
}
    

public protocol QuickPickerDelegate: class {
    
    func quickPicker(_ imagePicker: QuickPickerModel, didFinishPickingAssets assets: [PHAsset])
    func quickPickerDidCancel(_ imagePicker: QuickPickerModel)
}
