//
//  MenuTableViewController.swift
//  PKCanvasViewTester
//
//  Created by Kaz Yoshikawa on 5/9/20.
//  Copyright © 2020 Kaz Yoshikawa. All rights reserved.
//

import UIKit


class MenuTableViewController: UITableViewController {

	enum TestCase: CaseIterable {
		case contentViewAsCanvus
		var title: String {
			switch self {
			case .contentViewAsCanvus: return "Content View (UIView) as Subview of PKCanvasView."
			}
		}
		var storyboardName: String {
			switch self {
			case .contentViewAsCanvus: return "Canvas1"
			}
		}
	}

	static let cellKey = "cell"

	override func viewDidLoad() {
		super.viewDidLoad()
		self.clearsSelectionOnViewWillAppear = false
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellKey)
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return TestCase.allCases.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellKey, for: indexPath)
		let testCase = TestCase.allCases[indexPath.row]
		cell.textLabel?.text = testCase.title
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let testCase = TestCase.allCases[indexPath.row]
		let storyboard = UIStoryboard(name: testCase.storyboardName, bundle: nil)
		let viewController = storyboard.instantiateInitialViewController()!
		self.navigationController?.pushViewController(viewController, animated: true)
	}

}

