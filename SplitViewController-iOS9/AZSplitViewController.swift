//
//  AZSplitViewController.swift
//  FeedCollectionView
//
//  Created by Alex Zimin on 15/07/15.
//  Copyright (c) 2015 Alex Zimin. All rights reserved.
//

import UIKit

let AZSideWidth: CGFloat = 320
let AZMinimalWidth: CGFloat = 320

enum AZSplitControllerStateRules {

  typealias StateRule = (_ traitCollection: UITraitCollection, _ viewSize: CGSize, _ sideWidth: CGFloat) -> (Bool)

  case `default`
  case widthBase
  case onlyPad
  case custom(StateRule)

  func stateValue(_ traitCollection: UITraitCollection, viewSize: CGSize, sideWidth: CGFloat) -> Bool {
    switch self {
    case .default:
      return traitCollection.horizontalSizeClass == .regular && viewSize.width >= sideWidth * 2
    case .widthBase:
      return viewSize.width >= sideWidth + AZMinimalWidth
    case .onlyPad:
      return traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular && viewSize.width > sideWidth
    case let .custom(rule):
      return rule(traitCollection, viewSize, sideWidth)
    }
  }
}

class AZSplitController: UIViewController {
  
  // MARK: - View Controllers
  
  var sideController: UINavigationController! {
    willSet {
      removeChildViewController(sideController)
    }
    didSet {
      setupSideController(sideController)
    }
  }
  
  var mainController: UINavigationController! {
    willSet {
      removeChildViewController(mainController)
    }
    didSet {
      setupMainController(mainController)
    }
  }
  
  fileprivate var sideControllerSize: CGSize = .zero
  fileprivate var mainControllerSize: CGSize = .zero
  
  var templateViewController: UIViewController!
  
  // MARK: - Separator
  
