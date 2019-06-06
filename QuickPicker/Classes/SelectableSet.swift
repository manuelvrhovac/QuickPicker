//
//  SelectableSet.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 13/07/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation

public protocol SelectableSetDelegate: class {
    
    func selectableSet(_ selectableSet: SelectableSet, didSelect indexes: Set<Int>)
    func selectableSet(_ selectableSet: SelectableSet, didDeselect indexes: Set<Int>)
    func selectableSetDidUpdateIndexes(_ selectableSet: SelectableSet)
}

public class SelectableSet {
    
    private var max: Int
    weak var delegate: SelectableSetDelegate!
    var latestSelection: Set<Int> = []//{ return undoStack.last ?? [] }

    private(set) var selectedIndexes = Set<Int>() {
        willSet {
            let oldValue = selectedIndexes
            let needDeselect = oldValue.subtracting(newValue)
            let needSelect = newValue.subtracting(oldValue)
            delegate?.selectableSet(self, didSelect: needSelect)
            delegate?.selectableSet(self, didDeselect: needDeselect)
        }
    }
    var deselectedIndexes: Set<Int> { return Set(0..<max).subtracting(selectedIndexes) }
    
    // MARK: - Methods
    
    public init(max: Int, delegate: SelectableSetDelegate? = nil) {
        self.max = max
        self.delegate = delegate
    }
    
    func update(_ indexes: Set<Int>, selected: Bool, permanent: Bool = true/*, initial: Set<Int>? = nil*/) {
        selectedIndexes = selected ? selectedIndexes.union(indexes) : selectedIndexes.subtracting(indexes)
        if permanent {
            save()
        }
    }
    
    func save() {
        latestSelection = selectedIndexes
        delegate?.selectableSetDidUpdateIndexes(self)
    }
    
    
    // shortcut methods:
    func select(_ indexes: Set<Int>, permanent: Bool = true) {
        update(indexes, selected: true, permanent: permanent)
    }
    func deselect(_ indexes: Set<Int>, permanent: Bool = true) {
        update(indexes, selected: false, permanent: permanent)
    }
    
    func select(_ index: Int, permanent: Bool = true) {
        update(Set([index]), selected: true, permanent: permanent)
    }
    func deselect(_ index: Int, permanent: Bool = true) {
        update(Set([index]), selected: false, permanent: permanent)
    }
    
    
    func clearAndSet(_ indexes: Set<Int>, selected: Bool, permanent: Bool = true) {
        // normally you are setting selected indexes and start from an empty set.
        // other option is to set deselected, in that case you substract from all.
        let newSelectedIndexes = selected ? indexes : Set(0..<max).subtracting(indexes)
        select(newSelectedIndexes, permanent: permanent)
    }
    
    func toggle(_ index: Int, permanent: Bool = true) {
        toggle([index], permanent: permanent)
    }
    
    func toggle(_ indexes: Set<Int>, permanent: Bool = true) {
        let existingEntries = latestSelection.intersection(indexes)
        let nonexistingEntries = indexes.subtracting(existingEntries)
        let newSelection = latestSelection.subtracting(existingEntries).union(nonexistingEntries)
        if newSelection == selectedIndexes { return }
        clearAndSet(newSelection, selected: true, permanent: permanent)
    }
    
    func toggle(_ range: CountableClosedRange<Int>, permanent: Bool = true) {
        toggle(Set(range), permanent: permanent)
    }
    
}
