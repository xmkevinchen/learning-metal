//
//  MetalView.swift
//  LearningMetal
//
//  Created by Kai Chen on 8/25/22.
//

import SwiftUI
import MetalKit

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
#else
typealias ViewRepresentable = UIViewRepresentable
#endif

struct MetalViewRepresentable: ViewRepresentable {
    
    @Binding var mtkView: MTKView
    
#if os(macOS)
    func makeNSView(context: Context) -> some NSView {
        mtkView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
    
#else
    func makeUIView(context: Context) -> some UIView {
        mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
#endif
    
}

struct MetalView: View {
    
    @State private var mtkView = MTKView()
    @State private var renderer: Renderer?
    var body: some View {
        MetalViewRepresentable(mtkView: $mtkView)
            .onAppear {
                // TODO: Have better error handling
                do {
                    renderer = try Renderer(view: mtkView)
                } catch {
                    print("====> Failed to create renderer: \(error)")
                }
            }
    }
}

struct MetalView_Previews: PreviewProvider {
    static var previews: some View {
        MetalView()
    }
}
