import Foundation

nonisolated struct RecipeImageUploadRequest: Encodable, Sendable {
    let contentType: String
    let fileName: String
    let fileSizeBytes: Int

    private enum CodingKeys: String, CodingKey {
        case contentType = "content_type"
        case fileName = "file_name"
        case fileSizeBytes = "file_size_bytes"
    }
}

nonisolated struct RecipeImageUploadResponse: Decodable, Sendable {
    let uploadUrl: URL
    let token: String?
    let path: String
    let publicUrl: URL
    let method: String
    let headers: [String: String]
    let maxSizeBytes: Int
}
