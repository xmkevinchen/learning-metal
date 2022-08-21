//
//  TriangleView.swift
//  LearningMetal
//
//  Created by Kai Chen on 8/20/22.
//

import SwiftUI
import MetalKit

struct TriangleView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> MTKView {
        mtkView.enableSetNeedsDisplay = true
        return mtkView
    }
    
    private let mtkView: MTKView = MTKView()
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        
    }
    
    class Coordinator: NSObject {
        
        private let render: Renderer
        
        init(_ parent: TriangleView) {
            self.render = Renderer(view: parent.mtkView, device: MTLCreateSystemDefaultDevice()!)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}


struct TriangleView_Previews: PreviewProvider {
    static var previews: some View {
        TriangleView()
    }
}
