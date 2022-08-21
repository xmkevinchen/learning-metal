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
    private var pipelineState: MTLRenderPipelineState?
    
    init(view: MTKView, device: MTLDevice) {
        self.view = view
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        let vertices = [
            Vertex(position: [-0.75, -0.75], color: [1.0, 0.0, 0.0, 1.0]),
            Vertex(position: [ 0.75, -0.75], color: [0.0, 1.0, 0.0, 1.0]),
            Vertex(position: [    0,  0.75], color: [0.0, 0.0, 1.0, 1.0]),
        ]
        
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride)!
        
        do {
            pipelineState = try Renderer.createPipelineState(device: device,
                                                                  label: "Triangle Pipeline",
                                                                  pixelFormat: view.colorPixelFormat)
        } catch (let error) {
            print("====> Fail to create render pipeline: \(error)")
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
        
        guard let onscreenCommandBuffer = commandQueue.makeCommandBuffer(),
              let onscreenCommandEncoder = onscreenCommandBuffer.makeRenderCommandEncoder(descriptor: onscreenDescriptor) else {
            return
        }
       
        if let pipelineState = pipelineState {
            onscreenCommandEncoder.setRenderPipelineState(pipelineState)
            onscreenCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            onscreenCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }
        
        onscreenCommandEncoder.endEncoding()
 
        onscreenCommandBuffer.present(currentDrawable)
        onscreenCommandBuffer.commit()
        
    }
    
}
