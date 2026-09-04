import Foundation

/// What the presign signs. R2 enforces both, so bytes that do not match exactly are a
/// `403 SignatureDoesNotMatch` — `bitelyapi` ADR-0006.
struct PresignRequest: Encodable {
    let contentType: String
    let contentLength: Int

    enum CodingKeys: String, CodingKey {
        case contentType = "content_type"
        case contentLength = "content_length"
    }
}

/// What the API answers a presign request with. `expires_at` is not decoded: the upload
/// follows immediately, and a stale URL is R2's `403` rather than something to pre-empt.
struct PresignedUpload: Decodable {
    let uploadUrl: String
    let key: String

    enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case key
    }
}

/// Sends bytes straight to R2 through a presigned PUT.
///
/// This cannot go through `APIClient`: that hardcodes `baseURL`, forces
/// `Content-Type: application/json`, and would attach the session token to a Cloudflare URL.
/// It shares `HTTPTransport` with it, so a stub records both halves of an upload.
struct PresignedUploader {
    private let transport: HTTPTransport

    init(transport: HTTPTransport = URLSession.shared) {
        self.transport = transport
    }

    func upload(_ image: EncodedRecipeImage, to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(image.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = image.data

        let (data, response) = try await transport.send(request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }
}
