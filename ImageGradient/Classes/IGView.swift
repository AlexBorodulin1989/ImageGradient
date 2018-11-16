import UIKit

#if !targetEnvironment(simulator)
import Metal
import QuartzCore
#endif

class IGView: UIView {
#if !targetEnvironment(simulator)
    let pixelFormat: MTLPixelFormat = .bgra8Unorm
    
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    var vBuffer: MTLBuffer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    var timer: CADisplayLink! = nil
    
    struct RuntimeError: Error {
        let message: String
        
        init(_ message: String) {
            self.message = message
        }
        
        public var localizedDescription: String {
            return message
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        //self.backgroundColor = UIColor.blue
        
        initMetalLayer()
        initData()
        do {
            try initPipeline()
            
            timer = CADisplayLink(target: self, selector: #selector(loop))
            timer.add(to: .main, forMode: .defaultRunLoopMode)
        } catch let error {
            print("Failed to create pipeline state with error: \(error)")
        }
    }
    
    func initMetalLayer() {
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = pixelFormat
        metalLayer.framebufferOnly = true
        metalLayer.frame = self.layer.frame
        metalLayer.backgroundColor = UIColor.clear.cgColor
        self.layer.addSublayer(metalLayer)
    }
    
    func initData() {
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
    
    func initPipeline() throws {
        guard let bundle = Bundle(identifier: "org.cocoapods.ImageGradient"),
            let path = bundle.path(forResource: "default", ofType: "metallib")
            else { return }
        
        let defaultLibrary = try device.makeLibrary(filepath: path)
        let vertexFunction = defaultLibrary.makeFunction(name: "gradientVertex")
        let fragmentFunction = defaultLibrary.makeFunction(name: "gradientFragment")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add//MTLBlendOperationAdd;
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add//MTLBlendOperationAdd;
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha//MTLBlendFactorSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha//MTLBlendFactorOneMinusSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha//MTLBlendFactorSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha//MTLBlendFactorOneMinusSourceAlpha;
        
        try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    func render() {
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
