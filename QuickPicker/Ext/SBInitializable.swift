// swiftlint:disable all

//  Created by Manuel Vrhovac on 29/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit

/// SBInitializable allows you to initialize ViewControllers from storyboard faster and more convenient.
protocol SBInitializable where Self: UIViewController {
    //init?(storyboardName sb: String?, viewControllerId id: String?,  bundle: Bundle?)
    //init?(storyboardName sb: String?)
}

extension SBInitializable {
    /*
    static func initWithStoryboardName(_ sb: String, bundle bun: Bundle? = nil) -> Self? {
        let className = NSStringFromClass(Self.self).from(".")
        let sb = UIStoryboard(name: sb ?? className, bundle: bun ?? Bundle(for: Self.self))
        let vc = sb.instantiateViewController(withIdentifier: className) as? Self
        if vc == nil {
            print("Couldn't find \(className) storyboard!")
        }
        return vc
    }*/
}

extension UIViewController: SBInitializable {
    
}

protocol ContainedVC where Self: UIViewController {
    func addToContainerView(_ containerView: UIView, in controller: UIViewController)
    func removeFromContainerView()
}

extension ContainedVC {
    
    private var mainView: UIView {
        return self.view!
        //self.loadViewIfNeeded()
        //return self.view.subviews.filter { $0.restorationIdentifier == "mainView"}.first ?? self.view ?? UIView()
    }
    
    
    func insertToContainerView(_ containerView: UIView, index: Int?, in controller: UIViewController) {
        removeFromContainerView()
        controller.addChild(self)
        removeFlexibleLabel()
        let mainView = self.mainView
        mainView.tintColor = containerView.tintColor ?? controller.view?.tintColor
        let last = max(0, containerView.subviews.count - 1)
        if let containerStack = containerView as? UIStackView {
            containerStack.insertArrangedSubview(mainView, at: index ?? last)
            containerStack.layoutSubviews()
        } else {
            containerView.insertSubview(mainView, at: index ?? last)
            containerView.layoutSubviews()
            mainView.snapToSuperview()
        }
    }
    
    func addToContainerView(_ containerView: UIView, in controller: UIViewController) {
        insertToContainerView(containerView, index: nil, in: controller)
    }
    
    private func removeFlexibleLabel() {
        if let thisStack = self.view as? UIStackView{
            let labels = thisStack.arrangedSubviews.compactMap { $0 as? UILabel}
            labels.filter { $0.text == "flexible"}.forEach{ $0.removeFromSuperview() }
        }
    }
    
    func removeFromContainerView() {
        if self.isViewLoaded == false { return }
        if self.view == nil { return }
        if self.parent != nil { removeFromParent() } else { return }
        if self.mainView.superview != nil { mainView.removeFromSuperview() }
    }
}
