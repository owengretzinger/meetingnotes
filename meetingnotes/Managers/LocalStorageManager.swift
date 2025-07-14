// LocalStorageManager.swift
// Handles local storage of meetings and app data

import Foundation

/// Manages local file storage for meetings and app data
class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let documentsDirectory: URL
    private let meetingsDirectory: URL
    private let templatesDirectory: URL
    
    private init() {
        // Get the app's documents directory
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                    in: .userDomainMask).first!
        
        // Create meetings subdirectory
        meetingsDirectory = documentsDirectory.appendingPathComponent("Meetings")
        
        // Create templates subdirectory
        templatesDirectory = documentsDirectory.appendingPathComponent("Templates")
        
        // Ensure directories exist
        try? FileManager.default.createDirectory(at: meetingsDirectory,
                                               withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: templatesDirectory,
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
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(meeting)

            // Write atomically using a temp file then replace
            let tmpURL = fileURL.appendingPathExtension("tmp")
            try data.write(to: tmpURL, options: .atomic)
            try FileManager.default.replaceItem(at: fileURL, withItemAt: tmpURL, backupItemName: nil, options: [], resultingItemURL: nil)

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
            
            var didCreateBackup = false
            
            let meetings = fileURLs.compactMap { url -> Meeting? in
                guard let data = try? Data(contentsOf: url),
                      let meeting = try? decoder.decode(Meeting.self, from: data) else {
                    print("⚠️ Failed to decode meeting at: \(url)")
                    return nil
                }
                // Forward-compatibility guard – skip if file was written by a newer build
                if meeting.dataVersion > Meeting.currentDataVersion {
                    print("🚫 Meeting \(meeting.id) written by newer app version (\(meeting.dataVersion)). Skipping load.")
                    return nil
                }

                // Check if migration is needed
                if meeting.dataVersion < Meeting.currentDataVersion {
                    // Create backup **once** before we start mutating anything
                    if !didCreateBackup {
                        _ = DataMigrationManager.shared.backupMeetingsDirectory()
                        didCreateBackup = true
                    }

                    if let migratedMeeting = DataMigrationManager.shared.migrateMeeting(meeting) {
                        if saveMeeting(migratedMeeting) {
                            print("✅ Migrated and saved meeting: \(migratedMeeting.id)")
                            return migratedMeeting
                        }
                        print("❌ Failed to save migrated meeting: \(migratedMeeting.id)")
                    } else {
                        print("❌ Failed to migrate meeting: \(meeting.id)")
                    }
                    // Return original if anything failed
                    return meeting
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
    
    // MARK: - Template Management
    
    /// Saves a note template to local storage
    /// - Parameter template: The template to save
    /// - Returns: True if successful, false otherwise
    func saveTemplate(_ template: NoteTemplate) -> Bool {
        let fileURL = templatesDirectory.appendingPathComponent("\(template.id.uuidString).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            
            let data = try encoder.encode(template)
            
            // Write atomically using a temp file then replace
            let tmpURL = fileURL.appendingPathExtension("tmp")
            try data.write(to: tmpURL, options: .atomic)
            try FileManager.default.replaceItem(at: fileURL, withItemAt: tmpURL, backupItemName: nil, options: [], resultingItemURL: nil)
            
            print("✅ Saved template: \(template.id)")
            return true
        } catch {
            print("❌ Failed to save template: \(error)")
            return false
        }
    }
    
    /// Loads all templates from local storage
    /// - Returns: Array of templates, empty if none found
    func loadTemplates() -> [NoteTemplate] {
        var templates: [NoteTemplate] = []
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: templatesDirectory,
                                                                     includingPropertiesForKeys: nil,
                                                                     options: .skipsHiddenFiles)
            
            let decoder = JSONDecoder()
            
            for fileURL in fileURLs {
                guard fileURL.pathExtension == "json" else { continue }
                
                do {
                    let data = try Data(contentsOf: fileURL)
                    let template = try decoder.decode(NoteTemplate.self, from: data)
                    templates.append(template)
                    print("✅ Loaded template: \(template.id)")
                } catch {
                    print("❌ Failed to load template from \(fileURL): \(error)")
                }
            }
        } catch {
            print("❌ Failed to read templates directory: \(error)")
        }
        
        // Always ensure all default templates are available
        let defaultTemplates = NoteTemplate.defaultTemplates()
        let existingTitles = Set(templates.map { $0.title })
        
        // Add any missing default templates
        for defaultTemplate in defaultTemplates {
            if !existingTitles.contains(defaultTemplate.title) {
                _ = saveTemplate(defaultTemplate)
                templates.append(defaultTemplate)
                print("✅ Added missing default template: \(defaultTemplate.title)")
            }
        }
        
        return templates.sorted { $0.title < $1.title }
    }
    
    /// Deletes a template from local storage
    /// - Parameter template: The template to delete
    /// - Returns: True if successful, false otherwise
    func deleteTemplate(_ template: NoteTemplate) -> Bool {
        // Don't allow deletion of default templates
        if template.isDefault {
            print("⚠️ Cannot delete default template")
            return false
        }
        
        let fileURL = templatesDirectory.appendingPathComponent("\(template.id.uuidString).json")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ Deleted template: \(template.id)")
            return true
        } catch {
            print("❌ Failed to delete template: \(error)")
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