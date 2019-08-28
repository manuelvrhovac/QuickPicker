//
// Created by Manuel Vrhovac on 28/08/2019.
// Copyright © 2019 Manuel Vrhovac. All rights reserved.
// 

import Foundation

public extension QuickPicker {
    
    /// Configuration options for QuickPicker
    /// - **allowedMedia**: OptionSet - What media is allowed to be picked (image/video/both).
    /// - **picking**: Selection mode - can be single or multiple (with limit or unlimited).
    /// - **customTabKinds**: Options that appear in the segmented control (nil = DEFAULT: recently added, favorites, albums, iCloud albums, smartAlbums)
    /// - **needsConfirmation**: Should display a popup where user can review picked photo(s)
    /// - **showsLimit**: If limited count, display how many photos remaining or don't
    /// - **preselected**: Assets that should be selected in advance
    /// - **presentFirstOfferMoreLater**: Start as picking single item, go onto review screen when item is picked and then offer to pick more items (multiple). Selection has to be set to multple.
    struct Config {
        
        /// Selection mode can be single or multiple
        public var selectionMode: SelectionMode
        
        /// OptionSet - What media is allowed to be picked (image/video/both).
        public var allowedMedia: AllowedMedia
        
        /// If limited count, display how many photos remaining or don't
        public var showsLimit: Bool
        
        /// Displays a popup where user can review picked photo(s)
        public var needsConfirmation: Bool
        
        /// Options that appear in the segmented control (nil = DEFAULT: recently added, favorites, albums, iCloud albums, smartAlbums)
        public var tabKinds: [TabKind]
        
        /// If picking multiple, go onto review screen as soon as one item is picked. Offer to pick more in review screen.
        public var presentFirstOfferMoreLater: Bool
        
        /// The tint color of the QuickPicker user interface. Has to be preset before showing!
        public var tintColor: UIColor?
        
        /// Random configuration options. Testing uses only.
        public static let `random`: Config = .init(selectionMode: .random,
                                                          allowedMedia: .random,
                                                          showsLimit: .random(),
                                                          needsConfirmation: .random(),
                                                          tabKinds: .random,
                                                          presentFirstOfferMoreLater: .random(),
                                                          tintColor: nil)
        
        
    }
}

extension QuickPicker.Config {
    
    /// Most typical picker for single/multiple image/video. Shows limit, needs confirmation, default tab kinds.
    public init(selectionMode: SelectionMode, allowedMedia: AllowedMedia) {
        self.init(selectionMode: selectionMode,
                  allowedMedia: allowedMedia,
                  showsLimit: true,
                  needsConfirmation: true,
                  tabKinds: .default,
                  presentFirstOfferMoreLater: false,
                  tintColor: nil)
    }
    
    /// Single image picker. Shows limit, needs confirmation, default tab kinds.
    public init() {
        self.init(selectionMode: .single, allowedMedia: .images)
    }
}

extension Array where Element == TabKind {
    
    /// 5 tabs - two single and three grouped: Recent, Favorites, UserAlbums, Cloud, SmartAlbums
    public static let `default` = QPToolbarView.defaultTabKinds
    
    static var random: [TabKind] {
        var defaulto = QPToolbarView.defaultTabKinds
        defaulto.remove(at: 1)

        let singleTabKinds: [TabKind] = [
            .favorites,
            .videos,
            .screenshots,
            .selfPortraits,
            .panoramas,
            .livePhotos,
            .depthEffect,
            .bursts,
            .timelapses,
            .slomoVideos,
            .generic,
            .longExposures,
            .animated,
            .allHidden
        ]
        
        defaulto.insert(singleTabKinds.random!, at: 1)
        return defaulto
    }
}
