//
//  Persistence.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import Foundation

final class Persistence {
    static let shared = Persistence()
    private init() {}

    func url(for filename: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(filename)
    }

    func save<T: Codable>(_ value: T, as filename: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url(for: filename), options: [.atomic])
        } catch {
            print("Save error:", error)
        }
    }

    func load<T: Codable>(_ type: T.Type, from filename: String, default fallback: T) -> T {
        do {
            let data = try Data(contentsOf: url(for: filename))
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return fallback
        }
    }
}

