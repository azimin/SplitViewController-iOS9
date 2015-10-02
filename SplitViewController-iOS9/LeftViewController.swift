//
//  LeftViewController.swift
//  SplitViewController-iOS9
//
//  Created by Alex Zimin on 02/10/15.
//  Copyright © 2015 Alexander Zimin. All rights reserved.
//

import UIKit

class LeftViewController: UIViewController { }

// MARK: - Orientation

extension LeftViewController {
  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    print("LeftViewController - \(__FUNCTION__): Size: \(size)")
  }
}

// MARK: - UITableViewDataSource

extension LeftViewController: UITableViewDataSource {
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    cell.textLabel?.text = (indexPath.row == 0) ? "Collection VC" : "Test VC"
    return cell
  }
}

// MARK: - UITableViewDelegate

extension LeftViewController: UITableViewDelegate {
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    
    if indexPath.row == 0 {
      az_splitController?.mainController = (UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Center") as! UINavigationController)
    }
    
    if indexPath.row == 1 {
      az_splitController?.mainController = (UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("AnotherCenter") as! UINavigationController)
    }
    
    az_splitController?.toggleSide()
  }
}
