import CoreImage

enum AlphaFrameFilterError: Error {
    case unsupportedRenderingMode
}

final class AlphaFrameFilter {
    private let renderingMode: RenderingMode
    private let context: CIContext
    private let kernel: CIColorKernel?

    enum RenderingMode {
        case builtInFilter
        case customKernel
    }

    init(renderingMode: RenderingMode) {
        self.renderingMode = renderingMode
        self.context = CIContext()

        if renderingMode == .customKernel {
            let kernelString = """
            kernel vec4 alphaFrame(__sample s) {
                return vec4(s.rgb, s.r);
            }
            """
            self.kernel = CIColorKernel(source: kernelString)
        } else {
            self.kernel = nil
        }
    }

    func process(_ image: CIImage) throws -> CIImage {
        switch renderingMode {
        case .builtInFilter:
            let parameters: [String: Any] = [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                "inputAVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
            ]
            guard let filter = CIFilter(name: "CIColorMatrix", parameters: parameters) else {
                throw AlphaFrameFilterError.unsupportedRenderingMode
            }
            filter.setValue(image, forKey: kCIInputImageKey)
            guard let output = filter.outputImage else {
                throw AlphaFrameFilterError.unsupportedRenderingMode
            }
            return output

        case .customKernel:
            guard let kernel = self.kernel else {
                throw AlphaFrameFilterError.unsupportedRenderingMode
            }
            return kernel.apply(extent: image.extent, arguments: [image]) ?? image
        }
    }
}
