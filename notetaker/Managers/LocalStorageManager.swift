// LocalStorageManager.swift
// Handles local storage of meetings and app data

import Foundation

/// Manages local file storage for meetings and app data
class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let documentsDirectory: URL
    private let meetingsDirectory: URL
    
    private init() {
        // Get the app's documents directory
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                    in: .userDomainMask).first!
        
        // Create meetings subdirectory
        meetingsDirectory = documentsDirectory.appendingPathComponent("Meetings")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: meetingsDirectory,
                                               withIntermediateDirectories: true)
    }
    
    // MARK: - Meeting Management
    
    /// Saves a meeting to local storage
    /// - Parameter meeting: The meeting to save
    /// - Returns: True if successful, false otherwise
    func saveMeeting(_ meeting: Meeting) -> Bool {
        let fileURL = meetingsDirectory.appendingPathComponent("\(meeting.id.uuidString).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(meeting)
            try data.write(to: fileURL)
            
            print("✅ Saved meeting: \(meeting.id)")
            return true
        } catch {
            print("❌ Failed to save meeting: \(error)")
            return false
        }
    }
    
    /// Loads all meetings from local storage
    /// - Returns: Array of meetings, sorted by date (newest first)
    func loadMeetings() -> [Meeting] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: meetingsDirectory,
                                                                      includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let meetings = fileURLs.compactMap { url -> Meeting? in
                guard let data = try? Data(contentsOf: url),
                      let meeting = try? decoder.decode(Meeting.self, from: data) else {
                    print("⚠️ Failed to decode meeting at: \(url)")
                    return nil
                }
                return meeting
            }
            
            return meetings.sorted { $0.date > $1.date }
        } catch {
            print("❌ Failed to load meetings: \(error)")
            return []
        }
    }
    
    /// Deletes a meeting from local storage
    /// - Parameter meeting: The meeting to delete
    /// - Returns: True if successful, false otherwise
    func deleteMeeting(_ meeting: Meeting) -> Bool {
        let fileURL = meetingsDirectory.appendingPathComponent("\(meeting.id.uuidString).json")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ Deleted meeting: \(meeting.id)")
            return true
        } catch {
            print("❌ Failed to delete meeting: \(error)")
            return false
        }
    }
    
    // MARK: - Settings Management
    
    /// Saves non-sensitive settings to local storage
    /// - Parameter settings: The settings to save (sensitive data should use Keychain)
    func saveSettings(_ settings: Settings) -> Bool {
        // For now, all settings are stored in Keychain
        // This method is here for future non-sensitive settings
        return true
    }
    
    /// Gets the app's documents directory URL
    var documentsDirectoryURL: URL {
        documentsDirectory
    }
    
    /// Gets the meetings directory URL
    var meetingsDirectoryURL: URL {
        meetingsDirectory
    }
} 