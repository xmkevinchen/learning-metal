//
//  Renderer.swift
//  LearningMetal
//
//  Created by Kai Chen on 8/20/22.
//

import MetalKit

enum RendererError: Error {
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
    
    init(view: MTKView, device: MTLDevice) {
        self.view = view
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
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
     
        do {
            // Load Texture
            let textureLoader = MTKTextureLoader(device: device)
            let options: [MTKTextureLoader.Option: Any] = [
                .origin: MTKTextureLoader.Origin.topLeft]
            
#if os(macOS)
            texture = try textureLoader.newTexture(name: "metal",
                                                   scaleFactor: view.window?.backingScaleFactor ?? 2.0,
                                                   bundle: nil,
                                                   options: options)
#else
            texture = try textureLoader.newTexture(name: "metal",
                                                   scaleFactor: view.contentScaleFactor,
                                                   bundle: nil,
                                                   options: options)
#endif
            
            pipelineState = try Renderer.createPipelineState(device: device,
                                                             label: "Renderer",
                                                             pixelFormat: view.colorPixelFormat)
        } catch (let error) {
            print("====> Error occurred: \(error)")
            fatalError()
        }
        
        
        super.init()
        
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
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable,
              let onscreenDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        onscreenDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        onscreenDescriptor.colorAttachments[0].loadAction = .clear
        onscreenDescriptor.colorAttachments[0].storeAction = .store
        onscreenDescriptor.colorAttachments[0].texture = currentDrawable.texture
        
        guard let onscreenCommandBuffer = commandQueue.makeCommandBuffer(),
              let onscreenCommandEncoder = onscreenCommandBuffer.makeRenderCommandEncoder(descriptor: onscreenDescriptor) else {
            return
        }
       
        if let pipelineState = pipelineState {
            onscreenCommandEncoder.setRenderPipelineState(pipelineState)
            onscreenCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            // Set the texture object
            onscreenCommandEncoder.setFragmentTexture(texture, index: 0)
            
            onscreenCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                         indexCount: indexCount,
                                                         indexType: .uint16,
                                                         indexBuffer: indexBuffer,
                                                         indexBufferOffset: 0)
        }
        
        onscreenCommandEncoder.endEncoding()
 
        onscreenCommandBuffer.present(currentDrawable)
        onscreenCommandBuffer.commit()
        
    }
    
}
