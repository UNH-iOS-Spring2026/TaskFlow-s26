//
//  Persistence.swift
//  Task_Flow
import Foundation

// Handles simple local file storage for Codable data.
final class Persistence {
    static let shared = Persistence()

    private init() {}

    // MARK: - File URL

    // Creates the file path inside the app's Documents directory.
    func url(for filename: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(filename)
    }

    // MARK: - Save Data

    // Saves any Codable value as JSON data to the given file name.
    func save<T: Codable>(_ value: T, as filename: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url(for: filename), options: [.atomic])
        } catch {
            print("Save error:", error)
        }
    }

    // MARK: - Load Data

    // Loads Codable data from a file and returns fallback data if loading fails.
    func load<T: Codable>(_ type: T.Type, from filename: String, default fallback: T) -> T {
        do {
            let data = try Data(contentsOf: url(for: filename))
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return fallback
        }
    }
}
