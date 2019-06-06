//
//  ImageBarButton.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 05/06/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

/// A UIBarButtonItem subclass with 'button' property. Also has 'image' property for easier image assigning.
class ImageBarButtonItem: UIBarButtonItem {
    
    var button: UIButton {
        return customView as! UIButton
    }
    override var image: UIImage? {
        get {
            return button.image(for: .normal)
        }
        set {
            button.setImage(newValue, for: .normal)
        }
    }
    
    init(buttonImage: UIImage?, size: CGSize) {
        let button = UIButton()
        button.setImage(buttonImage, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        button.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        super.init()
        self.customView = button
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
