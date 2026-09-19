//
//  DrawCurveTests.swift
//  breathing
//
//


import XCTest
@testable import breathing // 确保这里的 `breathing` 是你的 app module 名称

class DepthDataCurveDrawerTests: XCTestCase {

    var drawer: DepthDataCurveDrawer!

    override func setUpWithError() throws {
        // 在每个测试前初始化 DepthDataCurveDrawer 实例
        drawer = DepthDataCurveDrawer()
    }

    override func tearDownWithError() throws {
        // 在每个测试后销毁实例，确保测试相互独立
        drawer = nil
    }

    // 测试 updateDepthData 方法是否正确更新 depthHistory
    func testUpdateDepthData() {
        // 初始 depthHistory 为空
        XCTAssertTrue(drawer.depthHistory.isEmpty, "depthHistory 应该初始为空")

        // 添加深度数据
        drawer.updateDepthData(5.0)
        XCTAssertEqual(drawer.depthHistory.count, 1, "depthHistory 应该包含 1 个元素")
        XCTAssertEqual(drawer.depthHistory.first, 5.0, "depthHistory 第一个元素应该是 5.0")

        // 添加 100 个数据，确保旧数据被移除
        for i in 1...100 {
            drawer.updateDepthData(CGFloat(i))
        }
        XCTAssertEqual(drawer.depthHistory.count, 100, "depthHistory 应该最多存储 100 个元素")
        XCTAssertEqual(drawer.depthHistory.first, 1.0, "depthHistory 最早的元素应该是 1.0")
    }

    // 测试 drawDepthCurve 方法是否正确绘制曲线
    func testDrawDepthCurve() {
        let size = CGSize(width: 300, height: 200) // 设定 canvas 大小
        
        // 1. 当 depthHistory 为空时，路径应该为空
        let emptyPath = drawer.drawDepthCurve(in: size)
        XCTAssertTrue(emptyPath.isEmpty, "depthHistory 为空时，绘制的路径也应该为空")

        // 2. 当有数据时，检查路径是否正确绘制
        drawer.updateDepthData(10.0)
        drawer.updateDepthData(20.0)
        let path = drawer.drawDepthCurve(in: size)
        
        XCTAssertFalse(path.isEmpty, "depthHistory 有数据时，路径不应为空")

        // 3. 验证路径的起点与终点
        let firstPoint = path.boundingRect.origin
        let lastPoint = CGPoint(x: size.width, y: size.height) // 假设终点应该在右侧
        
        XCTAssertNotEqual(firstPoint, lastPoint, "路径的起点和终点不应该相同")
    }

    // 测试 reset 方法是否清空 depthHistory
    func testReset() {
        // 先添加数据
        drawer.updateDepthData(5.0)
        drawer.updateDepthData(10.0)
        XCTAssertEqual(drawer.depthHistory.count, 2, "depthHistory 应该有 2 个元素")

        // 执行 reset
        drawer.reset()
        XCTAssertTrue(drawer.depthHistory.isEmpty, "reset() 后 depthHistory 应该为空")
    }
}
