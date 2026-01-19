import Foundation
import UIKit

actor ImageUploadService {
    static let shared = ImageUploadService()

    private let defaultContentType = "image/jpeg"
    private let defaultFileName = "cover.jpg"
    private let maxUploadBytes = 10 * 1024 * 1024

    func uploadCoverPhoto(_ image: UIImage, accessToken: String) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw ImageUploadError.invalidImageData
        }

        if imageData.count > maxUploadBytes {
            throw ImageUploadError.imageTooLarge(maxBytes: maxUploadBytes)
        }

        let request = RecipeImageUploadRequest(
            contentType: defaultContentType,
            fileName: defaultFileName,
            fileSizeBytes: imageData.count
        )
        let response: RecipeImageUploadResponse = try await APIService.shared.postAuthenticated(
            path: "/uploads/recipe-images",
            body: request,
            accessToken: accessToken
        )

        if imageData.count > response.maxSizeBytes {
            throw ImageUploadError.imageTooLarge(maxBytes: response.maxSizeBytes)
        }

        var uploadRequest = URLRequest(url: response.uploadUrl)
        uploadRequest.httpMethod = response.method
        response.headers.forEach { key, value in
            uploadRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (_, uploadResponse) = try await URLSession.shared.upload(for: uploadRequest, from: imageData)
        guard let httpResponse = uploadResponse as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ImageUploadError.uploadFailed(statusCode: httpResponse.statusCode)
        }

        return response.publicUrl
    }
}

enum ImageUploadError: LocalizedError {
    case invalidImageData
    case imageTooLarge(maxBytes: Int)
    case invalidResponse
    case uploadFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The cover photo couldn't be processed."
        case .imageTooLarge(let maxBytes):
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return "The selected image exceeds the \(formatter.string(fromByteCount: Int64(maxBytes))) upload limit."
        case .invalidResponse:
            return "The upload service returned an invalid response."
        case .uploadFailed(let statusCode):
            return "The upload failed with status code \(statusCode)."
        }
    }
}
