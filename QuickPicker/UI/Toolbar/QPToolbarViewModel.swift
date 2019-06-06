//
//  QPToolbarViewModel.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 31/05/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class QPToolbarViewModel {
    
    
    var bag = DisposeBag()
    var qpm: QuickPickerModel
    
    init(quickPickerModel: QuickPickerModel) {
        self.qpm = quickPickerModel
    }
    
    lazy var selectedSegmentIndex: BehaviorRelay<Int> = .init(value: 0)
    
    
    lazy var isUndoEnabled: Observable<Bool> = qpm.selectionStack.asObservable().map { !$0.isEmpty }
    
    lazy var countStatus: Observable<(String, UIColor, UIImage)> = self.countAttributes
    
    lazy var countAttributes = qpm.selection.map { (selection) -> (String, UIColor, UIImage) in
        let isOverMax = selection.count > self.qpm.selectionMode.max
        let color = isOverMax ? QuickPickerModel.redColor : UIColor.black
        let text = "\(selection.count)" + (self.qpm.showsLimit && self.qpm.selectionMode.hasMax ? "/\(self.qpm.selectionMode.max)" : "")
        let image = self.qpm.allowedMedia.image
        return (text, color, image)
    }
    
}
