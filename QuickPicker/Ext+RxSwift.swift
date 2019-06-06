//
//  Ext+RxSwift.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 20/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Observable {
    
}

extension BehaviorRelay {
    
    
    var v: Element {
        get {
            return value
        }
        set {
            accept(newValue)
        }
    }
    
    public func subscribeNext(_ onNext: ((Element) -> Void)?) -> Disposable {
        return subscribe(onNext: onNext, onError: nil, onCompleted: nil, onDisposed: nil)
    }
    public func subscribeNext(_ onNext: (() -> Void)?) -> Disposable {
        return subscribe(onNext: { _ in onNext?() }, onError: nil, onCompleted: nil, onDisposed: nil)
    }
}

extension BehaviorRelay where Element: RangeReplaceableCollection {
    
    func acceptAppending(_ element: Element.Element) {
        accept(value + [element])
    }
}
