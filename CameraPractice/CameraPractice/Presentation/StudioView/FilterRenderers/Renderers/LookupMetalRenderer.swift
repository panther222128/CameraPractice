//
//  LookupRenderer.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/07/21.
//

import CoreMedia
import CoreVideo
import Metal
import MetalKit

class LookupMetalRenderer: FilterRenderer {

    var description: String = "Lookup (Metal)"
    var isPrepared: Bool = false
    
    private let samplers: [String: String]?
    private var intensity: Float
    private(set) var inputFormatDescription: CMFormatDescription?
    private(set) var outputFormatDescription: CMFormatDescription?
    private var outputPixelBufferPool: CVPixelBufferPool?
    private let metalDevice = MTLCreateSystemDefaultDevice()!
    private var computePipelineState: MTLComputePipelineState?
    private var textureCache: CVMetalTextureCache!
    private let outputBufferPoolAllocator: OutputBufferPoolAllocatable
    private lazy var commandQueue: MTLCommandQueue? = {
        return self.metalDevice.makeCommandQueue()
    }()
    
    required init() {
        self.samplers = ["lookup": "original_lookup.png"]
        self.intensity = 1.0
        self.outputBufferPoolAllocator = DefaultOutputBufferPoolAllocator()
        let defaultLibrary = metalDevice.makeDefaultLibrary()!
        let kernelFunction = defaultLibrary.makeFunction(name: "lookupKernel")
        do {
            computePipelineState = try metalDevice.makeComputePipelineState(function: kernelFunction!)
        } catch {
            print("Could not create pipeline state: \(error)")
        }
    }
    
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        reset()
        (outputPixelBufferPool, _, outputFormatDescription) = self.outputBufferPoolAllocator.allocateOutputBufferPool(with: formatDescription, outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        
        if outputPixelBufferPool == nil {
            return
        }
        inputFormatDescription = formatDescription
        
        var metalTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &metalTextureCache) != kCVReturnSuccess {
            assertionFailure("Unable to allocate texture cache")
        } else {
            textureCache = metalTextureCache
        }
        
        isPrepared = true
    }
    
    func reset() {
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        textureCache = nil
        isPrepared = false
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        if !isPrepared {
            assertionFailure("Invalid state: Not prepared.")
            return nil
        }
        
        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &newPixelBuffer)
        guard let outputPixelBuffer = newPixelBuffer else { return nil }
        guard let inputTexture = makeTextureFromCVPixelBuffer(pixelBuffer: pixelBuffer, textureFormat: .bgra8Unorm), let outputTexture = makeTextureFromCVPixelBuffer(pixelBuffer: outputPixelBuffer, textureFormat: .bgra8Unorm) else { return nil }
        
        guard let commandQueue = commandQueue, let commandBuffer = commandQueue.makeCommandBuffer(), let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            CVMetalTextureCacheFlush(textureCache!, 0)
            return nil
        }
        
        commandEncoder.setBytes(&intensity, length: MemoryLayout<Float>.size, index: 0)
        commandEncoder.label = "Lookup"
        commandEncoder.setComputePipelineState(computePipelineState!)
        commandEncoder.setTexture(inputTexture, index: 0)
        commandEncoder.setTexture(outputTexture, index: 1)
        
        if let samplers = samplers {
            for key in samplers.keys.sorted() {
                let imageName = samplers[key]!
                if !imageName.isEmpty {
                    let texture = getSamplerTexture(named: imageName)!
                    commandEncoder.setTexture(texture, index: 2)
                }
            }
        }
        
        let width = computePipelineState!.threadExecutionWidth
        let height = computePipelineState!.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
        let threadgroupsPerGrid = MTLSize(width: (inputTexture.width + width - 1) / width, height: (inputTexture.height + height - 1) / height, depth: 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        return outputPixelBuffer
    }
    
    func makeTextureFromCVPixelBuffer(pixelBuffer: CVPixelBuffer, textureFormat: MTLPixelFormat) -> MTLTexture? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, textureFormat, width, height, 0, &cvTextureOut)
        
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            CVMetalTextureCacheFlush(textureCache, 0)
            return nil
        }
        
        return texture
    }
    
    private func getSamplerTexture(named name: String) -> MTLTexture? {
        let bundle = Bundle(for: Self.self)
        let resourceURL = bundle.url(forResource: "FilterResources", withExtension: "bundle")!
        let resourceBundle = Bundle(url: resourceURL)!
        let url = resourceBundle.url(forResource: name, withExtension: nil)!
        guard let data = try? Data(contentsOf: url) else { return nil }
        return self.loadTexture(data: data, metalDevice: self.metalDevice)
    }

    private func loadTexture(data: Data, metalDevice: MTLDevice) -> MTLTexture? {
        let loader = MTKTextureLoader(device: metalDevice)
        return try? loader.newTexture(data: data, options: [MTKTextureLoader.Option.SRGB: false])
    }
    
}
