import SwiftUI

#if os(macOS)
    import AppKit

    typealias UniversalColor = NSColor
    typealias PlatformImage = NSImage
#else
    import UIKit

    typealias UniversalColor = UIColor
    typealias PlatformImage = UIImage
#endif

func loadImageFromDocumentsDirectory(withName name: String) -> PlatformImage? {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let imageFileURL = documentsURL.appendingPathComponent("\(name).png")

    if let imageData = try? Data(contentsOf: imageFileURL) {
        #if os(macOS)
            return NSImage(data: imageData)
        #else
            return UIImage(data: imageData)
        #endif
    }
    return nil
}

func loadImageFromiCloud(_ fileName: String) -> PlatformImage? {
    if let image = loadImageFromDocumentsDirectory(withName: fileName) {
        return image
    }

    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
        return nil
    }

    do {
        if !FileManager.default.fileExists(atPath: containerURL.path) {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
        }

        let fileUrl = containerURL.appendingPathComponent("\(fileName).png")
        
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: fileUrl)

        #if os(macOS)
            guard let image = NSImage(data: data) else { return nil }
        #else
            guard let image = UIImage(data: data) else { return nil }
        #endif
        return image
    } catch {
        print("Error loading image '\(fileName)': \(error.localizedDescription)")
        return nil
    }
}

func saveImageToDocumentsDirectory(imageData: Data, withName name: String) -> URL? {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let imageFileURL = documentsURL.appendingPathComponent("\(name).png")

    do {
        try imageData.write(to: imageFileURL)
        print("Image saved to: \(imageFileURL.path)")
        return imageFileURL
    } catch {
        print("Error saving image: \(error)")
        return nil
    }
}

func getImageSizeInBytes(imageURL: URL) -> Int? {
    if let imageData = try? Data(contentsOf: imageURL) {
        return imageData.count
    }
    return nil
}

func toPlatformImage(base64: String) -> PlatformImage? {
    #if os(macOS)
        guard let image = NSImage(data: Data(base64Encoded: base64)!) else { return nil }
    #else
        guard let image = UIImage(data: Data(base64Encoded: base64)!) else { return nil }
    #endif
    return image
}

extension PlatformImage {
    func saveToiCloud(fileName: String) {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            print("iCloud container not available.")
            return
        }

