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
        currentDataSource?.vc = self
        searchField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func showLimitAlert() {
        let ac = UIAlertController(title: "Limit reached", message: "API Rate Limit Exceeded. You need to wait.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let name = textField.text, name != "", name.count > 2 else {
            print("short name")
            currentDataSource?.repositories = []
            tableView.reloadData()
            return
        }
        
        GitHubApi.shared.fetchRepos(urlString: URLs.baseUrl + "&q=\(name)+in%3Aname") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let repoResult) :
                DispatchQueue.main.async {
                    guard repoResult.searchQuery == URLs.baseUrl+"&q=\(textField.text ?? "" )+in%3Aname" else { return }
                    self.currentDataSource?.repositories = repoResult.repositories
                    self.tableView.reloadData()
                }
            case .failure(let error):
                if error == .limitReached {
                    DispatchQueue.main.async {
                        self.showLimitAlert()
                    }
                }
                print("Error occured: \(error)")
            }
        }
    }
    
}
