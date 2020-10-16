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
        
        cell.textLabel?.text = repo.fullName
        cell.detailTextLabel?.text = String(repo.stargazersCount)
        cell.selectionStyle = .none
        
        if viewed.contains(repo.id) {
            cell.backgroundColor = .gray
        } else {
            cell.backgroundColor = .white
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
            tableView.cellForRow(at: indexPath)?.backgroundColor = .gray
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
                    print("Error occured: \(error)")
                }
            }
        }
    }
}
