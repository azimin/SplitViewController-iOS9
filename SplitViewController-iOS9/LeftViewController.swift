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
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    print("LeftViewController - \(#function): Size: \(size)")
  }
}

// MARK: - UITableViewDataSource

extension LeftViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    cell.textLabel?.text = (indexPath.row == 0) ? "Collection VC" : "Test VC"
    return cell
  }
}

// MARK: - UITableViewDelegate

extension LeftViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if indexPath.row == 0 {
      az_splitController?.mainController = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Center") as! UINavigationController)
    }
    
    if indexPath.row == 1 {
      az_splitController?.mainController = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AnotherCenter") as! UINavigationController)
    }
    
    az_splitController?.toggleSide()
  }
}
