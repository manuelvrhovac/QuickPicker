//
//  ImageBarButton.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 27/08/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit

class ImageBarButton: UIBarButtonItem {
    
    //typealias Action = (UIBarButtonItem) -> Void
    
    private var button = UIButton()
    var tinted: Bool = true
    //var actionBlock: Action?
    
    override var image: UIImage? {
        didSet {
            let tintedImage = image?.withRenderingMode(renderingMode)
            button.setImage(tintedImage, for: .normal)
        }
    }
    
    private var renderingMode: UIImage.RenderingMode {
        return tinted ? .alwaysTemplate : .alwaysOriginal
    }
    

    init(image: UIImage, tinted: Bool, size: CGSize, target: Any?, action: Selector) {
        let image = UIImage(bundleNamed: "selectAll").withRenderingMode(tinted ? .alwaysTemplate : .alwaysOriginal)
        super.init()
        self.tinted = tinted
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentMode = .scaleAspectFit
        button.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        button.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        button.addTarget(target, action: action, for: .touchUpInside)
        customView = button
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    @objc
    func pressed() {
        self.actionBlock?(self)
    }*/
}
