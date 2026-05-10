import Foundation

// MARK: - Provider Status

enum ProviderStatus {
    case idle, checking, success, failed

    var label: String {
        switch self {
        case .idle:     return "Waiting..."
        case .checking: return "Checking..."
        case .success:  return "Working"
        case .failed:   return "Not available"
        }
    }

    var color: String {
        switch self {
        case .idle:     return "gray"
        case .checking: return "orange"
        case .success:  return "green"
        case .failed:   return "red"
        }
    }
}

// MARK: - Provider Model

struct EmbedProvider: Identifiable {
    let id = UUID()
    let name: String
    let embedURL: (String) -> String
    var status: ProviderStatus = .idle

    var currentURL: String = ""

    static func all() -> [EmbedProvider] {
        [
            EmbedProvider(name: "VidSrc.to",   embedURL: { "https://vidsrc.to/embed/movie/\($0)" }),
            EmbedProvider(name: "VidSrc.me",   embedURL: { "https://vidsrc.me/embed/movie?tmdb=\($0)" }),
            EmbedProvider(name: "2embed",      embedURL: { "https://www.2embed.cc/embed/\($0)" }),
            EmbedProvider(name: "SuperEmbed",  embedURL: { "https://multiembed.mov/?video_id=\($0)&tmdb=1" }),
        ]
    }
}

// MARK: - Checker ViewModel

@MainActor
class EmbedCheckerViewModel: ObservableObject {

    @Published var providers: [EmbedProvider] = EmbedProvider.all()
    @Published var activeURL: URL? = nil
    @Published var activeProviderName: String = ""
    @Published var isChecking: Bool = false
    @Published var noneFound: Bool = false

    private var firstLoaded = false

    func checkAll(tmdbID: String) async {
        guard !tmdbID.isEmpty else { return }

        isChecking = true
        firstLoaded = false
        noneFound = false
        activeURL = nil
        activeProviderName = ""

        // Reset all providers
        for i in providers.indices {
            providers[i].status = .idle
            providers[i].currentURL = providers[i].embedURL(tmdbID)
        }

        for i in providers.indices {
            providers[i].status = .checking

            let url = providers[i].embedURL(tmdbID)
            let reachable = await isReachable(urlString: url)

            providers[i].status = reachable ? .success : .failed

            if reachable && !firstLoaded {
                firstLoaded = true
                activeURL = URL(string: url)
                activeProviderName = providers[i].name
            }
        }

        if !firstLoaded {
            noneFound = true
        }

        isChecking = false
    }

    func loadProvider(at index: Int) {
        let url = providers[index].currentURL
        if let validURL = URL(string: url) {
            activeURL = validURL
            activeProviderName = providers[index].name
        }
    }

    private func isReachable(urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 6

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                return (200...399).contains(http.statusCode)
            }
            return true
        } catch {
            // Try GET as fallback
            request.httpMethod = "GET"
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse {
                    return (200...399).contains(http.statusCode)
                }
                return true
            } catch {
                return false
            }
        }
    }
}
