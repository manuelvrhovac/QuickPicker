//
//  Created by Manuel Vrhovac on 01/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import UIKit
import Photos
import RxSwift
import RxCocoa

/// ViewController used to display QuickPicker. Use 'initFromSB(viewModel:)' to initialize. Call 'present' method on current view controller to display the quick picker. See 'QuickPicker.ViewModel' for more.
/// - **config**: Contains configuration options like selection mode, limit, type of selection etc.
/// - **delegate**: Delegate with methods that execute when user has canceled or finished picking assets.
/// - **completion**: A completion block that executes when user has canceled or finished picking assets.
///
/// **Note**: You may leave 'completion' as nil if you plan to use delegate
public class QuickPicker: UIViewController {
    
    // MARK: - UI Properties
    
    private var containerStack: UIStackView!
    private var toolbarContainerStack: UIView!
    
    // MARK: - Public Properties
    
    /// Contains configuration options like selection mode, limit, type of selection etc.
    public var config: Config {
        set {
            viewModel.config = newValue
        }
        get {
            return viewModel.config
        }
    }
    
    /// A completion block that executes when user has canceled or finished picking assets.
    public var completion: Completion?
    
    /// Delegate with methods that execute when user has canceled or finished picking assets.
    public weak var delegate: QuickPickerDelegate?
    
    
    // MARK: Private
    
    private var navigationControllers = [TabKind: CTNavigationController]()
    private var viewModel: QuickPicker.ViewModel!
    private var bag: DisposeBag = .init()
    private var toolbar: QPToolbarView!
    
    
    // MARK: Calculated
    
    var allItemViews: [ItemView] {
        return navigationControllers
            .flatMap { $0.value.viewControllers }
            .compactMap { $0.view as? ItemView }
    }
    
    var selectedNavigationController: CTNavigationController {
        return navigationControllers[viewModel.selectedTabKind.value]!
    }
    
    var selectedViewControllers: [CTNavigationController] {
        return selectedNavigationController.viewControllers as! [CTNavigationController]
    }
    
    
    // MARK: - Initialization
    
    /// Default init method for QuickPicker.
    /// - parameter config: Contains configuration options like selection mode, limit, type of selection etc.
    /// - parameter preselected: Assets that should be already selected when picker shows up
    /// - parameter completion: A completion block that will execute when user has canceled or finished picking assets.
    ///
    /// **Note**: You may leave 'completion' as nil if you plan to use delegate
    public init(configuration: Config, preselected: [PHAsset]?, completion: Completion?) {
        self.viewModel = .init(config: configuration, preselected: preselected)
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    internal init(viewModel: QuickPicker.ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: bundle)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - ViewController Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        containerStack = .init(frame: .zero)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        containerStack.distribution = .fillEqually
        containerStack.axis = .vertical
        view.addSubview(containerStack)
        containerStack.snapToSuperview()
        
        toolbarContainerStack = .init(frame: .zero)
        toolbarContainerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbarContainerStack)
        
        NSLayoutConstraint.activate([
            toolbarContainerStack.leadingAnchor.constraint(equalTo: containerStack.leadingAnchor),
            toolbarContainerStack.trailingAnchor.constraint(equalTo: containerStack.trailingAnchor),
            toolbarContainerStack.bottomAnchor.constraint(equalTo: containerStack.bottomAnchor)
        ])
        
        self.view.tintColor = viewModel.config.tintColor
        
        for kind in viewModel.config.tabKinds {
            let tabViewModel = viewModel.tabViewModel(for: kind)!
            let vc: UIViewController = createAndBindTabViewController(tabModel: tabViewModel)
            let nc = CTNavigationController(customToolbarView: nil, rootViewController: vc)
            nc.setToolbarHidden(false, animated: true)
            navigationControllers[kind] = nc
            containerStack.addArrangedSubview(nc.view)
        }
        
        // Now add the toolbar to toolbarContainer:
        
        let toolbarViewModel = QPToolbarViewModel(quickPickerViewModel: viewModel)
        toolbar = QPToolbarView.initFromNib(viewModel: toolbarViewModel)
        toolbar.quickPickerViewModel = viewModel
        toolbarContainerStack.addSubview(toolbar)
        toolbar.snapToSuperview()
        setupBindings()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    func setupBindings() {
        bag.insert(
            viewModel.userError
                .bind(onNext: displayUserError(_:)),
            viewModel.selectedTabKind
                .bind(onNext: changeTab(to:)),
            viewModel.itemViewModel
                .bind(onNext: push(itemViewModel:)),
            viewModel.reviewViewModel
                .bind(onNext: present(reviewViewModel:)),
            viewModel.onFinish
                .bind(onNext: finish(result:)),
            viewModel.onUndo
                .bind(onNext: showUndoHUD(flag:))
        )
        
        if let firstTab = viewModel.config.tabKinds.first {
            viewModel.selectedTabKind.accept(firstTab)
        }
    }
    
