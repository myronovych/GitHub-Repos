//
//  ViewController.swift
//  GitHub-Repos
//
//  Created by rs on 15.10.2020.
//  Copyright © 2020 Oleksandr Myronovych. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var searchField: UITextField!
    @IBOutlet var tableView: UITableView!
    
    var repositories = [Repository]()
    var viewed: Set<Int> {
        get { fetchVisitedIDs() }
        set { saveVisitedIDs(ids: newValue) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        searchField.addTarget(self, action: #selector(ViewController.textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func fetchVisitedIDs() -> Set<Int> {
        let defaults = UserDefaults.standard
        let arr = defaults.object(forKey: "visitedIDs") as? [Int] ?? [Int]()
        return Set(arr)
    }
    
    func saveVisitedIDs(ids: Set<Int>) {
        let defaults = UserDefaults.standard
        print(ids)
        defaults.set(Array(ids), forKey: "visitedIDs")
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let name = textField.text, name != "", name.count > 2 else {
            print("short name")
            repositories = []
            tableView.reloadData()
            return
        }
        
        NetworkService.shared.fetchRepos(name: name) { result in
            switch result {
            case .success(let repositories) :
                self.repositories = repositories
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error occured: \(error)")
            }
        }
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate{
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
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let htmlUrl = repositories[indexPath.row].htmlUrl
        if let url = URL(string: htmlUrl) {
            UIApplication.shared.open(url)
            viewed.insert(repositories[indexPath.row].id)
            tableView.cellForRow(at: indexPath)?.backgroundColor = .gray
        }
    }
}
