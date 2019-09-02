//
//  Created by Manuel Vrhovac on 26/08/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//


import Foundation
import UIKit

/// Little black rectangle that appears in center of some UIView with a message and disappears quickly. Like Volume HUD, for example.
class HUDView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(size: CGFloat, text: String, fontSize: CGFloat) {
        super.init(frame: .init(x: 0, y: 0, width: size, height: size))
        backgroundColor = #colorLiteral(red: 0.04825023408, green: 0.04825023408, blue: 0.04825023408, alpha: 1).withAlphaComponent(0.8)
        layer.cornerRadius = 10.0
        clipsToBounds = true
        restorationIdentifier = "blackRect"
        
        let label = UILabel(frame: .init(x: 0, y: size * 0.1, width: size, height: size))
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: fontSize)
        label.textAlignment = .center
        label.textColor = .white
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(in view: UIView, disappearAfter: Double) {
        center = view.center
        view.addSubview(self)
        UIView.animate(withDuration: 0.3, delay: disappearAfter, options: [], animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}