        do {
            if !FileManager.default.fileExists(atPath: containerURL.path) {
                try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
            }

            let fileURL = containerURL.appendingPathComponent("\(fileName).png")

            #if os(macOS)
                guard let tiffData = tiffRepresentation,
                      let bitmapImage = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmapImage.representation(using: .png, properties: [:])
                else {
                    print("Failed to create PNG data from NSImage.")
                    return
                }
            #else
                guard let pngData = self.pngData() else {
                    print("Failed to create PNG data from UIImage.")
                    return
                }
            #endif

            try pngData.write(to: fileURL)
            print("Image saved to iCloud: \(fileURL.path)")

            #if os(macOS)
                try FileManager.default.setAttributes([FileAttributeKey.extensionHidden: true], ofItemAtPath: fileURL.path)
            #endif
        } catch {
            print("Error saving image to iCloud: \(error.localizedDescription)")
        }
    }

    func toBase64PNG() -> String? {
        #if os(macOS)
            guard let tiffData = tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmapImage.representation(using: .png, properties: [:])
            else {
                return nil
            }
        #else
            guard let pngData = self.pngData() else {
                return nil
            }
        #endif

        return pngData.base64EncodedString(options: .endLineWithCarriageReturn)
    }

    func toImage() -> Image {
        #if os(macOS)
            return Image(nsImage: self)
        #else
            return Image(uiImage: self)
        #endif
    }

    #if os(macOS)
        func saveImageToDownloads(fileName: String) {
            let savePanel = NSSavePanel()
            savePanel.title = "Save your image"
            savePanel.message = "Choose the location to save the image."
            savePanel.allowedContentTypes = [.png]
            savePanel.nameFieldStringValue = "illustrate_\(fileName)"

            savePanel.begin { response in
                if response == .OK {
                    guard let url = savePanel.url else { return }

                    if let tiffData = self.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapImage.representation(using: .png, properties: [:])
                    {
                        do {
                            try pngData.write(to: url)
                            print("Image saved to \(url)")
                        } catch {
                            print("Error saving image: \(error)")
                        }
                    }
                }
            }
        }

        func shareImage() {
            let imageToShare = [self]
            let picker = NSSharingServicePicker(items: imageToShare)

            if let window = NSApplication.shared.keyWindow {
                picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
            }
        }

        func resizeImage(scale: CGFloat) -> String? {
            let newSize = NSSize(width: size.width * scale, height: size.height * scale)
            let resizedImage = NSImage(size: newSize)

            resizedImage.lockFocus()
            draw(in: NSRect(origin: .zero, size: newSize),
                 from: NSRect(origin: .zero, size: size),
                 operation: .copy,
                 fraction: 1.0)
            resizedImage.unlockFocus()

            guard let tiffData = resizedImage.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmapRep.representation(using: .png, properties: [
                      .compressionFactor: 1.0,
                  ])
            else {
                return nil
            }

            return pngData.base64EncodedString()
        }
    #else
        func resizeImage(scale: CGFloat) -> String? {
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            guard let pngData = resizedImage?.pngData() else {
                return nil
            }

            return pngData.base64EncodedString()
        }
    #endif

    func resizeImage(targetSize: CGSize) -> PlatformImage? {
        #if os(macOS)
            let scale = NSScreen.main?.backingScaleFactor ?? 1.0
            let scaledSize = CGSize(width: targetSize.width / scale, height: targetSize.height / scale)

            let newImage = NSImage(size: scaledSize)
            newImage.lockFocus()

            NSGraphicsContext.current?.imageInterpolation = .high
            let rect = NSRect(origin: .zero, size: scaledSize)
            draw(in: rect, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1.0)

            newImage.unlockFocus()

            guard let cgImage = newImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return nil
            }

            let finalImage = NSImage(cgImage: cgImage, size: scaledSize)
            return finalImage
        #else
            let scale = UIScreen.main.scale
            let scaledSize = CGSize(width: targetSize.width / scale, height: targetSize.height / scale)

            let format = UIGraphicsImageRendererFormat.default()
            format.scale = scale

            let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)
            let resizedImage = renderer.image { context in
                context.cgContext.interpolationQuality = .none
                self.draw(in: CGRect(origin: .zero, size: scaledSize))
            }

            if let cgImage = resizedImage.cgImage {
                return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
            }
            return nil
        #endif
    }
}

func getDominantColors(imageURL: URL, clusterCount: Int = 6) -> [String] {
    if let imageData = try? Data(contentsOf: imageURL) {
        #if canImport(UIKit)
            if let image = UIImage(data: imageData) {
                return dominantColorsFromImage(image, clusterCount: clusterCount)
            }
        #elseif canImport(AppKit)
            if let image = NSImage(data: imageData) {
                return dominantColorsFromImage(image, clusterCount: clusterCount)
            }
        #endif
    }
    return []
}

#if os(macOS)
    func dominantColorsFromImage(_ image: NSImage, clusterCount: Int) -> [String] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return [] }
        return dominantColorsFromCGImage(cgImage, clusterCount: clusterCount)
    }
#else
    func dominantColorsFromImage(_ image: UIImage, clusterCount: Int) -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        return dominantColorsFromCGImage(cgImage, clusterCount: clusterCount)
    }
#endif

