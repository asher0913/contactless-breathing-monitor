import XCTest
import AVFoundation
@testable import breathing  // 确保与目标模块一致

class PixelBufferCropperTests: XCTestCase {

    var pixelBufferCropper: PixelBufferCropper!

    override func setUpWithError() throws {
        // 初始化 PixelBufferCropper 实例
        pixelBufferCropper = PixelBufferCropper()
    }

    override func tearDownWithError() throws {
        // 清理资源
        pixelBufferCropper = nil
    }

    // 辅助函数：生成一个简单的 pixelBuffer 用于测试
    func createTestPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        
        // 创建一个空的 CVPixelBuffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         nil,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        // 锁定 base 地址
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        
        // 获取 pixel buffer 的 base 地址
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)!
        
        // 获取 bytesPerRow
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        // 填充 pixelBuffer 为测试数据（例如，填充每个像素值为不同的颜色）
        for y in 0..<height {
            for x in 0..<width {
                let pixel = baseAddress + y * bytesPerRow + x * MemoryLayout<UInt8>.size * 4  // 每个像素有 4 字节（BGRA）
                let color: [UInt8] = [UInt8(x % 256), UInt8(y % 256), UInt8((x + y) % 256), 255]  // 使用简单的颜色模式
                memcpy(pixel, color, 4)  // 使用 `memcpy` 复制颜色值到 pixel
            }
        }
        
        // 解锁 base 地址
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        
        return buffer
    }

    // 测试 1：验证裁剪函数
    func testPixelBufferCrop() throws {
        // 创建一个 10x10 的测试 pixelBuffer
        guard let originalPixelBuffer = createTestPixelBuffer(width: 10, height: 10) else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        // 定义一个裁剪区域（例如裁剪到 (2, 2) 到 (7, 7)）
        let cropRect = CGRect(x: 2, y: 2, width: 5, height: 5)
        
        // 使用 cropPixelBuffer 函数进行裁剪
        guard let croppedPixelBuffer = pixelBufferCropper.cropPixelBuffer(originalPixelBuffer, rect: cropRect) else {
            XCTFail("Failed to crop pixel buffer")
            return
        }
        
        // 获取裁剪后 pixel buffer 的宽度和高度
        let croppedWidth = CVPixelBufferGetWidth(croppedPixelBuffer)
        let croppedHeight = CVPixelBufferGetHeight(croppedPixelBuffer)
        
        // 验证裁剪后的尺寸是否与期望一致
        XCTAssertEqual(croppedWidth, Int(cropRect.width), "裁剪后的宽度应为 5")
        XCTAssertEqual(croppedHeight, Int(cropRect.height), "裁剪后的高度应为 5")
        
        // 你可以进一步验证裁剪后的像素数据是否正确，例如检查裁剪区域的像素值
        CVPixelBufferLockBaseAddress(croppedPixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(croppedPixelBuffer)!
        let bytesPerRow = CVPixelBufferGetBytesPerRow(croppedPixelBuffer)
        
        // 检查裁剪区域的像素值
        for y in 0..<Int(cropRect.height) {
            for x in 0..<Int(cropRect.width) {
                let pixel = baseAddress + y * bytesPerRow + x * MemoryLayout<UInt8>.size * 4
                var color = [UInt8](repeating: 0, count: 4)
                memcpy(&color, pixel, 4)  // 使用 &color 来传递到 `memcpy`
                // 可以添加检查像素数据是否符合预期的逻辑
            }
        }
        CVPixelBufferUnlockBaseAddress(croppedPixelBuffer, .readOnly)
    }
}
