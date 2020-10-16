//
//  SearchDataSource.swift
//  GitHub-Repos
//
//  Created by rs on 16.10.2020.
//  Copyright © 2020 Oleksandr Myronovych. All rights reserved.
//

import Foundation
import UIKit

class SearchDataSourceDelegate: NSObject, UITableViewDataSource {
    weak var vc: SearchVC?
    
    var repositories = [Repository]()
    var viewed: Set<Int> {
        get { fetchVisitedIDs() }
        set { saveVisitedIDs(ids: newValue) }
    }
    
    func fetchVisitedIDs() -> Set<Int> {
        let defaults = UserDefaults.standard
        let arr = defaults.object(forKey: "visitedIDs") as? [Int] ?? [Int]()
        return Set(arr)
    }
    
    func saveVisitedIDs(ids: Set<Int>) {
        let defaults = UserDefaults.standard
        defaults.set(Array(ids), forKey: "visitedIDs")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepoCell", for: indexPath)
        let repo = repositories[indexPath.row]
        
        cell.detailTextLabel?.text = "⭐️ \(repo.stargazersCount)"
        cell.selectionStyle = .none
        
        if viewed.contains(repo.id) {
            cell.textLabel?.text = "🔴 \(repo.fullName)"
        } else {
            cell.textLabel?.text = "🟢 \(repo.fullName)"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }
}

extension SearchDataSourceDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let htmlUrl = repositories[indexPath.row].htmlUrl
        if let url = URL(string: htmlUrl) {
            UIApplication.shared.open(url)
            viewed.insert(repositories[indexPath.row].id)
            let repo = repositories[indexPath.row]
            tableView.cellForRow(at: indexPath)?.textLabel?.text = "🔴 \(repo.fullName)"
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == repositories.count {
            GitHubApi.shared.fetchNextPage { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let repositories) :
                    self.repositories += repositories
                    DispatchQueue.main.async {
                        tableView.reloadData()
                    }
                case .failure(let error):
                    if error == .limitReached {
                        DispatchQueue.main.async {
                            self.vc?.showLimitAlert()
                        }
                    }
                    print("Error occured: \(error)")
                }
            }
        }
    }
}
