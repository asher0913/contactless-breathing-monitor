import XCTest
@testable import breathing  // 导入目标模块，确保与你的项目模块名一致

class WeightedMovingAverageFilterTests: XCTestCase {

    var filter: WeightedMovingAverageFilter!

    override func setUpWithError() throws {
        // 在每个测试用例开始前初始化 WeightedMovingAverageFilter 实例
        filter = WeightedMovingAverageFilter()
    }

    override func tearDownWithError() throws {
        // 在每个测试用例结束后清理资源
        filter = nil
    }

    // 测试 1：验证滤波器的初始化
    func testInitialization() {
        // 获取窗口大小并验证
        let windowSize = filter.getWindowSize()
        XCTAssertEqual(windowSize, 5, "窗口大小应为 5")
        
        // 获取权重数组并验证
        let weights = filter.getWeights()
        XCTAssertEqual(weights, [0.1, 0.15, 0.2, 0.25, 0.3], "权重应为 [0.1, 0.15, 0.2, 0.25, 0.3]")
        
        // 验证数据数组初始为空
        let data = filter.getData()
        XCTAssertTrue(data.isEmpty, "数据数组应为空")
    }

    // 测试 2：验证数据添加和窗口管理
    func testDataAdditionAndWindowManagement() {
        // 添加少于窗口大小的数据点
        _ = filter.applyWeightedMovingAverage(depthData: 1.0)
        _ = filter.applyWeightedMovingAverage(depthData: 2.0)
        _ = filter.applyWeightedMovingAverage(depthData: 3.0)
        
        // 获取并验证数据数组内容
        let data = filter.getData()
        XCTAssertEqual(data, [1.0, 2.0, 3.0], "数据数组应为 [1.0, 2.0, 3.0]")
        
        // 添加超过窗口大小的数据点
        _ = filter.applyWeightedMovingAverage(depthData: 4.0)
        _ = filter.applyWeightedMovingAverage(depthData: 5.0)
        _ = filter.applyWeightedMovingAverage(depthData: 6.0)
        
        // 获取并验证窗口滑动后数据数组内容
        let updatedData = filter.getData()
        XCTAssertEqual(updatedData, [2.0, 3.0, 4.0, 5.0, 6.0], "数据数组应为 [2.0, 3.0, 4.0, 5.0, 6.0]")
    }

    // 测试 3：验证加权平均计算
    func testWeightedMovingAverageCalculation() {
        var average: CGFloat?
        
        // 添加第一个数据点并验证加权平均
        average = filter.applyWeightedMovingAverage(depthData: 1.0)
        // 计算：1.0 * 0.1 = 0.1
        XCTAssertEqual(Double(average ?? 0.0), 0.1, accuracy: 0.0001, "加权平均应为 0.1")
        
        // 添加第二个数据点并验证加权平均
        average = filter.applyWeightedMovingAverage(depthData: 2.0)
        // 计算：1.0 * 0.1 + 2.0 * 0.15 = 0.1 + 0.3 = 0.4
        XCTAssertEqual(Double(average ?? 0.0), 0.4, accuracy: 0.0001, "加权平均应为 0.4")
        
        // 添加第三个数据点并验证加权平均
        average = filter.applyWeightedMovingAverage(depthData: 3.0)
        // 计算：1.0 * 0.1 + 2.0 * 0.15 + 3.0 * 0.2 = 0.1 + 0.3 + 0.6 = 1.0
        XCTAssertEqual(Double(average ?? 0.0), 1.0, accuracy: 0.0001, "加权平均应为 1.0")
        
        // 添加第四个数据点并验证加权平均
        average = filter.applyWeightedMovingAverage(depthData: 4.0)
        // 计算：1.0 * 0.1 + 2.0 * 0.15 + 3.0 * 0.2 + 4.0 * 0.25 = 0.1 + 0.3 + 0.6 + 1.0 = 2.0
        XCTAssertEqual(Double(average ?? 0.0), 2.0, accuracy: 0.0001, "加权平均应为 2.0")
        
        // 添加第五个数据点并验证加权平均
        average = filter.applyWeightedMovingAverage(depthData: 5.0)
        // 计算：1.0 * 0.1 + 2.0 * 0.15 + 3.0 * 0.2 + 4.0 * 0.25 + 5.0 * 0.3 = 0.1 + 0.3 + 0.6 + 1.0 + 1.5 = 3.5
        XCTAssertEqual(Double(average ?? 0.0), 3.5, accuracy: 0.0001, "加权平均应为 3.5")
        
        // 添加第六个数据点，窗口滑动后验证加权平均
        average = filter.applyWeightedMovingAverage(depthData: 6.0)
        // 计算：2.0 * 0.1 + 3.0 * 0.15 + 4.0 * 0.2 + 5.0 * 0.25 + 6.0 * 0.3 = 0.2 + 0.45 + 0.8 + 1.25 + 1.8 = 4.5
        XCTAssertEqual(Double(average ?? 0.0), 4.5, accuracy: 0.0001, "加权平均应为 4.5")
    }
}
