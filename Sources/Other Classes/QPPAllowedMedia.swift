//
//  Created by Manuel Vrhovac on 12/06/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos

/// OptionSet - Could be .photo, .video or [.photo, .video]
public struct AllowedMedia: OptionSet {
    
    public let rawValue: Int
    public static let images = AllowedMedia(rawValue: 0)
    public static let videos = AllowedMedia(rawValue: 1)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    var mediaTypes: [PHAssetMediaType] {
        return !contains(.images) ? [.video] : contains(.videos) ? [.image, .video] : [.image]
    }
    
    var image: UIImage {
        let imageName = !contains(.images) ? "video" : contains(.videos) ? "photovideo" : "photo"
        return UIImage(bundleNamed: imageName)
    }
    
    public static var random: AllowedMedia {
        let am: [AllowedMedia] = [.images, .videos, [.images, .videos]]
        return am.random!
    }
    
    var fetchPredicate: NSPredicate? {
        if mediaTypes.count != 1 { return nil }
        return .init(format: "mediaType = \(mediaTypes[0].rawValue)")
    }
}
