//
//  SearchEngines.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import Foundation

enum SearchEngine: String, CaseIterable {
    case google
    case yahoo
    case bing
    case brave
    case duckDuckGo
    case ecosia
    case startpage
    case custom
    case bingChina
    case duckDuckGoLite
    case duckDuckGoHTML

    // Keep old raw values decodable; only these four are offered in the UI.
    static let pickerEngines: [SearchEngine] = [.duckDuckGo, .duckDuckGoLite, .duckDuckGoHTML]
    
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .yahoo:
            return "Yahoo"
        case .bing:
            return "Bing"
        case .brave:
            return "Brave"
        case .duckDuckGo:
            return "DuckDuckGo"
        case .ecosia:
            return "Ecosia"
        case .startpage:
            return "Startpage"
        case .custom:
            return NSLocalizedString("Custom", comment: "Search engine option")
        case .bingChina:
            return "cn.bing.com"
        case .duckDuckGoLite:
            return "DuckDuckGo (Lite)"
        case .duckDuckGoHTML:
            return "DuckDuckGo (HTML)"
        }
    }
    
    private static let navigationExpression = try! NSRegularExpression(
        pattern: "^\\s*(\\w+-+)*[\\w\\[]+(://[/]*|:|\\.)(\\w+-+)*[\\w\\[:]+([\\S&&[^\\w-]]\\S*)?\\s*$"
    )

    static func isDirectNavigationInput(_ input: String) -> Bool {
        navigationExpression.firstMatch(in: input, range: NSRange(location: 0, length: (input as NSString).length)) != nil
    }

    static func destination(for query: String, engine: SearchEngine? = nil) -> String {
        // Encode a query VALUE, not an entire URL (otherwise & and # change it).
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+#?")
        let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let template: String
        template = queryTemplate(for: engine ?? Prefs.SearchSettings.searchEngine)
        return template.replacingOccurrences(of: "%s", with: escapedQuery)
    }

    var iconAssetName: String {
        switch self {
        case .google: return "google.com"
        case .duckDuckGoLite, .duckDuckGoHTML: return "FennecSearch-duckDuckGo"
        case .bingChina: return "FennecSearch-bing"
        default: return "FennecSearch-\(rawValue)"
        }
    }
    
    static func canSearch(using customQueryTemplate: String) -> Bool {
        let normalizedTemplate = customQueryTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedTemplate.contains("%s") else {
            return false
        }
        
        let exampleDestination = normalizedTemplate.replacingOccurrences(of: "%s", with: "reynard")
        return URLUtils.normalizedCustomURL(from: exampleDestination) != nil
    }
    
    private var queryTemplate: String? {
        switch self {
        case .google:
            return "https://www.google.com/search?q=%s"
        case .yahoo:
            return "https://search.yahoo.com/search?p=%s"
        case .bing:
            return "https://www.bing.com/search?q=%s"
        case .brave:
            return "https://search.brave.com/search?q=%s"
        case .duckDuckGo:
            return "https://duckduckgo.com/?q=%s"
        case .ecosia:
            return "https://www.ecosia.org/search?q=%s"
        case .startpage:
            return "https://www.startpage.com/sp/search?query=%s"
        case .bingChina:
            return "https://cn.bing.com/search?q=%s"
        case .duckDuckGoLite:
            return "https://lite.duckduckgo.com/lite/?q=%s"
        case .duckDuckGoHTML:
            return "https://html.duckduckgo.com/html/?q=%s"
        case .custom:
            return nil
        }
    }
    
    private static func queryTemplate(for engine: SearchEngine) -> String {
        switch engine {
        case .custom:
            let customQueryTemplate = Prefs.SearchSettings.customSearchTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard canSearch(using: customQueryTemplate) else {
                return SearchEngine.google.queryTemplate!
            }
            
            let exampleDestination = customQueryTemplate.replacingOccurrences(of: "%s", with: "reynard")
            return URLUtils.isWebURL(exampleDestination) ? customQueryTemplate : "https://\(customQueryTemplate)"
        case let engine:
            return engine.queryTemplate ?? SearchEngine.google.queryTemplate!
        }
    }
}
