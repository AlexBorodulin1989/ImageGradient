//
//  IGView.swift
//  ImageGradient
//
//  Created by Aleksandr Borodulin on 20/11/2018.
//

import UIKit

#if !targetEnvironment(simulator)
import Metal
#endif

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
        
        initMetalLayer()
        initData()
        do {
            try initPipeline()
            
            texture = try IGTextureMaker.createTexture(image: self.textureImage!, device: device)
            
            timer = CADisplayLink(target: self, selector: #selector(loop))
            timer.add(to: .main, forMode: .defaultRunLoopMode)
        } catch let error {
            print("Failed to create pipeline state with error: \(error)")
        }
    }
    
    private func initMetalLayer() {
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = pixelFormat
        metalLayer.framebufferOnly = true
        metalLayer.frame = self.layer.frame
        metalLayer.backgroundColor = UIColor.clear.cgColor
        self.layer.addSublayer(metalLayer)
    }
    
    private func initData() {
        let vertexData:[Float] = [
            -1.0, -1.0, 0.5,
            -1.0, 1.0, 0.5,
            1.0, -1.0, 0.5,
            1.0, -1.0, 0.5,
            -1.0, 1.0, 0.5,
            1.0, 1.0, 0.5
        ]
        
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
    }
    
    private func render() {
        autoreleasepool {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            guard let drawable = metalLayer.nextDrawable() else { return }
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            
            if let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setVertexBuffer(vBuffer, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                renderEncoder.setFragmentTexture(texture, index: 0)
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
