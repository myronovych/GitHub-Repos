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

typealias SearchRepositoriesResponse = Result<(repositories: [Repository], nextURL: URL?), NetworkError>

class NetworkService {
    static let shared = NetworkService()
    private init() {}
    
    let baseUrl = "https://api.github.com/search/repositories?sort=stars"
    
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
            
            print(response.allHeaderFields)
            
            if let links = response.allHeaderFields["Link"] as? String {
                do {
                    let links = try NetworkService.parseLinks(links)
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
    
    private static let parseLinksPattern = "\\s*,?\\s*<([^\\>]*)>\\s*;\\s*rel=\"([^\"]*)\""
    private static let linksRegex = try! NSRegularExpression(pattern: parseLinksPattern, options: [.allowCommentsAndWhitespace])

    private static func parseLinks(_ links: String) throws -> [String: String] {

        let length = (links as NSString).length
        let matches = NetworkService.linksRegex.matches(in: links, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: length))

        var result: [String: String] = [:]

        for m in matches {
            let matches = (1 ..< m.numberOfRanges).map { rangeIndex -> String in
                let range = m.range(at: rangeIndex)
                let startIndex = links.index(links.startIndex, offsetBy: range.location)
                let endIndex = links.index(links.startIndex, offsetBy: range.location + range.length)
                return String(links[startIndex ..< endIndex])
            }
            if matches.count != 2 {
                throw NetworkError.invalidData
            }
            result[matches[1]] = matches[0]
        }
        
        return result
    }
}
