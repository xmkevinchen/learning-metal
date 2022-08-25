//
//  Renderer.swift
//  LearningMetal
//
//  Created by Kai Chen on 8/20/22.
//

import MetalKit

enum RendererError: Error {
    case nilDevice
    case nilCommandQueue
    case nilDefaultLibrary
}

class Renderer: NSObject, MTKViewDelegate {
    private let view: MTKView
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let indexCount: Int
    private var pipelineState: MTLRenderPipelineState?
    private let texture: MTLTexture
    
    init(view: MTKView) throws {
        self.view = view
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw RendererError.nilDevice
        }
        
        self.device = device
        guard let commandQueue = device.makeCommandQueue() else {
            throw RendererError.nilCommandQueue
        }
        
        self.commandQueue = commandQueue
        
        /**
         Metal texture coordiantes are values from 0.0 to 1.0 (normalized) both x and y
         - (0.0, 0.0) - The top-left corner of the image, the first byte of the texture data
         - (1.0, 1.0) - The bottom-right corner of the image, the last byte of the texture data
         */
        let vertices = [
            Vertex(position: [-0.75, -0.75], color: [1.0, 0.0, 0.0, 1.0], textureCoordinate: [0.0, 1.0]),      // 0
            Vertex(position: [ 0.75, -0.75], color: [0.0, 1.0, 0.0, 1.0], textureCoordinate: [1.0, 1.0]),      // 1
            Vertex(position: [ 0.75,  0.75], color: [0.0, 0.0, 1.0, 1.0], textureCoordinate: [1.0, 0.0]),      // 2
            Vertex(position: [-0.75,  0.75], color: [0.0, 1.0, 0.0, 1.0], textureCoordinate: [0.0, 0.0]),      // 3
        ]
        
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride)!
        
        let indecies: [UInt16] = [
            0, 1, 2,
            2, 3, 0,
        ]
        indexCount = indecies.count
        indexBuffer = device.makeBuffer(bytes: indecies, length: indecies.count * MemoryLayout<UInt16>.stride)!
        
        texture = try Renderer.loadTexture(device: device, imageAssetName: "metal", scaleFactor: Renderer.scaleFactor(with: view))
        pipelineState = try Renderer.createPipelineState(device: device, label: "Renderer", pixelFormat: view.colorPixelFormat)
        
        super.init()
        self.view.enableSetNeedsDisplay = true
        self.view.device = device
        self.view.delegate = self
    }
    
    static func createPipelineState(device: MTLDevice, label: String, pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.nilDefaultLibrary
        }
        
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = label
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    static func loadTexture(device: MTLDevice, imageAssetName: String, scaleFactor: CGFloat, options: [MTKTextureLoader.Option: Any]? = nil) throws -> MTLTexture {
        // Load Texture
        let textureLoader = MTKTextureLoader(device: device)
        
        return try textureLoader.newTexture(name: imageAssetName,
                                            scaleFactor: scaleFactor,
                                            bundle: nil,
                                            options: options)
    }
    
    static func scaleFactor(with view: MTKView) -> CGFloat {
#if os(macOS)
        return view.window?.backingScaleFactor ?? 1.0
#else
        return view.contentScaleFactor
#endif
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable,
              let renderDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        renderDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        renderDescriptor.colorAttachments[0].loadAction = .clear
        renderDescriptor.colorAttachments[0].storeAction = .store
        renderDescriptor.colorAttachments[0].texture = currentDrawable.texture
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else {
            return
        }
        
        if let pipelineState = pipelineState {
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            // Set the texture object
            renderEncoder.setFragmentTexture(texture, index: 0)
            
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: indexCount,
                                                indexType: .uint16,
                                                indexBuffer: indexBuffer,
                                                indexBufferOffset: 0)
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
        
    }
    
}
