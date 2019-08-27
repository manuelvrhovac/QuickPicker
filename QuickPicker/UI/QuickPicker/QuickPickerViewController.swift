//
//  Created by Manuel Vrhovac on 01/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import UIKit
import Photos
import RxSwift
import RxCocoa

/// ViewController used to display QuickPicker. Use 'initFromSB(viewModel:)' to initialize. Call 'present' method on current view controller to display the quick picker. See 'QuickPickerViewModel' for more.
public class QuickPickerViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var containerStack: UIStackView!
    @IBOutlet private(set) weak var toolbarContainerStack: UIView!

    // MARK: - Properties
    
    private var navigationControllers = [TabKind: CTNavigationController]()
    weak var viewModel: QuickPickerViewModel!
    var bag: DisposeBag = .init()
    var toolbar: QPToolbarView!
    
    // MARK: Calculated
    
    var allItemViews: [ItemView] {
        return navigationControllers
            .flatMap { $0.value.viewControllers }
            .compactMap { $0.view as? ItemView }
    }
    
    private var selectedNavigationController: CTNavigationController {
        return navigationControllers[viewModel.selectedTabKind.value]!
    }
    
    var selectedViewControllers: [CTNavigationController] {
        return selectedNavigationController.viewControllers as! [CTNavigationController]
    }
    
    
    // MARK: - Initialization
    
    /// Default init method using viewModel.
    public static func initFromSB(viewModel: QuickPickerViewModel) -> QuickPickerViewController {
        let qp: QuickPickerViewController! = UIStoryboard.instantiateVC(QuickPickerViewController.self)
        qp.viewModel = viewModel
        return qp
    }
    
    
    // MARK: - ViewController Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.tintColor = viewModel.tintColor
        
        for kind in viewModel.tabKinds {
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
        toolbar.qpm = viewModel
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
            viewModel.itemViewModels.bind(onNext: { ivms in
                guard let itemViewModel = ivms.last else { return }
                let vc = self.createAndBindTabViewController(tabModel: itemViewModel)
                self.selectedNavigationController.pushViewController(vc, animated: true)
            }),
            viewModel.reviewViewModel.bind(onNext: { rvm in
                guard let rvm = rvm else { return }
                let rvc = ReviewViewController.initi(viewModel: rvm)
                self.present(rvc, animated: false, completion: nil)
            }),
            viewModel.userError
                .bind(onNext: displayUserError),
            viewModel.onFinish
                .map { _ in }
                .bind(onNext: clear),
            viewModel.selectedTabKind
                .bind(onNext: changeTab(to:)),
            viewModel.onUndo
                .bind(onNext: undoPressed(flag:))
        )
        
        viewModel.selectedTabKind
            .accept(viewModel.tabKinds.first!)
    }
    
    /// Created for each tab, each of them has a cancel (x) button. May be single collection tab or collection group tab.
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
            if viewModel.selectionMode != .single {
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
    
    func clear() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func undoPressed(flag: Bool) {
        guard viewModel.selectionMode != .single else { return } // no undo if single
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
        checkForDeletedAssetsFromUndoStack()
        allItemViews.forEach { $0.viewModel.reloadCollection() }
    }
    
    
    /// Gets called when user reenters the app and checks for deleted photos/videos.
    func checkForDeletedAssetsFromUndoStack() {
        var allAssets = Set<PHAsset>()
        let selections = viewModel.selectionStack.value
        selections.forEach { allAssets.formUnion($0) }
        let deletedAssets = PHAsset.findMissingAssets(in: Array(allAssets))
        guard !deletedAssets.isEmpty else { return }
        let clearedSelections = selections.map { $0.subtracting(deletedAssets) }
        viewModel.selectionStack.accept(clearedSelections)
    }
    
    
    private func displayOverLimitMessage() {
        guard case .multiple(let max) = viewModel.selectionMode else { return }
        let alert = UIAlertController(title: "Maximum \(max) items", message: "You have selected more items than allowed", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        mainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
