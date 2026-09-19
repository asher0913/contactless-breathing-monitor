import XCTest
import AVFoundation
@testable import breathing // 确保这里的 breathing 是你的 app module 名称

class GaussianFilterTests: XCTestCase {

    var filter: GaussianFilter!

    override func setUpWithError() throws {
        // 在每个测试前初始化 GaussianFilter 实例
        filter = GaussianFilter()
    }

    override func tearDownWithError() throws {
        // 在每个测试后销毁实例，确保测试相互独立
        filter = nil
    }

    // 辅助方法：创建一个空的 CVPixelBuffer 作为测试输入
    private func createTestPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attributes as CFDictionary,
                                         &pixelBuffer)
        
        return (status == kCVReturnSuccess) ? pixelBuffer : nil
    }


    // 测试: 传入有效的 PixelBuffer，应该返回有效的 PixelBuffer
    func testApplyGaussianFilterWithValidInput() {
        guard let testPixelBuffer = createTestPixelBuffer(width: 100, height: 100) else {
            XCTFail("无法创建测试 PixelBuffer")
            return
        }
        
        let result = filter.applyGaussianFilter(depthImage: testPixelBuffer)
        
        XCTAssertNotNil(result, "当输入有效的 PixelBuffer 时，结果不应为 nil")
        
        // 验证输出 PixelBuffer 的尺寸是否与输入一致
        if let resultBuffer = result {
            XCTAssertEqual(CVPixelBufferGetWidth(resultBuffer), CVPixelBufferGetWidth(testPixelBuffer),
                           "输出 PixelBuffer 宽度应与输入一致")
            XCTAssertEqual(CVPixelBufferGetHeight(resultBuffer), CVPixelBufferGetHeight(testPixelBuffer),
                           "输出 PixelBuffer 高度应与输入一致")
            XCTAssertEqual(CVPixelBufferGetPixelFormatType(resultBuffer), CVPixelBufferGetPixelFormatType(testPixelBuffer),
                           "输出 PixelBuffer 格式应与输入一致")
        }
    }
}
