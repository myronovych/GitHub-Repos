//
//  GitHubApi.swift
//  GitHub-Repos
//
//  Created by rs on 15.10.2020.
//  Copyright © 2020 Oleksandr Myronovych. All rights reserved.
//

import Foundation
import Combine

enum NetworkError: Error {
    case invalidURL, invalidData, unableToPerformRequest, badResponse, limitReached
}

typealias SearchRepositoriesResponse = Result<(repositories: [Repository], nextURL: URL?), NetworkError>

class GitHubApi {
    static let shared = GitHubApi()
    private init() {}
        
    var nextUrl: String?
    
    func fetchNextPage(completion: @escaping (Result<RepositoryResult,NetworkError>) -> Void) {
        if let nextUrl = nextUrl {
            print("FETCHING NEXT URL: \(nextUrl)")
            fetchRepos(urlString: nextUrl, completion: completion)
        }
    }
    
    func fetchRepos(urlString: String, completion: @escaping (Result<RepositoryResult,NetworkError>) -> Void) {
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) {data, response, error in
            if let _ = error {
                completion(.failure(.unableToPerformRequest))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(.badResponse))
                return
            }
            
            if response.statusCode != 200 {
                if response.statusCode == 403 {
                    completion(.failure(.limitReached))
                    return
                }
            }
                        
            if let links = response.allHeaderFields["Link"] as? String {
                do {
                    let links = try Parser().parseLinks(links)
                    self.nextUrl = links["next"]
                } catch {
                    print(error)
                }
            } else {
                print("BAD LINKS")
            }
            
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let repositories = try decoder.decode(RepositoryResponse.self, from: data).items
                let repoResult = RepositoryResult(searchQuery: urlString, repositories: repositories)
                completion(.success(repoResult))
            } catch {
                completion(.failure(.invalidData))
            }
        }
        task.resume()
    }
}
