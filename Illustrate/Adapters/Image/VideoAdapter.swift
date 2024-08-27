import SwiftUI
import AVFoundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

func loadVideoUrlFromDocumentsDirectory(withName name: String) -> URL? {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let videoFileURL = documentsURL.appendingPathComponent("\(name).mp4")
    
    if fileManager.fileExists(atPath: videoFileURL.path) {
        return videoFileURL
    }
    return nil
}

func getVideoSizeInBytes(videoURL: URL) -> Int? {
    if let imageData = try? Data(contentsOf: videoURL) {
        return imageData.count
    }
    return nil
}

func loadVideoFromiCloud(_ fileName: String) -> URL? {
    if let video = loadVideoUrlFromDocumentsDirectory(withName: fileName) {
        return video
    }
    
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
        print("iCloud container not available.")
        return nil
    }
    
    do {
        if !FileManager.default.fileExists(atPath: containerURL.path) {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        var fileUrl: URL? = containerURL.appendingPathComponent("\(fileName).mp4")
        let data = try Data(contentsOf: fileUrl!)
        
        fileUrl = saveVideoToDocumentsDirectory(videoData: data, withName: fileName)
        return fileUrl
    } catch {
        print("Error loading video: \(error.localizedDescription)")
        return nil
    }
}

func saveVideoToiCloud(videoData: Data, fileName: String) {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
        print("iCloud container not available.")
        return
    }

    do {
        if !FileManager.default.fileExists(atPath: containerURL.path) {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
        }

        let fileURL = containerURL.appendingPathComponent("\(fileName).mp4")

        try videoData.write(to: fileURL)
        print("Video saved to iCloud: \(fileURL.path)")
    } catch {
        print("Error saving video to iCloud: \(error.localizedDescription)")
    }
}

func saveVideoToDocumentsDirectory(videoData: Data, withName name: String) -> URL? {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let videoFileURL = documentsURL.appendingPathComponent("\(name).mp4")
    
    do {
        try videoData.write(to: videoFileURL)
        print("Image saved to: \(videoFileURL.path)")
        return videoFileURL
    } catch {
        print("Error saving image: \(error)")
        return nil
    }
}

#if os(macOS)
func saveVideoToDownloads(url: URL, fileName: String) {
    let savePanel = NSSavePanel()
        savePanel.title = "Save your video"
        savePanel.message = "Choose the location to save the video."
        savePanel.allowedContentTypes = [.mpeg4Movie]
        savePanel.nameFieldStringValue = "illustrate_\(fileName)"

        savePanel.begin { response in
            if response == .OK {
                guard let savePanelUrl = savePanel.url else { return }
                
                do {
                    try FileManager.default.copyItem(at: url, to: savePanelUrl)
                    print("Video saved to \(savePanelUrl)")
                } catch {
                    print("Error saving video: \(error)")
                }
            }
        }
}

func shareVideo(url: URL) {
    let videoToShare = [url]
    let picker = NSSharingServicePicker(items: videoToShare)
    
    if let window = NSApplication.shared.keyWindow {
        picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
    }
}
#endif

func extractFirstFrameFromVideo(base64Video: String) -> String? {
    guard let videoData = Data(base64Encoded: base64Video) else {
        return nil
    }
    
    let tempDirectory = FileManager.default.temporaryDirectory
    let videoURL = tempDirectory.appendingPathComponent("tempVideo.mp4")
    
    do {
        try videoData.write(to: videoURL)
    } catch {
        print("Error writing video data to file: \(error)")
        
        return nil
    }
    
    return getFirstFrameAsBase64Image(from: videoURL)
}

func getFirstFrameAsBase64Image(from videoURL: URL) -> String? {
    let asset = AVAsset(url: videoURL)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    do {
        let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
        
        #if os(macOS)
        let image = NSImage(cgImage: cgImage, size: .zero)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData.base64EncodedString(options: .endLineWithCarriageReturn)
        
        #else
        let image = UIImage(cgImage: cgImage)
        
        guard let pngData = image.pngData() else {
            return nil
        }
        
        return pngData.base64EncodedString(options: .endLineWithCarriageReturn)
        #endif
        
    } catch {
        print("Error extracting first frame: \(error)")
        
        return nil
    }
}
