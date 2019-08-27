//
//  Created by Manuel Vrhovac on 16/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import KVFetcher
import RxSwift
import RxCocoa

class ItemCellView: UICollectionViewCell {
    
    @IBOutlet private(set) weak var imageView: UIImageView!
    @IBOutlet private(set) weak var shadow: UIImageView!
    @IBOutlet private(set) weak var iconImageView: UIImageView!
    @IBOutlet private(set) weak var durationLabel: UILabel!
    @IBOutlet private(set) weak var checkmark: UIImageView!
    
    static let placeholderImage = UIImage(bundleNamed: "placeholder")
    static let shadowImage = UIImage(bundleNamed: "shadow")
    private var bag: DisposeBag = .init()
    
    var viewModel: ItemCellViewModel!
    
    /// Get/Set RX value from the viewModel instead
    override var isSelected: Bool {
        get {
            return viewModel.isSelected.v
        }
        set {
            viewModel?.isSelected.v = newValue
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMoveToWindow() {
        imageView.layer.masksToBounds = true
        iconImageView.tintColor = .white
        iconImageView.isHidden = false
        shadow.alpha = 0.6
        //iconImageView.layer.addShadow(.black, o: 0.3, r: 3.0, d: 2.0)
    }
    
    
    func configure(viewModel: ItemCellViewModel) {
        self.viewModel = viewModel
        configureViewModel()
        self.viewModel.fetchImage()
    }
    
    
    func configureViewModel() {
        bag.insert(
            viewModel.rxIcon
                .bind(to: iconImageView.rx.image),
            viewModel.rxIcon
                .map { $0 == nil }
                .bind(to: iconImageView.rx.isHidden),
            viewModel.image
                .bind(to: imageView.rx.image),
            viewModel.rxIcon
                .bind(to: iconImageView.rx.image),
            viewModel.rxDurationText
                .bind(onNext: updateDurationLabel),
            viewModel.rxDurationText
                .map { $0.isNilOrEmpty }
                .bind(to: durationLabel.rx.isHidden),
            viewModel.isSelected
                .bind(onNext: updateIsSelected(selected:)),
            viewModel.selectionStyle
                .bind(onNext: updateSelectionStyle)
        )
        
        // Force change now:
        viewModel.item.accept(viewModel.item.value)
    }
    
    func updateDurationLabel(text: String?) {
        durationLabel.text = text
        durationLabel.isHidden = text == nil
        shadow.isHidden = text == nil
        guard text != nil else { return }
        if (shadow.layer.sublayers ?? []).isEmpty {
            let shadowLayer = CAGradientLayer(start: .topCenter,
                                              end: .bottomCenter,
                                              colors: [.clear, .black],
                                              type: .axial)
            shadowLayer.frame = shadow.bounds
            shadow.layer.addSublayer(shadowLayer)
        }
    }
    
    func updateSelectionStyle(selectionStyle: ItemCellViewModel.SelectionStyle) {
        updateIsSelected(selected: isSelected)
    }
    
    func updateIsSelected(selected: Bool) {
        checkmark.isHidden = !selected
        switch viewModel.selectionStyle.value {
        case .checkmark:
            checkmark.isHidden = !selected
            imageView.alpha = selected ? 0.7 : 1.0
            imageView.layer.removeBorder()
            backgroundColor = .clear
        case .outline:
            checkmark.isHidden = true
            imageView.alpha = 1.0
            imageView.layer.addBorder(tintColor, width: selected ? 3.0 : 0.0)
            if selected {
                layer.addShadow(.black, o: 0.7, r: 6.0, d: 2.0)
                layer.masksToBounds = false
            } else {
                layer.removeShadow()
            }
        }
        self.layer.removeAllAnimations()
    }
    
    
    // MARK: - Other
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let shadowLayer = shadow.layer.sublayers?.compactMapAs(CAGradientLayer.self).first {
            shadowLayer.frame = shadow.bounds
            shadow.clipsToBounds = true
        }
        let fontSize: CGFloat = 11.0 * (frame.width / 80.0)
        let f = durationLabel.font!
        durationLabel.font = UIFont(name: f.fontName, size: fontSize)
    }
    
    
    override func prepareForReuse() {
        alpha = 1.0
        viewModel = nil
        iconImageView.image = nil
        imageView.image = nil
        durationLabel.isHidden = true
        shadow.isHidden = true
        bag = .init()
    }
}
