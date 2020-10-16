//
//  SearchVC.swift
//  GitHub-Repos
//
//  Created by rs on 15.10.2020.
//  Copyright © 2020 Oleksandr Myronovych. All rights reserved.
//

import UIKit

class SearchVC: UIViewController {
    @IBOutlet var searchField: UITextField!
    @IBOutlet var tableView: UITableView!
    
    var currentDataSource: SearchDataSourceDelegate? {
        didSet {
            self.tableView.dataSource = currentDataSource
            self.tableView.delegate = currentDataSource
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.currentDataSource = SearchDataSourceDelegate()
        
        searchField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let name = textField.text, name != "", name.count > 2 else {
            print("short name")
            currentDataSource?.repositories = []
            tableView.reloadData()
            return
        }
        
        GitHubApi.shared.fetchRepos(url: URLs.baseUrl + "&q=\(name)+in%3Aname") { [weak self] result in
            switch result {
            case .success(let repositories) :
                self?.currentDataSource?.repositories = repositories
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("Error occured: \(error)")
            }
        }
    }
    
}
