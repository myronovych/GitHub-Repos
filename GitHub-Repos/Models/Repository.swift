//
//  Repository.swift
//  GitHub-Repos
//
//  Created by rs on 15.10.2020.
//  Copyright © 2020 Oleksandr Myronovych. All rights reserved.
//

import Foundation

struct RepositoryResponse: Decodable {
    let items: [Repository]
}

struct RepositoryResult {
    let searchQuery: String
    let repositories: [Repository]
}

struct Repository: Decodable {
    let id: Int
    let fullName: String
    let stargazersCount: Int
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case stargazersCount = "stargazers_count"
        case htmlUrl = "html_url"
    }
}

