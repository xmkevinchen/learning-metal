//
//  TriangleView.swift
//  LearningMetal (iOS)
//
//  Created by Kai Chen on 8/21/22.
//

import SwiftUI
import MetalKit

struct TriangleView: UIViewRepresentable {
    
    private let mtkView: MTKView = MTKView()
    
    func makeUIView(context: Context) -> MTKView {
        mtkView.enableSetNeedsDisplay = true
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        
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
