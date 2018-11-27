//
//  IGView.swift
//  ImageGradient
//
//  Created by Aleksandr Borodulin on 20/11/2018.
//

import UIKit
import simd

#if !targetEnvironment(simulator)
import Metal
#endif

struct Vertex {
    var x, y, z: Float!
    var s, t: Float!
    
    func floatBuffer() -> [Float] {
        return [x, y, z, s, t]
    }
}

class IGView: UIView {
    
    private var textureImage: UIImage?
    
    @IBInspectable var image: UIImage? {
        get {
            return textureImage
        }
        set {
            if self.textureImage == nil && newValue != nil {
                self.textureImage = newValue
                initialize()
            }
        }
    }
    
#if !targetEnvironment(simulator)
    private let pixelFormat: MTLPixelFormat = .bgra8Unorm
    
    private var device: MTLDevice! = nil
    private var metalLayer: CAMetalLayer! = nil
    private var vBuffer: MTLBuffer! = nil
    private var pipelineState: MTLRenderPipelineState! = nil
    private var commandQueue: MTLCommandQueue! = nil
    
    private var timer: CADisplayLink! = nil
    
    var texture: MTLTexture!
    var samplerState: MTLSamplerState!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //initialize()
    }
    
    private func initialize() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        do {
            initMetalLayer()
            initData()
            try initPipeline()
            try initResources()
            
            timer = CADisplayLink(target: self, selector: #selector(loop))
            timer.add(to: .main, forMode: .defaultRunLoopMode)
        } catch let error {
            print("Failed to initialize with error: \(error)")
        }
    }
    
    private func initMetalLayer() {
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = pixelFormat
        metalLayer.framebufferOnly = true
        metalLayer.frame = self.layer.frame
        metalLayer.backgroundColor = UIColor.clear.cgColor
        metalLayer.isOpaque = false
        self.layer.isOpaque = false
        self.layer.addSublayer(metalLayer)
    }
    
    private func initData() {
        var vertexData = [Float]()
        vertexData.append(contentsOf: Vertex(x: -1.0, y: -1.0, z: 0.5, s: 0.0, t: 1.0).floatBuffer())
        vertexData.append(contentsOf: Vertex(x: -1.0, y: 1.0, z: 0.5, s: 0.0, t: 0.0).floatBuffer())
        vertexData.append(contentsOf: Vertex(x: 1.0, y: -1.0, z: 0.5, s: 1.0, t: 1.0).floatBuffer())
        vertexData.append(contentsOf: Vertex(x: 1.0, y: -1.0, z: 0.5, s: 1.0, t: 1.0).floatBuffer())
        vertexData.append(contentsOf: Vertex(x: -1.0, y: 1.0, z: 0.5, s: 0.0, t: 0.0).floatBuffer())
        vertexData.append(contentsOf: Vertex(x: 1.0, y: 1.0, z: 0.5, s: 1.0, t: 0.0).floatBuffer())
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: .storageModePrivate)
    }
    
    private func initPipeline() throws {
        guard let bundle = Bundle(identifier: "org.cocoapods.ImageGradient"),
            let path = bundle.path(forResource: "default", ofType: "metallib")
            else {
                throw RuntimeError("Cannot create library path")
        }
        
        let defaultLibrary = try device.makeLibrary(filepath: path)
        let vertexFunction = defaultLibrary.makeFunction(name: "gradientVertex")
        let fragmentFunction = defaultLibrary.makeFunction(name: "gradientFragment")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        self.isOpaque = false
    }
    
    private func initResources() throws {
        texture = try IGTextureMaker.createTexture(image: textureImage!, device: device)
        
        let samplerDesc = MTLSamplerDescriptor()
        samplerDesc.sAddressMode = .clampToEdge
        samplerDesc.tAddressMode = .clampToEdge
        samplerDesc.minFilter = .nearest
        samplerDesc.magFilter = .linear
        samplerDesc.mipFilter = .notMipmapped
        samplerState = device.makeSamplerState(descriptor: samplerDesc)
    }
    
    private func render() {
        self.isOpaque = false
        autoreleasepool {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            guard let drawable = metalLayer.nextDrawable() else { return }
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            
            if let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.setRenderPipelineState(self.pipelineState)
                renderEncoder.setVertexBuffer(self.vBuffer, offset: 0, index: 0)
                
                renderEncoder.setFragmentTexture(self.texture, index: 0)
                renderEncoder.setFragmentSamplerState(self.samplerState, index: 0)
                
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                
                renderEncoder.endEncoding()
                
                commandBuffer?.present(drawable)
                commandBuffer?.commit()
            }
            
            timer.isPaused = true
        }
    }
    
    @objc func loop(displaylink: CADisplayLink) {
        self.render()
    }
#endif
}
