//
//  Created by Manuel Vrhovac on 31/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit

class FlexibleToolbar: UIToolbar {
    
    var height: CGFloat = 150.0 {
        didSet {
            self.layoutSubviews()
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var newSize: CGSize = super.sizeThatFits(size)
        newSize.height = self.height  // there to set the toolbar height
        return newSize
    }
}

/// CT stands for custom toolbar (UIToolbar instance).
class CTNavigationController: UINavigationController {
    
    var flexibleToolbar: FlexibleToolbar! {
        return toolbar as? FlexibleToolbar
    }
    
    var customToolbarView: UIView? {
        didSet {
            self.viewDidLayoutSubviews()
        }
    }
    
    convenience init(customToolbarView: UIView?, rootViewController: UIViewController) {
        self.init(navigationBarClass: nil, toolbarClass: FlexibleToolbar.self)
        self.customToolbarView = customToolbarView
        self.viewControllers = [rootViewController]
    }
    
    override func viewDidLayoutSubviews() {
        if let ctv = customToolbarView {
            if ctv.superview == nil {
                view.addSubview(ctv)
                view.backgroundColor = .clear
                ctv.backgroundColor = .clear
                ctv.snapToSuperview(side: .bottom, constant: nil)
                self.view.layoutSubviews()
            }
            flexibleToolbar.height = ctv.frame.height
        }
        flexibleToolbar.isHidden = true
    }
    
}
