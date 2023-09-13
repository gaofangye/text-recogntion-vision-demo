//
//  ContentView.swift
//  text-recogntion-vision-demo
//
//  Created by nannan on 2023/9/13.
//

import SwiftUI
import Vision

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var visionTextInfos: [VisionTextInfo] = []
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    if let image = selectedImage {
                        let scale = min(geometry.size.width / image.size.width, geometry.size.height / image.size.height)
                        let offsetX = (geometry.size.width - image.size.width * scale) / 2
                        let offsetY = (geometry.size.height - image.size.height * scale) / 2
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit) // Ensure the image fits the available space
                            .frame(maxWidth: .infinity)     // Allow the image to take up as much space as possible
                        
                        ForEach(visionTextInfos, id: \.uniqueID) { visionTextInfo in
                            let scaledFrame = CGRect(x: visionTextInfo.frame.origin.x * scale + offsetX,
                                                     y: visionTextInfo.frame.origin.y * scale + offsetY,
                                                     width: visionTextInfo.frame.width * scale,
                                                     height: visionTextInfo.frame.height * scale)
                            
                            Rectangle()
                                .path(in: scaledFrame)
                                .stroke(Color.red, lineWidth: 2)
                        }
                    }
                }
            }
            
            Button("选择图片") {
                self.isImagePickerPresented = true
            }
            .sheet(isPresented: $isImagePickerPresented, onDismiss: {
                if let image = self.selectedImage {
                    self.processImage(image: image)
                }
            }) {
                ImagePicker(selectedImage: self.$selectedImage)
            }
        }
        .padding()
    }
    
    
    func processImage(image: UIImage) {
        guard let cgImage = image.cgImage else {
            fatalError()
        }
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLevel = .accurate // 采用精确路径
        request.recognitionLanguages = ["zh-Hans", "en-US"] // 设置识别的语言
        
        request.usesLanguageCorrection = false

        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try requestHandler.perform([request])
        } catch {
            print("error:\(error)")
        }
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        visionTextInfos = []
        
        observations.compactMap { observation in
            
            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else { return }
            
            let recognizedStrings = candidate.string
            
            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            let boundingBox = boxObservation?.boundingBox ?? .zero
            
            // Convert the rectangle from normalized coordinates to image coordinates.
            guard let cgImage = selectedImage?.cgImage else { return }
            let rects = convert(boundingBox: boundingBox, to: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)))
            
            let visionTextInfo = VisionTextInfo(text: recognizedStrings.description, frame: rects)
            visionTextInfos.append(visionTextInfo)
        }
        
        let visionTextInfosData = try? JSONEncoder().encode(visionTextInfos)
        let visionTextInfosJson = String(bytes: visionTextInfosData!, encoding: .utf8)
        print(visionTextInfosJson!.description)
    }
    
    func convert(boundingBox: CGRect, to bounds: CGRect) -> CGRect {
        let imageWidth = bounds.width
        let imageHeight = bounds.height
        
        // Begin with input rect.
        var rect = boundingBox
        
        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.minX
        rect.origin.y = (1 - rect.maxY) * imageHeight + bounds.minY
        
        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight
        
        return rect
    }
    
    func processResults(recognizedStrings: [String]) {
        let result = recognizedStrings.joined(separator: " ")
        print(result)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