  var separatorViewColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
    didSet {
      separatorView.backgroundColor = separatorViewColor
    }
  }
  fileprivate var separatorView: UIView!
  
  // MARK: - Indents
  
  fileprivate var sideCurrentWidth: CGFloat {
    return isSideOpen ? sideWidth : 0
  }
  
  fileprivate var sideIndent: CGFloat {
    return sideCurrentWidth - sideWidth
  }
  
  // MARK: - Setup
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    recalculateState(view.bounds.size)
  }
  
  // MARK: - States
  
  var rules: AZSplitControllerStateRules = .widthBase
  var animationDuration: TimeInterval = 0.2
  
  fileprivate(set) var isSideOpen: Bool = false
  fileprivate(set) var sideWidth: CGFloat = AZSideWidth
  
  fileprivate var isControllerContainsSideMenu: Bool = false
  
  // return yes if need to to cahnge
  func recalculateState(_ size: CGSize) -> Bool {
    let traitCollection = newCollection ?? self.traitCollection
    
    let newState = rules.stateValue(traitCollection, viewSize: size, sideWidth: sideWidth)
    
    if newState != isControllerContainsSideMenu {
      isControllerContainsSideMenu = newState
      return true
    }
    
    return false
  }
  
  // MARK: - UIContentContainer
  
  fileprivate weak var newCollection: UITraitCollection?
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    self.newCollection = newCollection
    super.willTransition(to: newCollection, with: coordinator)
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    if recalculateState(size) {
      changeState(size, withTransitionCoordinator: coordinator)
      return
    }
    
    var rect = self.mainController.view.frame
    rect.size.width = size.width - (isControllerContainsSideMenu ? sideCurrentWidth : 0)
    rect.size.height = size.height
    
    
    if isControllerContainsSideMenu {
      var sideRect = self.sideController.view.frame
      sideRect.size.height = size.height
      
      mainControllerSize = rect.size
      sideControllerSize = sideRect.size
    } else {
      rect.origin.x = 0
      sideControllerSize = rect.size
    }
    
    super.viewWillTransition(to: size, with: coordinator)
    
    animation({ () -> () in
      if self.isControllerContainsSideMenu {
        self.sideController.view.frame.size.height = size.height
        self.mainController?.view.frame
      } else {
        self.sideController.view.frame = rect
      }
      }, withTransitionCoordinator: coordinator)
  }
  
  override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
    if container.isEqual(sideController) {
      return sideControllerSize
    }
    
    if container.isEqual(mainController) {
      return mainControllerSize
    }
    
    return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
  }
  
  // MARK: - State changing
  
  var cachedViewControllers: [UIViewController] = []
  
  fileprivate func changeState(_ size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    
    isSideOpen = false
    
    if isControllerContainsSideMenu {
      var controllers = [UIViewController]()
      for controller in self.sideController.viewControllers {
        controllers.append(controller)
      }
      controllers.remove(at: 0)
      
      sideController.popToRootViewController(animated: false)
      
      mainController = UINavigationController()
      mainController.viewControllers = controllers.count > 0 ? controllers : [templateViewController]
      mainController.az_addMenuButton()
      
      let sideRect = CGRect(x: 0, y: 0, width: sideWidth, height: size.height)
      let mainRect = CGRect(x: sideCurrentWidth, y: 0, width: size.width - sideCurrentWidth, height: size.height)
      
      mainControllerSize = mainRect.size
      sideControllerSize = sideRect.size
      
      super.viewWillTransition(to: size, with: coordinator)
      
      animation({ () -> () in
        self.sideController.view.frame = sideRect
        self.addSeparator(size)
        }, withTransitionCoordinator: coordinator)
      
      
    } else {
      var controllers = [UIViewController]()
      for controller in self.mainController.viewControllers {
        controllers.append(controller)
      }
      controllers.first?.navigationItem.leftBarButtonItem = nil
      
      mainController.popToRootViewController(animated: false)
      mainController.view.removeFromSuperview()
      
      sideControllerSize = bounds.size
      mainControllerSize = .zero
      
      super.viewWillTransition(to: size, with: coordinator)
      
      sideController.viewControllers = [self.sideController.viewControllers.first!] + controllers
      
      animation({ () -> () in
        self.sideController.view.frame = bounds
        }, withTransitionCoordinator: coordinator)
      
      removeSeparator()
    }
  }
  
  fileprivate func setupMainController(_ controller: UINavigationController?) {
    guard let controller = controller else {
      return
    }
    
    self.addChildViewController(controller)
    controller.didMove(toParentViewController: self)
    
    if !isControllerContainsSideMenu {
      self.isSideOpen = true
      return
    }
    
    positionMainController()
    controller.az_addMenuButton()
  }
  
  func positionMainController() {
    var mainFrame = self.view.bounds
    mainFrame.origin.x = sideCurrentWidth
    mainFrame.size.width -= sideCurrentWidth
    
    mainController.view.frame = mainFrame
    mainControllerSize = mainFrame.size
    
    self.view.addSubview(mainController.view)
  }
  
  fileprivate func setupSideController(_ controller: UINavigationController?) {
    guard let controller = controller else {
      return
    }
    
    self.addChildViewController(controller)
    controller.didMove(toParentViewController: self)
    
    controller.view.frame = self.isControllerContainsSideMenu ? CGRect(x: sideIndent, y: 0, width: sideWidth, height: self.view.bounds.size.height) : self.view.bounds
    controller.view.autoresizingMask = UIViewAutoresizing()
    sideControllerSize = controller.view.bounds.size
    
    self.view.addSubview(controller.view)
    
    if !isControllerContainsSideMenu {
      self.isSideOpen = true
      return
    }
    
    addSeparator()
  }
  
  // MARK: - Separator actions
  
  fileprivate func addSeparator() {
    addSeparator(self.view.bounds.size)
  }
  
  fileprivate func addSeparator(_ size: CGSize) {
    removeSeparator()
    separatorView = UIView(frame: CGRect(x: sideWidth - 1, y: 0, width: 1, height: size.height))
    separatorView.autoresizingMask = .flexibleHeight
    separatorView.backgroundColor = separatorViewColor
    sideController.topViewController?.view.addSubview(separatorView)
  }
  
  fileprivate func removeSeparator() {
    separatorView?.removeFromSuperview()
  }
  
  // MARK: - State change
  
  func toggleSide() {
    isSideOpen ? closeSide() : openSide()
  }
  
  func openSide() {
    if !isControllerContainsSideMenu {
      assertionFailure("Wrong state: you can't open side menu in not full state")
      return
    }
    
    if isSideOpen {
      assertionFailure("Wrong state: side already opened")
      return
    }
    
    isSideOpen = true
    
    UIView.animate(withDuration: animationDuration, animations: {
      var sideFrame = self.sideController.view.frame
      sideFrame.origin.x = 0
      self.sideController.view.frame = sideFrame
      self.sideController.view.layoutIfNeeded()
      
      var mainFrame = self.mainController.view.frame
      mainFrame.origin.x = self.sideWidth
      mainFrame.size.width -= self.sideWidth
      self.mainController.view.frame = mainFrame;
      self.mainController.view.layoutIfNeeded()
      })
  }
  
  func closeSide() {
    if !isSideOpen {
      assertionFailure("Wrong state: side already closed")
      return
    }
    
    isSideOpen = false
    
    if !isControllerContainsSideMenu {
      sideController.pushViewController(mainController.topViewController!, animated: true)
      return;
    }
    
    UIView.animate(withDuration: animationDuration, animations: {
      var sideFrame = self.sideController.view.frame;
      sideFrame.origin.x = -self.sideWidth;
      self.sideController.view.frame = sideFrame;
      self.sideController.view.layoutIfNeeded()
      
      var mainFrame = self.mainController.view.frame;
      mainFrame.origin.x = 0
      mainFrame.size.width += self.sideWidth
      self.mainController.view.frame = mainFrame
      self.mainController.view.layoutIfNeeded()
      })
  }
  
  // MARK: - Helpers
  
  fileprivate func removeChildViewController(_ viewController: UIViewController?) {
    if let viewController = viewController {
      viewController.willMove(toParentViewController: nil)
      viewController.view.removeFromSuperview()
      viewController.removeFromParentViewController()
    }
  }
  
  fileprivate func animation(_ animation: @escaping () ->(), withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: { context in
      animation()
      }, completion: nil)
  }
}

// MARK: - UIViewController Helpers

extension UIViewController {
  var az_splitController: AZSplitController? {
    var controller = self.parent
    
    while controller != nil {
      if let az_Controller = controller as? AZSplitController {
        return az_Controller
      }
      controller = controller?.parent
    }
    
    return nil
  }
}

extension UINavigationController {
  func az_addMenuButton() {
    if let topItem = viewControllers.first?.navigationItem {
      topItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self.az_splitController, action: #selector(AZSplitController.toggleSide))
    }
  }
  
  func az_removeMenuButton() {
    if let topItem = viewControllers.first?.navigationItem {
      topItem.leftBarButtonItem = nil
    }
  }
}