    func push(itemViewModel: ItemViewModel?) {
        guard let itemViewModel = itemViewModel else { return }
        let vc = createAndBindTabViewController(tabModel: itemViewModel)
        selectedNavigationController.pushViewController(vc, animated: true)
    }
    
    func present(reviewViewModel: ReviewViewModel?) {
        guard let reviewViewModel = reviewViewModel else { return }
        let reviewViewController = ReviewViewController.initi(viewModel: reviewViewModel)
        self.present(reviewViewController, animated: false, completion: nil)
    }
    
    func finish(result: Result) {
        completion?(self, result)
        switch result {
        case .canceled:
            print("Canceled")
            delegate?.quickPickerDidCancel()
        case .finished(let assets):
            print("Got \(assets.count) assets")
            delegate?.quickPicker(didFinishPickingAssets: assets)
        }
    }
    
    /// Convenience method. Created for each tab, each of them has a cancel (x) button. May be single collection tab or collection group tab.
    func createAndBindTabViewController(tabModel: TabViewModel) -> UIViewController {
        let vc = UIViewController(nibName: nil, bundle: nil)
        
        let xImage = UIImage(bundleNamed: "cancel").template
        let xButton = ImageBarButtonItem(buttonImage: xImage, size: .init(width: 30.0, height: 30.0))
        xButton.button.rx.tap.bind(onNext: viewModel.cancel).disposed(by: bag)
        
        vc.navigationItem.insertRightBarButtonItem(xButton, at: 0)
        
        switch tabModel {
        case let ivm as ItemViewModel:
            let itemView = ItemView(viewModel: ivm)
            vc.view = itemView
            vc.title = ivm.title
            if viewModel.config.selectionMode != .single {
                vc.navigationItem.addRightBarButtonItem(itemView.selectAllBarButtonItem)
            }
        case let avm as AlbumViewModel:
            let albumView = AlbumView(viewModel: avm)
            vc.view = albumView
            vc.title = avm.title
        default: fatalError("Unknown tab view controller")
        }
        return vc
    }
    
    // MARK: Interaction
    
    func showUndoHUD(flag: Bool) {
        guard viewModel.config.selectionMode != .single else { return } // no undo if single
        guard !viewModel.selectionStack.value.isEmpty else { return }
        view.viewWithRestorationIdentifier("hud")?.removeFromSuperview()
        let hud = HUDView(size: 160.0, text: "⃔", fontSize: 90.0)
        hud.restorationIdentifier = "hud"
        hud.show(in: view, disappearAfter: 0.5)
    }
    
    func changeTab(to tabKind: TabKind) {
        for nc in self.navigationControllers.values {
            nc.view.isHidden = nc !== self.selectedNavigationController
        }
        guard !self.navigationControllers.isEmpty else { return }
        let nc = self.selectedNavigationController
        
        // Migrate toolbar to this navigation controller:
        nc.customToolbarView = toolbar
        nc.view.layoutSubviews()
        delay(1.0) {
            nc.view.layoutSubviews()
        }
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: true, completion: {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        })
        /*let offset = UIScreen.main.bounds.height
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: {
            self.view.transform = .init(translationX: 0.0, y: offset)
            self.view.transform = .init(scaleX: 0.5, y: 0.5)
            self.view.alpha = 0.0
            self.presentedViewController?.view.transform = self.view.transform
        }, completion: { _ in
            mainThread {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                super.dismiss(animated: false, completion: completion)
            }
        })*/
        /*
        UIView.animate(withDuration: 0.4, animations: {
            self.view.transform = .init(translationX: 0.0, y: offset)
            self.view.transform = .init(scaleX: 0.5, y: 0.5)
            self.view.alpha = 0.0
            self.presentedViewController?.view.transform = self.view.transform
        }, completion: { _ in
            mainThread {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                super.dismiss(animated: false, completion: completion)
            }
        })*/
    }
    
    func displayUserError(_ error: String?) {
        guard let error = error else { return }
        print(error)
        displayOverLimitMessage()
    }
    
    @objc
    func applicationDidBecomeActive() {
        viewModel.checkForDeletedAssetsFromUndoStack()
        allItemViews.forEach { $0.viewModel.reloadCollection() }
    }
    
    
    
    
    private func displayOverLimitMessage() {
        guard case .multiple(let max) = viewModel.config.selectionMode else { return }
        let alert = UIAlertController(title: "Maximum \(max) items", message: "You have selected more items than allowed", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        mainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}




public extension QuickPicker {
    
    // Result used in Completion Handler
    enum Result {
        case canceled
        case finished(assets: [PHAsset])
    }
    
    typealias Completion = (QuickPicker, Result) -> Void
    
}


public protocol QuickPickerDelegate: class {
    
    func quickPicker(/*_ imagePicker: QuickPicker, */didFinishPickingAssets assets: [PHAsset])
    func quickPickerDidCancel(/*_ imagePicker: QuickPicker*/)
}
