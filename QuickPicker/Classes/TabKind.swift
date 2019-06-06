//
//  ImagePickerTools.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 21/08/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos

/*
public enum GroupCollectionKind: SegmentKindProtocol, Hashable {
    case regular
    case shared
    case smart
    case smartSingle(subkind: SmartCollectionKind)
    
    var isSingle: Bool {
        return order < 2000
    }
    
    var order: Int {
        switch self {
        case .regular: return 5000
        case .shared: return 6000
        case .smart: return 7000
        case .smartSingle(let subkind): return subkind.subtype.normalOrder
        }
    }
    
    var title: String {
        switch self {
        case .regular: return "My Albums"
        case .shared: return "iCloud Shared"
        case .smart: return "Smart Albums"
        case .smartSingle(let subkind): return subkind.title
        }
    }
    
    var type: PHAssetCollectionType {
        switch self {
        case .regular: return .album
        case .shared: return .album
        case .smart: return .smartAlbum
        default: return .smartAlbum
        }
    }
    
    var subtype: PHAssetCollectionSubtype {
        switch self {
        case .regular: return .albumRegular
        case .shared: return .albumCloudShared
        case .smart: return .albumRegular
        case .smartSingle(let subkind): return subkind.subtype
        }
    }
    
    var image: UIImage? {
        switch self {
        case .regular: return imageLiteral(resourceName: "segment-myAlbums")
        case .shared: return imageLiteral(resourceName: "icon-101")
        case .smart: return imageLiteral(resourceName: "segment-smart")
        case .smartSingle(let subkind): return subkind.image
        }
    }
}
*/

/// Tab kind can be single collection (recentlyAdded, favorites, panoramas...) or a collection group (groupRegular, groupShared, groupSmart). For groups, AlbumView is displayed. For single collection ItemView is displayed.
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
        switch self {
        case .groupRegular, .groupSmart, .groupShared: return false
        default: return true
        }
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
        case .groupRegular: return .album
        case .groupShared: return .album
        case .groupSmart: return .smartAlbum
        default: return .smartAlbum
        }
    }
    
    var subtype: PHAssetCollectionSubtype {
        switch self {
            
        case .groupRegular: return .albumRegular
        case .groupShared: return .albumCloudShared
        case .groupSmart: return .albumRegular
            
        case .recentlyAdded : return .smartAlbumRecentlyAdded
        case .userLibrary :   return .smartAlbumUserLibrary
        case .favorites :     return .smartAlbumFavorites
        case .videos :        return .smartAlbumVideos
        case .screenshots :   return .smartAlbumScreenshots
        case .selfPortraits : return .smartAlbumSelfPortraits
        case .panoramas :     return .smartAlbumPanoramas
        case .livePhotos :    return .smartAlbumLivePhotos
        case .depthEffect :   return .smartAlbumDepthEffect
        case .bursts :        return .smartAlbumBursts
        case .timelapses :    return .smartAlbumTimelapses
        case .slomoVideos :   return .smartAlbumSlomoVideos
        case .generic :       return .smartAlbumGeneric
        case .longExposures : return .smartAlbumLongExposures
        case .animated :      return .smartAlbumAnimated
        case .allHidden :     return .smartAlbumAllHidden
        default :             return .any
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
    
    var order: Int {
        switch self {
        case .groupRegular: return 5000
        case .groupShared: return 6000
        case .groupSmart: return 7000
        default: return subtype.normalOrder
        }
    }
    
    public static func < (lhs: TabKind, rhs: TabKind) -> Bool {
        return lhs.order < rhs.order
    }
}
