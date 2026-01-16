import Foundation
import Pulse

enum NetworkSessionFactory {
    nonisolated static func makeSession() -> URLSessionProtocol {
#if DEBUG
        return URLSessionProxy(configuration: .default)
#else
        return URLSession(configuration: .default)
#endif
    }
}
