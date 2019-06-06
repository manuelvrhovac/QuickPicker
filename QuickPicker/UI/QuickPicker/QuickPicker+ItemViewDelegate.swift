//
//  QuickPicker+ItemViewDelegate.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import KVFetcher
/*
extension QuickPicker: ItemViewModelDelegate {
    
    // MARK: - ItemViewModelDelegate
    /*
     func itemViewModel(_ itemViewModel: ItemViewModel, didUpdateSelectedItems selected: [PHAsset], deselected: [PHAsset]) {
     selection = selectedAssets.subtracting(deselected).union(selected)
     if selectionMode == .single && selectedAssets.count == 1 {
     playPressed(UIButton())
     selectedAssets = []
     }
     if case .multiple(let max) = selectionMode, selectedAssets.count > max {
     tooMany()
     delay(0.05) {
     self.undo(UIButton())
     }
     }
     }
     
     var selectedItems: [PHAsset] = []
     
     func alreadySelectedAssets(for itemViewModel: ItemViewModel) -> [PHAsset] {
     return Array(selectedAssets)
     }*/
    
    func itemViewModel(_ itemViewModel: ItemViewModel, didSelect selectedItems: [PHAsset], andDeselect deselectedItems: [PHAsset]) {
        self.selectedAssets = selectedAssets.subtracting(deselectedItems).union(selectedItems)
        refreshSelectedBar()
    }
    /*
     func bottomInset(for itemViewModel: ItemViewModel) -> CGFloat {
     return toolbarBG.frame.height
     }*/
    
    func selectedAssets(for itemViewModel: ItemViewModel) -> Set<PHAsset> {
        return self.selectedAssets
    }
    
}
*/