func samplePixels(from image: CGImage, sampleCount: Int) -> [(r: CGFloat, g: CGFloat, b: CGFloat)] {
    let width = image.width
    let height = image.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8
    var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    let context = CGContext(
        data: &pixelData,
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    context?.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

    var sampledPixels = [(r: CGFloat, g: CGFloat, b: CGFloat)]()
    for _ in 0 ..< sampleCount {
        let x = Int(arc4random_uniform(UInt32(width)))
        let y = Int(arc4random_uniform(UInt32(height)))
        let pixelIndex = (y * width + x) * bytesPerPixel
        let r = CGFloat(pixelData[pixelIndex]) / 255.0
        let g = CGFloat(pixelData[pixelIndex + 1]) / 255.0
        let b = CGFloat(pixelData[pixelIndex + 2]) / 255.0
        sampledPixels.append((r: r, g: g, b: b))
    }
    return sampledPixels
}

func downsample(image: CGImage, to size: CGSize) -> CGImage? {
    let widthRatio = size.width / CGFloat(image.width)
    let heightRatio = size.height / CGFloat(image.height)
    let scaleFactor = min(widthRatio, heightRatio)

    let newWidth = CGFloat(image.width) * scaleFactor
    let newHeight = CGFloat(image.height) * scaleFactor

    let context = CGContext(
        data: nil,
        width: Int(newWidth),
        height: Int(newHeight),
        bitsPerComponent: image.bitsPerComponent,
        bytesPerRow: 0,
        space: image.colorSpace!,
        bitmapInfo: image.bitmapInfo.rawValue
    )

    context?.interpolationQuality = .high
    context?.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

    return context?.makeImage()
}

func dominantColorsFromCGImage(_ cgImage: CGImage, clusterCount: Int) -> [String] {
    let startTime = CFAbsoluteTimeGetCurrent()

    let targetSize = CGSize(width: 100, height: 100)
    if let downsampledImage = downsample(image: cgImage, to: targetSize) {
        let sampledPixels = samplePixels(from: downsampledImage, sampleCount: 1000)

        let clusters = kMeansWithTimeCheck(pixels: sampledPixels, clusterCount: clusterCount, startTime: startTime)

        guard let clusters = clusters else {
            return []
        }

        return clusters.map { color in
            UniversalColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0).hexString
        }
    }
    return []
}

func kMeansWithTimeCheck(pixels: [(r: CGFloat, g: CGFloat, b: CGFloat)], clusterCount: Int, startTime: CFAbsoluteTime) -> [(r: CGFloat, g: CGFloat, b: CGFloat)]? {
    var clusters = [(r: CGFloat, g: CGFloat, b: CGFloat)]()
    var previousClusters = [(r: CGFloat, g: CGFloat, b: CGFloat)]()

    for _ in 0 ..< clusterCount {
        let randomPixel = pixels[Int(arc4random_uniform(UInt32(pixels.count)))]
        clusters.append(randomPixel)
    }

    repeat {
        if CFAbsoluteTimeGetCurrent() - startTime > 1.0 {
            return nil
        }

        previousClusters = clusters

        var pixelGroups = [[(r: CGFloat, g: CGFloat, b: CGFloat)]](repeating: [], count: clusterCount)

        for pixel in pixels {
            let nearestClusterIndex = clusters.enumerated().min(by: { distance(pixel, $0.element) < distance(pixel, $1.element) })!.offset
            pixelGroups[nearestClusterIndex].append(pixel)
        }

        clusters = pixelGroups.map { group in
            let count = CGFloat(group.count)
            let r = group.reduce(0) { $0 + $1.r } / count
            let g = group.reduce(0) { $0 + $1.g } / count
            let b = group.reduce(0) { $0 + $1.b } / count
            return (r: r, g: g, b: b)
        }
    } while !clustersEqual(clusters, previousClusters)

    return clusters
}

