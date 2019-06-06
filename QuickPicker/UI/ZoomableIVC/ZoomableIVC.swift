//
//  ZoomableIVC.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 29/08/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit
/*
protocol ZoomableIVCDelegate: class {
    
    func insets(for zoomableIVC: ZoomableIVC) -> UIEdgeInsets
}*/

class ZoomableIVC: UIViewController, ContainedVC {
    
    var i: ZoomableScrollViewController = .init()
    
    var stack: UIStackView {
        return view.subviews.first as! UIStackView
    }
    
    var image: UIImage? {
        didSet {
            self.i.imageView?.image = image
        }
    }
    
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    static func initi(image: UIImage?) -> ZoomableIVC {
        let v = ZoomableIVC.initi(storyboarddName: nil)!
        v.stack.addArrangedSubview(v.i.view)
        v.addChild(v.i)
        return v
    }
    
    override func viewDidLayoutSubviews() {
        //self.navigationController?.bottomLayoutGuide
        let insets = UIEdgeInsets(top: 0.0,
                                  left: 0.0,
                                  bottom: 0.0,
                                  right: 0.0)
        stack.snapToSuperview(insets: insets)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.i.imageView?.image = image
        //self.view.snapToSuperview()
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
