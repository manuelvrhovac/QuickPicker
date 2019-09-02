//
//  Created by Manuel Vrhovac on 13/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import RxSwift
import RxCocoa


class ReviewViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet private(set) weak var countLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var slider: UISlider!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var mainStack: UIStackView!
    
    @IBOutlet private(set) weak var cvStack: UIStackView!
    @IBOutlet private(set) weak var addMoreButton: UIButton!
    
    @IBOutlet private(set) weak var buttonStack: UIStackView!
    
    // MARK: Properties
    
    var viewModel: ReviewViewModel!
    var swipeGestureRecognizer: UISwipeGestureRecognizer!
    var leftSwipe: UISwipeGestureRecognizer!
    var collectionView: SmartLayoutCollectionView!
    var playerView: AVPlayerViewController!
    var bag = DisposeBag()

    // MARK: Calculated
    
    var removeButton: UIButton {
        return view.all(UIButton.self).last!
    }
    var mediaStack: UIStackView {
        return imageView.superview as! UIStackView
    }
    
    var currentIndex: Int {
        return viewModel.currentIndex.value
    }
    
    var player: AVPlayer! {
        get { return playerView.player }
        set { playerView?.player = newValue }
    }
    
    
    // MARK: - Init

    
    override func viewDidLoad() {
        super.viewDidLoad()
        confirmButton.layer.cornerRadius = 10.0
        confirmButton.backgroundColor = view.tintColor
        
        cancelButton.layer.cornerRadius = 10.0
        cancelButton.layer.addShadow(.black, o: 0.18, r: 14.0, d: 8.0)
        
        addMoreButton.layer.cornerRadius = 10.0
        
        imageView.contentMode = .scaleAspectFit
        
        addMoreButton.isHidden = !viewModel.canAddMore
        
        
        leftSwipe = .init(target: self, action: #selector(swipe))
        leftSwipe.direction = .right
        imageView.addGestureRecognizer(leftSwipe)
        
        swipeGestureRecognizer = .init(target: self, action: #selector(swipe))
        swipeGestureRecognizer.direction = .left
        
        imageView.addGestureRecognizer(swipeGestureRecognizer)
        imageView.isUserInteractionEnabled = true
        
        collectionView = .init(spacing: 3.0, maximumItemWidth: 56)
        collectionView.flowLayout.scrollDirection = .horizontal
        cvStack.addArrangedSubview(collectionView)
        
        collectionView.registerNibForCellWith(reuseIdentifier: ItemCellView.selfID, bundle: bundle)
        collectionView.dataSource = self
        collectionView.contentInset = .zero
        collectionView.layoutMargins = .zero
        collectionView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        collectionView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                   action: #selector(cvTapped)))
        collectionView.layer.cornerRadius = 6.0
        collectionView.alwaysBounceHorizontal = true
        collectionView.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        reload()
        
        playerView = .init()
        playerView.player = .init()
        playerView.view.backgroundColor = .clear
        mediaStack.addArrangedSubview(playerView.view)
        
        setupBindings()
        viewModel.assets.accept(viewModel.assets.value)
    }
    
    static func initi(viewModel: ReviewViewModel) -> ReviewViewController {
        let rvc = UIStoryboard.instantiateVC(ReviewViewController.self)
        rvc.viewModel = viewModel
        return rvc
    }

    func setupBindings() {
        let assetsChanged = viewModel
            .assets
            .share()
        
        let assetsCount = assetsChanged
            .map { $0.count }
            .share()
        
        let sliderValue = slider.rx.value
            .map { return Int($0 * Float(self.viewModel.numberOfItems - 1)) }
            .distinctUntilChanged()
            .share()
        
        bag.insert(
            viewModel.currentIndex
                .bind(onNext: indexChanged),
            viewModel.onFinish
                .bind(onNext: clearAndDismiss(result:)),
            assetsChanged
                .map { _ in }
                .bind(onNext: reload),
            assetsCount
                .map { $0 < 2 }
                .bind(to: removeButton.rx.isHidden),
            assetsCount
                .map { $0 < 2 }
                .bind(to: cvStack.rx.isHidden),
            assetsCount
                .map { $0 < 30 }
                .bind(to: slider.superview!.rx.isHidden),
            sliderValue
                .throttleMain(0.1)
                .bind(to: viewModel.currentIndex),
            sliderValue
                .debounceMain(0.1)
                .bind(onNext: indexChangedScroll),
            removeButton.rx.tap
                .delayMain(0.1)
                .bind(onNext: viewModel.removeCurrentAsset),
            cancelButton.rx.tap
                .delayMain(0.1)
                .bind(onNext: { self.viewModel.finish(.canceled) }),
            confirmButton.rx.tap
                .delayMain(0.1)
                .bind(onNext: { self.viewModel.finish(.confirmed) }),
            addMoreButton.rx.tap
                .delayMain(0.1)
                .bind(onNext: { self.viewModel.finish(.wantsMore) })
        )
        
        for button in [removeButton, cancelButton, confirmButton, addMoreButton] {
            button?.rx.tap.bind(onNext: {
                button?.animateShrinkGrow(duration: 0.2)
            }).disposed(by: bag)
        }
        
    }
    
    
    func preview(result: ReviewViewModel.PreviewResult) {
        var isImage = true
        switch result {
        case .image(let image):
            imageView.image = image
            playerView?.player?.pause()
            playerView?.player = .init()
        case .video(let url):
            isImage = false
            player = .init(url: url)
        }
        imageView.isHidden = !isImage
        playerView.view.isHidden = isImage
    }
    
    
    func clearAndDismiss(result: ReviewViewModel.Result) {
        if result != .confirmed {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
    }
    
    func indexChanged(index: Int) {
        guard countLabel != nil else { return }
        countLabel.text = viewModel.countText
        if !slider.isTracking {
            slider.value = Float(index) / Float(viewModel.numberOfItems - 1)
        }
        viewModel.getPreview(atIndex: index) { result in
            guard index == self.viewModel.currentIndex.value else { return }
            self.preview(result: result)
        }
    }
    
    
    func reload() {
        self.collectionView?.reloadData()
    }
    
    
    func setViews(hidden: Bool) {
        [view, cancelButton, confirmButton].compactMapAs(UIView.self).forEach {
            $0.transform = .init(scaleX: hidden ? 0.7 : 1.0, y: hidden ? 0.7 : 1.0)
            $0.alpha = hidden ? 0.0 : 1.0
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if viewModel.numberOfItems == 0 {
            dismiss(animated: false, completion: nil)
            return
        }
        
        setViews(hidden: true)
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        self.setViews(hidden: false)
        }, completion: nil)
        
        titleLabel.text = viewModel.title(forLanguage: "en")
    }
    
    
    // MARK: Interaction
    
    @objc
    func swipe(_ swipe: UISwipeGestureRecognizer) {
        let index = currentIndex + (swipe.direction == .left ? 1 : -1)
        viewModel.currentIndex.v = index.fixOverflow(count: viewModel.numberOfItems)
    }
    
    
    func indexChangedScroll(newIndex: Int) {
        UIView.animate(withDuration: 0.1) {
            self.collectionView.scrollToItem(at: .init(row: newIndex, section: 0),
                                             at: .centeredHorizontally,
                                             animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        delay(0.01) {
            self.moveSliderIfNeeded()
        }
    }
    
    @objc
    func cvTapped(tap: UITapGestureRecognizer) {
        let location = tap.location(in: collectionView)
        if let i = collectionView.indexPathForItem(at: location) {
            viewModel.currentIndex.accept(i.row)
        }
    }
    
    // MARK: Layout
    
    /// Rearanges the slider according to screen width.
    func moveSliderIfNeeded() {
        let cvContainer = collectionView.superview! // the container to be moved
        let landscape = mainStack.frame.width > 400
        let isSeparate = mainStack.arrangedSubviews.contains(cvContainer)
        if landscape && isSeparate {
            cvContainer.removeFromSuperview()
            buttonStack.insertArrangedSubview(cvContainer, at: 1)
        }
        if !landscape && !isSeparate {
            cvContainer.removeFromSuperview()
            let sliderI = mainStack.arrangedSubviews
                .enumerated()
                .first(where: { $0.element === slider })?
                .offset
            mainStack.insertArrangedSubview(cvContainer, at: (sliderI ?? 2) + 1)
        }
        collectionView.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        self.view.layoutIfNeeded()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

// MARK: -


extension ReviewViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
        let ivm = viewModel.itemCellViewModel(atIndex: indexPath.row)
        ivm.fetchImage()
        let cell = collectionView.dequeue(ItemCellView.self, for: indexPath)!
        cell.configure(viewModel: ivm)
        cell.imageView.layer.cornerRadius = 4.0
        cell.shadow.layer.cornerRadius = 4.0
        return cell
    }
}
