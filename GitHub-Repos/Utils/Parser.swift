//
//  Parser.swift
//  GitHub-Repos
//
//  Created by rs on 16.10.2020.
//  Copyright © 2020 Oleksandr Myronovych. All rights reserved.
//

import Foundation

class Parser {
    private static let parseLinksPattern = "\\s*,?\\s*<([^\\>]*)>\\s*;\\s*rel=\"([^\"]*)\""
    private static let linksRegex = try! NSRegularExpression(pattern: parseLinksPattern, options: [.allowCommentsAndWhitespace])
    
    func parseLinks(_ links: String) throws -> [String: String] {
        
        let length = (links as NSString).length
        let matches = Parser.linksRegex.matches(in: links, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: length))
        
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