func kMeans(pixels: [(r: CGFloat, g: CGFloat, b: CGFloat)], clusterCount: Int) -> [(r: CGFloat, g: CGFloat, b: CGFloat)] {
    var clusters = [(r: CGFloat, g: CGFloat, b: CGFloat)]()
    var previousClusters = [(r: CGFloat, g: CGFloat, b: CGFloat)]()

    for _ in 0 ..< clusterCount {
        let randomPixel = pixels[Int(arc4random_uniform(UInt32(pixels.count)))]
        clusters.append(randomPixel)
    }

    repeat {
        previousClusters = clusters

        var pixelGroups = [[(r: CGFloat, g: CGFloat, b: CGFloat)]](repeating: [], count: clusterCount)

        for pixel in pixels {
            let nearestClusterIndex = clusters.enumerated().min(by: { distance(pixel, $0.element) < distance(pixel, $1.element) })!.offset
            pixelGroups[nearestClusterIndex].append(pixel)
        }

        clusters = pixelGroups.map { group in
            let count = CGFloat(group.count)
            let r = group.reduce(0) { $0 + $1.r } / count
            let g = group.reduce(0) { $0 + $1.g } / count
            let b = group.reduce(0) { $0 + $1.b } / count
            return (r: r, g: g, b: b)
        }
    } while !clustersEqual(clusters, previousClusters)

    return clusters
}

func clustersEqual(_ a: [(r: CGFloat, g: CGFloat, b: CGFloat)], _ b: [(r: CGFloat, g: CGFloat, b: CGFloat)]) -> Bool {
    guard a.count == b.count else { return false }
    for i in 0 ..< a.count {
        if a[i] != b[i] {
            return false
        }
    }
    return true
}

func distance(_ a: (r: CGFloat, g: CGFloat, b: CGFloat), _ b: (r: CGFloat, g: CGFloat, b: CGFloat)) -> CGFloat {
    let rDiff = a.r - b.r
    let gDiff = a.g - b.g
    let bDiff = a.b - b.b
    return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff)
}

extension UniversalColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

#if os(macOS)
    extension NSColor {
        convenience init?(hex: String) {
            var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

            if hexString.hasPrefix("#") {
                hexString.remove(at: hexString.startIndex)
            }

            guard hexString.count == 6 || hexString.count == 8 else {
                return nil
            }

            var rgbValue: UInt64 = 0
            Scanner(string: hexString).scanHexInt64(&rgbValue)

            let red, green, blue, alpha: CGFloat
            if hexString.count == 6 {
                red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
                green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
                blue = CGFloat(rgbValue & 0x0000FF) / 255.0
                alpha = 1.0
            } else {
                red = CGFloat((rgbValue & 0xFF00_0000) >> 24) / 255.0
                green = CGFloat((rgbValue & 0x00FF_0000) >> 16) / 255.0
                blue = CGFloat((rgbValue & 0x0000_FF00) >> 8) / 255.0
                alpha = CGFloat(rgbValue & 0x0000_00FF) / 255.0
            }

            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }

    func getUniversalColorFromHex(hexString: String) -> NSColor {
        return NSColor(hex: hexString) ?? NSColor.clear
    }
#else
    func getUniversalColorFromHex(hexString: String) -> UIColor {
        var rgbValue: UInt64 = 0
        let scanner = Scanner(string: hexString.replacingOccurrences(of: "#", with: ""))

        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
#endif

func getAspectRatio(dimension: String) -> (width: Int, height: Int, actualWidth: Int, actualHeight: Int, ratio: String) {
    let dimensions = dimension.split(separator: "x")

    guard dimensions.count == 2,
          let width = Int(dimensions[0]),
          let height = Int(dimensions[1]),
          width > 0, height > 0
    else {
        return (width: 0, height: 0, actualWidth: 0, actualHeight: 0, ratio: "0:0")
    }

    let gcdValue = gcd(width, height)

    return (
        width: width / gcdValue, height: height / gcdValue, actualWidth: width, actualHeight: height, ratio: "\(width / gcdValue):\(height / gcdValue)"
    )
}
