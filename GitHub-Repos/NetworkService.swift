//
//  NetworkService.swift
//  GitHub-Repos
//
//  Created by rs on 15.10.2020.
//  Copyright © 2020 Oleksandr Myronovych. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case invalidURL, invalidData, unableToPerformRequest, badResponse
}

class NetworkService {
    static let shared = NetworkService()
    private init() {}
    
    let baseUrl = "https://api.github.com/search/repositories?sort=stars"
    
    func fetchRepos(name: String, completion: @escaping (Result<[Repository],NetworkError>) -> Void) {
        let endpoint = baseUrl + "&q=\(name)+in%3Aname"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) {data, response, error in
            if let _ = error {
                completion(.failure(.unableToPerformRequest))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(.failure(.badResponse))
                return
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
