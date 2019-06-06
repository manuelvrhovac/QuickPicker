//
//  ItemCollectionViewCell.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 01/07/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import UIKit
import Photos
import KVFetcher
import RxSwift
import RxCocoa

class ItemCellViewModel {
    
    typealias ImageFetcher = QPImageFetcher
    enum SelectionStyle {
        case checkmark
        case outline
    }
    static let shadowImage = UIImage(bundleNamed: "shadow")
    
    weak var imageFetcher: ImageFetcher.Caching!

    private(set) var item: BehaviorRelay<PHAsset>!
    lazy private(set) var image = BehaviorRelay<UIImage?>(value: nil)
    lazy private(set) var isSelected = BehaviorRelay<Bool>(value: false)
    lazy private(set) var selectionStyle = BehaviorRelay<SelectionStyle>(value: .checkmark)

    lazy private(set) var rxDurationText: Observable<String?> = self.item.asObservable()
        .map { item in
        guard item.mediaType == .video else { return nil }
        let d = Int(item.duration)
        if d >= 3600 {
            return String(format: "%02d:%02d:%02d", d / 60 / 60, d / 60, d % 60)
        } else {
            return String(format: "%02d:%02d", d / 60, d % 60)
        }
        }
    
    lazy private(set) var rxIcon: Observable<UIImage?> = self.item.asObservable()
        .map { asset in
            if let subtype = asset.relatedSmartCollectionSubtype {
                if let icon = subtype.icon {
                    return icon.template
                }
            }
            return nil
        }

    
    init(item: PHAsset, isSelected: Bool, selectionStyle: SelectionStyle, imageFetcher: ImageFetcher.Caching) {
        self.imageFetcher = imageFetcher
        self.item = .init(value: item)
        self.isSelected.accept(isSelected)
        self.selectionStyle.accept(selectionStyle)
    }
    
    func fetchImage() {
        imageFetcher?.fetchValue(for: item.value, priority: .now) { (image) in
            self.image.v = image
        }
    }
    
}
