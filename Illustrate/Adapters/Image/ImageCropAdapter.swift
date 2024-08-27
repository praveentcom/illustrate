import Foundation
import ImageCropper
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
    import Cocoa
#endif

#if os(macOS)
    private func crop(image: NSImage, from: CGPoint, to: CGPoint) -> NSImage? {
        let cropWidth = to.x - from.x
        let cropHeight = to.y - from.y

        let cropRect = CGRect(
            x: from.x,
            y: image.size.height - from.y - cropHeight,
            width: cropWidth,
            height: cropHeight
        )

        guard let tiffData = image.tiffRepresentation,
              let sourceImageRep = NSBitmapImageRep(data: tiffData),
              let cgImage = sourceImageRep.cgImage
        else {
            return nil
        }

        let scale = image.size.width / CGFloat(cgImage.width)

        let scaledCropRect = CGRect(
            x: cropRect.origin.x / scale,
            y: cropRect.origin.y / scale,
            width: cropRect.size.width / scale,
            height: cropRect.size.height / scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledCropRect) else {
            return nil
        }

        let croppedImage = NSImage(cgImage: croppedCGImage, size: NSSize(width: cropWidth, height: cropHeight))
        return croppedImage
    }
#else
    private func crop(image: UIImage, from: CGPoint, to: CGPoint) -> UIImage? {
        let cropWidth = to.x - from.x
        let cropHeight = to.y - from.y

        let cropRect = CGRect(x: from.x, y: from.y, width: cropWidth, height: cropHeight)

        guard let cgImage = image.cgImage else {
            return nil
        }

        let scale = image.scale

        let scaledCropRect = CGRect(
            x: cropRect.origin.x / scale,
            y: cropRect.origin.y / scale,
            width: cropRect.size.width / scale,
            height: cropRect.size.height / scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledCropRect) else {
            return nil
        }

        let croppedImage = UIImage(cgImage: croppedCGImage, scale: 1, orientation: image.imageOrientation)
        return croppedImage
    }
#endif

func cropImage(
    _ image: PlatformImage,
    fromX: CGFloat,
    fromY: CGFloat,
    toX: CGFloat,
    toY: CGFloat
) -> PlatformImage? {
    return crop(image: image, from: CGPoint(x: fromX, y: fromY), to: CGPoint(x: toX, y: toY))
}

struct ImageCropAdapter: View {
    var image: PlatformImage
    var cropDimensions: String

    @State private var cropRect: CGRect = .zero

    var onCropConfirm: (PlatformImage) -> Void
    var onCropCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ImageCropperView(
                image: image.toImage(),
                cropRect: nil,
                ratio: CropperRatio(
                    width: CGFloat(getAspectRatio(dimension: cropDimensions).width),
                    height: CGFloat(getAspectRatio(dimension: cropDimensions).height)
                )
            )
            .onCropChanged { _cropRect in
                cropRect = CGRect(
                    x: roundToTwoDecimalPlaces(_cropRect.origin.x),
                    y: roundToTwoDecimalPlaces(_cropRect.origin.y),
                    width: roundToTwoDecimalPlaces(_cropRect.size.width),
                    height: roundToTwoDecimalPlaces(_cropRect.size.height)
                )
            }
            .frame(maxWidth: 800, maxHeight: 600)
            HStack {
                Spacer()
                Button("Cancel") {
                    onCropCancel()
                }
                Button("Proceed") {
                    if let croppedImage = cropImage(
                        image,
                        fromX: round(cropRect.origin.x * image.size.width),
                        fromY: round(cropRect.origin.y * image.size.height),
                        toX: round(cropRect.size.width * image.size.width),
                        toY: round(cropRect.size.height * image.size.height)
                    ) {
                        onCropConfirm(croppedImage)
                    } else {
                        onCropCancel()
                    }
                }
                Spacer()
            }
        }
        #if os(macOS)
        .padding(.all, 24)
        #else
        .padding(.all, 12)
        #endif
    }
}
