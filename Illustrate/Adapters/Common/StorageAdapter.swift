import SwiftUI
import Foundation

func deleteAllICloudDocuments() {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
        print("iCloud container not available.")
        return
    }

    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
            print("Deleted file: \(fileURL.lastPathComponent)")
        }
        
        print("All iCloud documents have been deleted.")
    } catch {
        print("Error deleting iCloud documents: \(error.localizedDescription)")
    }
}

func deleteICloudDocuments(containingSubstring substring: String) {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
        print("iCloud container not available.")
        return
    }

    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil, options: [])
        
        var deletedCount = 0
        
        for fileURL in fileURLs {
            let filename = fileURL.lastPathComponent
            if filename.contains(substring) {
                try FileManager.default.removeItem(at: fileURL)
                print("Deleted file: \(filename)")
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            print("Deleted \(deletedCount) file(s) containing '\(substring)' in the name.")
        } else {
            print("No files found containing '\(substring)' in the name.")
        }
    } catch {
        print("Error deleting iCloud documents: \(error.localizedDescription)")
    }
}
