//
//  Yolo+Extensions.swift
//  SwiftRacer
//
//  Created by Mihaela Miches on 11/5/16.
//  Copyright © 2016 me. All rights reserved.
//

import UIKit

extension Race {
    struct StickerProperties {
        /// The desired size of an racer sticker image.
        static let size = CGSize(width: 300.0, height: 300.0)
        
        /**
         The amount of padding to apply to a sticker when drawn with an opaque
         background.
         */
        static let opaquePadding = CGSize(width: 60.0, height: 50.0)
    }
    
    func renderSticker(opaque: Bool) -> UIImage? {
        guard let partsImage = renderRaceSticker() else { return nil }
        
        // Determine the size to draw as a sticker.
        let outputSize: CGSize
        let raceSize: CGSize
        
        if opaque {
            // Scale the image to fit in the center of the sticker.
            let scale = min((StickerProperties.size.width - StickerProperties.opaquePadding.width) / partsImage.size.height,
                            (StickerProperties.size.height - StickerProperties.opaquePadding.height) / partsImage.size.width)
            raceSize = CGSize(width: partsImage.size.width * scale, height: partsImage.size.height * scale)
            outputSize = StickerProperties.size
        }
        else {
            // Scale the image to fit it's height into the sticker.
            let scale = StickerProperties.size.width / partsImage.size.height
            raceSize = CGSize(width: partsImage.size.width * scale, height: partsImage.size.height * scale)
            outputSize = raceSize
        }
        
        // Scale the image to the correct size.
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let image = renderer.image { context in
            let backgroundColor: UIColor
            if opaque {
                // Give the image a colored background.
                backgroundColor = UIColor(red: 250.0 / 255.0, green: 225.0 / 255.0, blue: 235.0 / 255.0, alpha: 1.0)
            }
            else {
                // Give the image a clear background
                backgroundColor = UIColor.clear
            }
            
            // Draw the background
            backgroundColor.setFill()
            context.fill(CGRect(origin: CGPoint.zero, size: StickerProperties.size))
            
            // Draw the scaled composited image.
            var drawRect = CGRect.zero
            drawRect.size = raceSize
            drawRect.origin.x = (outputSize.width / 2.0) - (raceSize.width / 2.0)
            drawRect.origin.y = (outputSize.height / 2.0) - (raceSize.height / 2.0)
            
            partsImage.draw(in: drawRect)
        }
        
        return image
    }
    
    /// Composites the racers into a single `UIImage`.
    private func renderRaceSticker() -> UIImage? {
        guard !participants.isEmpty else { return nil }

        let partImages = participants.flatMap { $0.value.stickerImage(percentCompleted: CGFloat(($0.value.totalDistance * 100.0)/maxDistance())) }
 
        // Calculate the size of the composited racers.
        var outputImageSize = CGSize.zero
        outputImageSize.width = partImages.reduce(0) { largestWidth, image in
            return max(largestWidth, image.size.width)
        }
        outputImageSize.height = partImages.reduce(0) { totalHeight, image in
            return totalHeight + image.size.height
        }
        
        // Render the part images into a single composite image.
        let renderer = UIGraphicsImageRenderer(size: outputImageSize)
        let image = renderer.image { context in
            // Draw each of the body parts in a vertica stack.
            var nextYPosition = CGFloat(0.0)
            for partImage in partImages {
                var position = CGPoint.zero
                position.x = outputImageSize.width / 2.0 - partImage.size.width / 2.0
                position.y = nextYPosition
                
                partImage.draw(at: position)
                
                nextYPosition += partImage.size.height
            }
        }
        
        return image
    }
    
    func maxDistance() -> Double {
        return participants.values.max { $0.0.totalDistance < $0.1.totalDistance }?.totalDistance ?? 0
    }
}

extension UILabel {
    static func carLabel(withFontSize: CGFloat = 70) -> UILabel {
        let carLabel = UILabel(frame: .zero)
        carLabel.backgroundColor = .clear
        carLabel.text = "🏎"
        carLabel.font = UIFont.systemFont(ofSize: withFontSize)
        carLabel.sizeToFit()
        return carLabel
    }
}

extension UIImage {
    convenience init?(view: UIView) {
        defer {
            UIGraphicsEndImageContext()
        }
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        guard let currentContext = UIGraphicsGetCurrentContext() else { return nil }
        view.layer.render(in: currentContext)

        if let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage {
            self.init(cgImage: image)
        } else {
            return nil
        }
    }
}

extension Double {
    var distanceString: String {
        return LengthFormatter().string(fromMeters: self)
    }
}
