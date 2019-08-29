//
//  Created by Manuel Vrhovac on 21/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos


/// Tab kind can be single collection (recentlyAdded, favorites, panoramas...) or a collection group (groupRegular, groupShared, groupSmart). For groups, AlbumView is displayed. For single collection ItemView is displayed.
///
/// Grouped:
/// - groupRegular
/// - groupShared
/// - groupSmart
///
/// Single:
/// - recentlyAdded
/// - userLibrary
/// - favorites
/// - videos
/// - screenshots
/// - selfPortraits
/// - panoramas
/// - livePhotos
/// - depthEffect
/// - bursts
/// - timelapses
/// - slomoVideos
/// - generic
/// - longExposures
/// - animated
/// - allHidden
/// - other

public enum TabKind: String, Comparable {
    
    case groupRegular
    case groupShared
    case groupSmart
    
    case recentlyAdded
    case userLibrary
    case favorites
    case videos
    case screenshots
    case selfPortraits
    case panoramas
    case livePhotos
    case depthEffect
    case bursts
    case timelapses
    case slomoVideos
    case generic
    case longExposures
    case animated
    case allHidden
    case other
    
    var isSingle: Bool {
        return !self.rawValue.hasPrefix("group")
    }
    
    var title: String {
        switch self {
        case .groupRegular: return "My Albums"
        case .groupShared: return "iCloud Shared"
        case .groupSmart: return "Smart Albums"
        default: return rawValue.revertCamelCased
        }
    }
    
    var type: PHAssetCollectionType {
        switch self {
        case .groupRegular, .groupShared: return .album
        default: return .smartAlbum
        }
    }
    
    var subtype: PHAssetCollectionSubtype {
        switch self {
            
        case .groupRegular, .groupSmart: return .albumRegular
        case .groupShared: return .albumCloudShared
            
        case .recentlyAdded : return .smartAlbumRecentlyAdded
        case .userLibrary :   return .smartAlbumUserLibrary
        case .favorites :     return .smartAlbumFavorites
        case .videos :        return .smartAlbumVideos
        case .screenshots :   return .smartAlbumScreenshots
        case .selfPortraits : return .smartAlbumSelfPortraits
        case .panoramas :     return .smartAlbumPanoramas
        case .livePhotos :    if #available(iOS 10.3, *) {
            return .smartAlbumLivePhotos
        } else {
            return .any
        }
        case .depthEffect :   if #available(iOS 10.2, *) {
            return .smartAlbumDepthEffect
        } else {
            return .any
        }
        case .bursts :        return .smartAlbumBursts
        case .timelapses :    return .smartAlbumTimelapses
        case .slomoVideos :   return .smartAlbumSlomoVideos
        case .generic :       return .smartAlbumGeneric
        case .allHidden :     return .smartAlbumAllHidden
        case .longExposures :
            if #available(iOS 11.0, *) {
                return .smartAlbumLongExposures
            } else {
                return .any
            }
        case .animated :
            if #available(iOS 11.0, *) {
                return .smartAlbumAnimated
            } else {
                return .any
            }
        default : return .any
        }
    }
    
    var image: UIImage? {
        switch self {
        case .groupRegular: return imageLiteral(resourceName: "segment-myAlbums")
        case .groupShared: return imageLiteral(resourceName: "icon-101")
        case .groupSmart: return imageLiteral(resourceName: "segment-smart")
        default: return subtype.icon
        }
    }
    
    /// If ordered automatically, the groups come last. If smart album, native order used.
    var order: Int {
        switch self {
        case .groupRegular: return 5000
        case .groupShared: return 6000
        case .groupSmart: return 7000
        default: return subtype.nativePhotosOrder
        }
    }
    
    public static func < (lhs: TabKind, rhs: TabKind) -> Bool {
        return lhs.order < rhs.order
    }
}
