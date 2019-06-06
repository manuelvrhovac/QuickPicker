//
//  ItemCellView.swift
//  QuickPicker
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
    private var bag: DisposeBag = .init()
    
    var viewModel: ItemCellViewModel!
    
    override var isSelected: Bool {
        get {
            return viewModel.isSelected.v
        }
        set {
            guard viewModel != nil else { return }
            if viewModel.isSelected.v != newValue {
                viewModel.isSelected.v = newValue
            }
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        imageView.layer.masksToBounds = true
        iconImageView.tintColor = .white
        iconImageView.isHidden = false
        iconImageView.layer.addShadow(.black, o: 0.3, r: 3.0, d: 2.0)
    }
    
    
    func configure(viewModel: ItemCellViewModel) {
        self.viewModel = viewModel
        configureViewModel()
        self.viewModel.fetchImage()
    }
    
    
    func configureViewModel() {
        viewModel.rxIcon.bind(to: iconImageView.rx.image).disposed(by: bag)
        viewModel.rxIcon.map { $0 == nil }.bind(to: iconImageView.rx.isHidden).disposed(by: bag)
        viewModel.image.bind(to: imageView.rx.image).disposed(by: bag)
        viewModel.rxIcon.bind(onNext: { icon in
            self.iconImageView.image = icon
        }).disposed(by: bag)
        
        viewModel.rxDurationText.bind(onNext: updateDurationLabel).disposed(by: bag)
        viewModel.rxDurationText.map { $0.isNilOrEmpty }.bind(to: durationLabel.rx.isHidden).disposed(by: bag)
        viewModel.isSelected.bind(onNext: updateIsSelected(selected:)).disposed(by: bag)
        viewModel.selectionStyle.bind(onNext: updateSelectionStyle).disposed(by: bag)
        
        // Force change now:
        viewModel.item.accept(viewModel.item.value)
        /*let item = viewModel.item.value
        viewModel.item.v = nil
        viewModel.item.v = item*/
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
            //imageView.transform = .identity
            imageView.layer.removeBorder()
            backgroundColor = .clear
        case .outline:
            //let w = imageView.frame.width
            //let scale = isSelected ? (w-6.0)/w : 1.0
            checkmark.isHidden = true
            imageView.alpha = 1.0
            imageView.layer.addBorder(tintColor, width: selected ? 3.0 : 0.0)
            //imageView.transform = .init(scaleX: scale, y: scale)
            //backgroundColor = isSelected ? tintColor : .clear
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
        for sublayer in shadow.layer.sublayers ?? [] {
            sublayer.frame = sublayer.superlayer!.bounds
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
