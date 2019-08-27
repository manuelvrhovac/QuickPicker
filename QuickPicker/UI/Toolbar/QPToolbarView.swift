//
//  Created by Manuel Vrhovac on 31/05/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class QPToolbarView: UIView {
    
    static let defaultTabKinds: [TabKind] = [.recentlyAdded, .favorites, .groupRegular, .groupShared, .groupSmart]
    
    
    @IBOutlet private(set) weak var proceedButtonFill: UIButton!
    @IBOutlet private(set) weak var blur: UIVisualEffectView!
    @IBOutlet private(set) weak var mainStack: UIStackView!
    @IBOutlet private(set) weak var toolbarBG: UIToolbar!
    @IBOutlet private(set) weak var fullWidthSegmentStack: UIStackView!
    @IBOutlet private(set) weak var segment: UISegmentedControl!
    @IBOutlet private(set) weak var proceedButton: UIButton!
    @IBOutlet private(set) weak var undoButton: UIButton!
    @IBOutlet private(set) weak var buttonsAndInfoStack: UIStackView!
    @IBOutlet private(set) weak var gradientShadow: UIImageView!
    @IBOutlet private(set) weak var centerStack: UIStackView!
    @IBOutlet private(set) weak var itemCountLabel: UILabel!
    @IBOutlet private(set) weak var itemCountImageView: UIImageView!
    
    // MARK: Properties
    
    var view: UIView { return self }
    var viewModel: QPToolbarViewModel!
    var qpm: QuickPickerViewModel!
    var bag = DisposeBag()
    
    let invisibleStack = UIStackView()
    
    // MARK: Calculated
    
    /// Stack that is supposed to contain segmented control menu (depending on available screen width)
    private var segmentStack: UIStackView {
        if segment.numberOfSegments < 2 {
            return invisibleStack
        }
        switch view.frame.width {
        case 000 ..< 550: return fullWidthSegmentStack
        case 550 ..< 750: return buttonsAndInfoStack
        default: return centerStack
        }
    }
    
    // MARK: - Methods
    
    class func initFromNib(viewModel: QPToolbarViewModel) -> QPToolbarView {
        let nib = UINib(nibName: QPToolbarView.selfID, bundle: bundle)
        let view = nib.instantiate(withOwner: nil, options: nil)[0] as! QPToolbarView
        view.viewModel = viewModel
        return view
    }
    
    override func didMoveToWindow() {
        segment.removeAllSegments()
        for kind in qpm.tabKinds {
            segment.addSegment(with: kind.image, animated: false)
            if kind.isSingle {
                segment.segmentImageViews.last?.transform = .init(scaleX: 0.8, y: 0.8)
            }
        }
        
        setupBindings()
        
        segment.removeFromSuperview()
        segment.selectedSegmentIndex = 0
        segment.imageContentMode = .scaleAspectFit

        blur.layer.cornerRadius = 4.0
        blur.layer.masksToBounds = true
        
        proceedButtonFill.setImage(proceedButtonFill.imageView!.image!.template, for: .normal)
        proceedButtonFill.tintColor = tintColor
        
        moveSegmentIfNeeded()
    }
    
    func setupBindings() {
        bag.insert(
            segment.rx.value
                .bind(to: viewModel.selectedSegmentIndex),
            proceedButton.rx.tap
                .bind(onNext: {
                    self.proceedButton?.animateShrinkGrow(duration: 0.2)
                    self.proceedButtonFill?.animateShrinkGrow(duration: 0.2)
                    self.qpm.proceed()
                }),
            qpm.selection
                .map { !$0.isEmpty }
                .bind(to: proceedButton.rx.isEnabled),
            qpm.selection
                .map { !$0.isEmpty }
                .bind(to: proceedButtonFill.rx.isEnabled),
            undoButton.rx.tap
                .bind(onNext: qpm.undo),
            viewModel.countAttributes
                .bind(onNext: setCountAttributes),
            viewModel.isUndoEnabled
                .bind(to: undoButton.rx.isEnabled),
            viewModel.selectedSegmentIndex
                .compactMap { self.qpm.tabKinds[safe: $0] }
                .bind(to: qpm.selectedTabKind)
        )
    }
    
    
    /// Moves the segmentedControl according to screen width (iPad/iPhone in portrait, landscape). Called on layoutSubviews.
    private func moveSegmentIfNeeded() {
        guard segment.superview != segmentStack else { return }
        segment.removeFromSuperview()
        segmentStack.insertArrangedSubview(segment, at: min(segmentStack.subviews.count, 1))
        centerStack.isHidden = centerStack.subviews.isEmpty
        
        undoButton.isHidden = qpm.selectionMode == .single
        proceedButton.superview!.isHidden = qpm.selectionMode == .single
        buttonsAndInfoStack.hideIfNoVisibleSubviews()
        
        fullWidthSegmentStack.hideIfNoVisibleSubviews()
        gradientShadow.isHidden = fullWidthSegmentStack.isHidden
        blur.isHidden = gradientShadow.isHidden
        
        segment.tintColor = gradientShadow.isHidden ? view.tintColor : .white
        
        blur.effect = UIBlurEffect(style: .light)
        blur.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        layoutIfNeeded()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        moveSegmentIfNeeded()
    }
    
    func setCountAttributes(_ tuple: (text: String, color: UIColor, image: UIImage)) {
        itemCountLabel.text = tuple.text
        itemCountLabel.textColor = tuple.color
        itemCountImageView.image = tuple.image
    }
    
}
