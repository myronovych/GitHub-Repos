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
    case invalidURL, invalidData, unableToPerformRequest, badResponse
}

typealias SearchRepositoriesResponse = Result<(repositories: [Repository], nextURL: URL?), NetworkError>

class GitHubApi {
    static let shared = GitHubApi()
    private init() {}
        
    var nextUrl: String?
    
    func fetchNextPage(completion: @escaping (Result<[Repository],NetworkError>) -> Void) {
        if let nextUrl = nextUrl {
            print("FETCHING NEXT URL: \(nextUrl)")
            fetchRepos(url: nextUrl, completion: completion)
        }
    }
    
    func fetchRepos(url: String, completion: @escaping (Result<[Repository],NetworkError>) -> Void) {
        
        guard let url = URL(string: url) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) {data, response, error in
            if let _ = error {
                completion(.failure(.unableToPerformRequest))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(.failure(.badResponse))
                return
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
                completion(.success(repositories))
            } catch {
                completion(.failure(.invalidData))
            }
        }
        task.resume()
    }
}
