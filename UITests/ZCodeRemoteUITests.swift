import XCTest

/// 端到端流程测试：添加连接 → 保存 → 进入连接页 → 退出回列表。
final class ZCodeRemoteUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddConnectBackFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET"]
        app.launch()

        // 1) 首页（干净状态）
        let add = app.buttons["home.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 10), "首页 + 按钮应存在")

        // 2) 添加连接
        add.tap()
        let field = app.textFields["add.urlField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "添加页输入框应存在")
        field.tap()
        field.typeText("https://example.com")

        let save = app.buttons["add.save"]
        app.swipeUp() // 确保保存按钮可见（小屏键盘遮挡时）
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()

        // 3) 列表出现连接卡片
        let card = app.buttons.matching(identifier: "home.card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5), "保存后列表应出现连接卡片")

        // 4) 进入连接页：浮动工具条出现（WKWebView 已挂载）
        card.tap()
        let back = app.buttons["connect.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 20), "连接页返回按钮应存在")

        // 5) 收起 → 展开工具条
        let collapse = app.buttons["connect.collapse"]
        XCTAssertTrue(collapse.waitForExistence(timeout: 5))
        collapse.tap()
        let expand = app.buttons["展开工具条"]
        XCTAssertTrue(expand.waitForExistence(timeout: 5), "收起后应出现展开小圆钮")
        expand.tap()
        XCTAssertTrue(app.buttons["connect.back"].waitForExistence(timeout: 5), "展开后工具条应恢复")

        // 6) 返回退出连接，回到列表
        back.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5), "退出后应回到列表")
    }

    func testMultiTabRailSwitching() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET"]
        app.launch()

        let add = app.buttons["home.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))

        // 添加两条连接（第一个标签 example.com，第二个 example.org）
        func addConnection(_ url: String) {
            add.tap()
            let field = app.textFields["add.urlField"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            field.tap()
            field.typeText(url)
            app.swipeUp()
            let save = app.buttons["add.save"]
            XCTAssertTrue(save.waitForExistence(timeout: 5))
            save.tap()
        }
        addConnection("https://example.com")
        addConnection("https://example.org")

        // 打开第一条（列表最新在上：example.org）
        let card = app.buttons.matching(identifier: "home.card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        let back = app.buttons["connect.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 20))

        // 左侧标签把手 → 展开标签栏 → 点击另一个标签原地切换
        let handle = app.buttons["rail.handle"]
        XCTAssertTrue(handle.waitForExistence(timeout: 5), "多连接时应显示左侧标签把手")
        handle.tap()
        let otherTab = app.buttons["rail.tab.example.com"]
        XCTAssertTrue(otherTab.waitForExistence(timeout: 5), "展开后应看到另一个连接的标签")
        otherTab.tap()

        // 切换后仍停留在连接页（未退出）
        XCTAssertTrue(app.buttons["connect.back"].waitForExistence(timeout: 10), "切换标签后应保持在连接页")

        // 返回列表
        back.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5), "退出后应回到列表")
    }
}
