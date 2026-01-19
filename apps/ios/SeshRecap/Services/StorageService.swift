import Foundation
import Supabase

class StorageService {
    static let shared = StorageService()

    private let bucketName = "audio-files"

    private init() {}

    // MARK: - Upload

    func uploadAudio(data: Data, path: String) async throws -> String {
        let storage = SupabaseClient.shared.storage(bucketName)

        try await storage.upload(
            path: path,
            file: data,
            options: FileOptions(
                contentType: "audio/mp4",
                upsert: true
            )
        )

        return path
    }

    func uploadAudio(fileURL: URL, path: String) async throws -> String {
        let data = try Data(contentsOf: fileURL)
        return try await uploadAudio(data: data, path: path)
    }

    // MARK: - Download

    func getDownloadURL(path: String) async throws -> URL {
        let storage = SupabaseClient.shared.storage(bucketName)

        let signedURL = try await storage.createSignedURL(
            path: path,
            expiresIn: 3600 // 1 hour
        )

        return signedURL
    }

    func downloadAudio(path: String) async throws -> Data {
        let storage = SupabaseClient.shared.storage(bucketName)
        return try await storage.download(path: path)
    }

    // MARK: - Delete

    func deleteAudio(paths: [String]) async throws {
        let storage = SupabaseClient.shared.storage(bucketName)
        try await storage.remove(paths: paths)
    }

    // MARK: - List

    func listFiles(folder: String) async throws -> [FileObject] {
        let storage = SupabaseClient.shared.storage(bucketName)
        return try await storage.list(path: folder)
    }
}
