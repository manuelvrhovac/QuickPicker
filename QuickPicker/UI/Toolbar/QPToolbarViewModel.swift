//
//  Created by Manuel Vrhovac on 31/05/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class QPToolbarViewModel {
    
    var bag = DisposeBag()
    var qpm: QuickPicker.ViewModel
    
    init(quickPickerViewModel: QuickPicker.ViewModel) {
        self.qpm = quickPickerViewModel
    }
    
    lazy var selectedSegmentIndex: BehaviorRelay<Int> = .init(value: 0)
    
    lazy var isUndoEnabled: Observable<Bool> = qpm.selectionStack
        .asObservable()
        .map { !$0.isEmpty }
    
    lazy var countAttributes = qpm.selection.map { (selection) -> (String, UIColor, UIImage) in
        let color: UIColor = selection.count > self.qpm.config.selectionMode.max ? .darkRed : .black
        let image = self.qpm.config.allowedMedia.image
        let text = self.qpm.config.showsLimit && self.qpm.config.selectionMode.isMultipleLimited
            ? "\(selection.count)/\(self.qpm.config.selectionMode.max)"
            : "\(selection.count)"
        return (text, color, image)
    }
    
}
