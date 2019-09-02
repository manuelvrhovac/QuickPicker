//
//  Created by Manuel Vrhovac on 01/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import UIKit
import Photos
import KVFetcher
import RxSwift
import RxCocoa


class ItemCellViewModel {
    
    /// Image fetcher used for (cached) fetching
    weak var imageFetcher: QPImageFetcher!
    
    // MARK: - Reactive

    private(set) var item: BehaviorRelay<PHAsset>!
    lazy private(set) var image = BehaviorRelay<UIImage?>(value: nil)
    lazy private(set) var isSelected = BehaviorRelay<Bool>(value: false)
    lazy private(set) var selectionStyle = BehaviorRelay<SelectionStyle>(value: .checkmark)

    // MARK: Observables
    
    lazy private(set) var rxDurationText: Observable<String?> = item
        .asObservable()
        .map { $0.durationString }
    
    lazy private(set) var rxIcon: Observable<UIImage?> = item
        .asObservable()
        .map { return $0.relatedSmartCollectionSubtype }
        .map { return $0?.icon?.template }

    
    // MARK: - Methods
    
    init(item: PHAsset, isSelected: Bool, selectionStyle: SelectionStyle, imageFetcher: QPImageFetcher) {
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


extension ItemCellViewModel {
    
    enum SelectionStyle {
        case checkmark
        case outline
    }
}
