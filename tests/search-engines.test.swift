// Real engine formatting and URL classification. Only profile prefs are doubled.
import Foundation

enum Prefs {
    enum SearchSettings {
        static var searchEngine: SearchEngine = .google
        static var customSearchTemplate = ""
    }
}

@main struct SearchEngineTests {
    static func main() {
        precondition(SearchEngine.pickerEngines == [.duckDuckGo, .duckDuckGoLite, .duckDuckGoHTML])
        precondition(SearchEngine.destination(for: "cn", engine: .bingChina) == "https://cn.bing.com/search?q=cn")
        precondition(SearchEngine.destination(for: "cn", engine: .duckDuckGoLite) == "https://lite.duckduckgo.com/lite/?q=cn")
        precondition(SearchEngine.destination(for: "cn", engine: .duckDuckGoHTML) == "https://html.duckduckgo.com/html/?q=cn")
        for engine in SearchEngine.allCases where engine != .custom {
            let destination = SearchEngine.destination(for: "cn & 汉字+#?=", engine: engine)
            let components = URLComponents(string: destination)!
            precondition(components.scheme == "https")
            precondition(components.fragment == nil)
            let values = components.queryItems!.map { $0.value ?? "" }
            precondition(values.contains("cn & 汉字+#?="), "Query must be encoded as a value: \(destination)")
            precondition(Prefs.SearchSettings.searchEngine == .google, "One-off search must preserve defaults")
        }
        Prefs.SearchSettings.customSearchTemplate = "https://example.invalid/find?q=%s"
        precondition(SearchEngine.destination(for: "cn", engine: .custom) == "https://example.invalid/find?q=cn")
        Prefs.SearchSettings.customSearchTemplate = "broken"
        precondition(SearchEngine.destination(for: "cn", engine: .custom).hasPrefix("https://www.google.com/"))
        for input in ["https://example.com", "example.com", "localhost:8080", "about:blank"] {
            precondition(SearchEngine.isDirectNavigationInput(input), input)
        }
        for input in ["cn", "hello world", "汉字 搜索"] {
            precondition(!SearchEngine.isDirectNavigationInput(input), input)
        }
        print("PASS: actual SearchEngine/URLUtils, provider overrides, custom validation, URL classification and reserved/Unicode query values; prefs doubled")
    }
}
