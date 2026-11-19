# WebKit 重构：初步源码审计与迁移门禁

## 状态与范围（必须先读）

**这不是已经完成的 WebKit 浏览器，也不是可安装的重构 IPA。** 当前分支包含第一阶段的定向源码审计、原版基线、隔离的真实 WKWebView 适配模块及原生扩展探测。生产入口仍是 Gecko，阶段二至六尚未完成。没有用空实现冒充下载、权限、扩展管理或视频兼容。

- 原版源码：`14452d327bf08c6222567adfd308701cf9e16e15`。
- 重构分支：`refactor/webkit-migration`。
- 备份 tag：`backup/gecko-before-webkit-14452d3`。
- 665 个原有 browser/、.github/、tools/release/ 文件的 SHA-256 基线：`baseline.json`。文本忽略 Windows CRLF 差异，二进制精确比较。
- `node tools/ci/WebKitBaseline.mjs` 核验生产源码/资源未变，只允许这阶段的手动 workflow 入口变化。此门禁以后需要随正式集成显式调整，不能把初期“文件未变”当作最终浏览行为一致。
- 本轮实际阅读了下面列出的关键源码及构建配置；**未逐行完成整个仓库、所有补丁和所有深层 UI 的人工审查**。完整审计仍是后续集成前提，不能把 grep/哈希清单说成已经人工阅读全部源码。
- 历史文档中“保持 Gecko/无 JIT”的旧约定被本次 WebKit 需求取代；现有 UI、名称和数据保留要求仍有效。实际展示名为 `ieynec`，不是擅自改回 Reynard。

## 1. 已确认的依赖边界

| 子系统 | 已阅读的源码依据 | 迁移影响 |
|---|---|---|
| 入口/初始化 | `browser/Reynard/main.swift`、`browser/GeckoView/Runtime/GeckoRuntime.swift` | 入口调用 GeckoRuntime.main，不是 UIApplicationMain；现存 sandbox SPI、Gecko 子进程/JIT 握手不能带入最终公开 API 版 |
| 页面视图 | `Client/Interface/ContentView/WebContentView.swift`、`browser/GeckoView/Session/GeckoSession.swift` | UIView 包装 GeckoView；视图布局不能删除；底层 session、输入、缩略图、刷新、滚动接口需逐项适配 |
| 标签 | `Client/TabManagement/Tab.swift`、`TabManagerImpl.swift` 的恢复路径 | 每个 Tab 强类型持有 GeckoSession；SessionManager 创建、激活、解绑所有代理；不能靠改一个 import 完成 |
| 会话 | `SessionManagement/SessionManager.swift`、`GeckoSessionState.swift` | 多代理事件、表单/滚动和 JSON 历史状态；WK 不接受 Gecko 的 opaque state |
| 扩展 | `GeckoView/Addons/AddonRuntimeCommands.swift`、`Interface/Addons/AddonCoordinator.swift` | 安装、启停、更新、权限都走 Gecko runtime 事件；动作、popup、options、下载和 tab 激活不能只换 manifest 解析器 |
| 扩展设置页 | `Interface/Library/Settings/Sections/General/Addons/AddonsPreferencesViewController.swift` | 已有 Installed/Unsupported、AMO、文件安装和更新入口；保留控制器/布局，替换服务层 |
| 阅读模式 | `SessionManagement/ReaderMode/ReaderModeController.swift` | 依赖 `readerview@mozac.org` 内建扩展及 native ports；引擎换掉会失效，不能漏掉或删掉按钮 |
| 权限 | `SessionManagement/Coordinators/PermissionCoordinator.swift` | 当前把原站点偏好写入 Gecko 权限系统；WK 相机/麦克风/定位/自动播放并非同一权限接口 |
| 下载 | `Interface/Coordinators/DownloadsCoordinator.swift`、`Stores/DownloadStore.swift` 的存储定义 | 已有确认队列和文件/记录；WKDownload 应交回这些 UI/记录，不能另建 Downloads 界面 |
| 隐私/清理 | `GeckoView/Controllers/GeckoStorageController.swift`、`Stores/SitePermissionStore.swift` 的存储定义 | Gecko flags 不能原样映射 WKWebsiteDataStore；必须区分 Cookie、缓存、history、auth、DOM storage 的真实支持范围 |
| 偏好 | `Preferences/RuntimePreferences.swift`、`FennecMediaPolicy.swift` | HTTPS-only、DoH、ETP/GPC、UA、远程调试及特定站点媒体策略不能静默变成无效开关 |

全仓 Swift 搜索发现 **77 个含 Gecko 引用的应用 Swift 文件**（`browser/Reynard` 范围，不含 GeckoView 模块）。这是静态耦合规模，不是迁移完成数量。

### UI 与手势基线

已有 `docs/UI-REFERENCE.md`、`docs/VIDEO-REVIEW.md`、`PROJECT.zh-CN.md` 和 `tests/ui-layout-smoke/`。本轮读取了视频回顾、中文项目记录相关部分及 `tools/Test-HomepageLayout.sh`。原测试很多使用引擎/数据库替身，不是浏览器 E2E。

WebContentView 的下拉刷新依赖 `GeckoInputHandling`、scrollableEdges、overscrollAxes 来判断网页是否消费手势；工具栏依赖 APZ compositor 的位置采样和触摸序列。不能用定时器或任意 JS scroll listener 声称完全等价。应保持 ToolbarController、BottomToolbar、AddressBar、菜单、托盘等现有视图，给 UIScrollView 的拖拽/惯性/缩放重新建立映射，并测网页内部滚动容器、fixed 页脚、键盘和底部手势区。

新模块放在 `browser/WebKitEngine/`，**不在现有 Reynard 同步编译组内**，没有改变 production pbxproj。独立测试由 swiftc 编译同一源码。没有引入 Floorp、Safari、Telescopure UI 或第三方代码。

## 2. WebKit、JIT 与 sing-box

`WebKitSession.swift` 目前真实实现：WKWebView、导航/刷新/停止、KVO 状态、前进后退、关闭、导航错误/进程退出事件、普通/私密数据容器、popup 配置边界。它没有伪装成完整 GeckoSession。

- 普通模式使用 default persistent WKWebsiteDataStore。
- 一组私密标签显式共享同一个 nonPersistent store；新私密会话组使用新 store。
- popup 必须属于同一 profile，保留 WebKit 提供的 configuration，默认不创建 popup。
- 不启动任何调试、配对、VPN、ptrace、idevice、DDI 或 app 自有 JIT。
- WKWebView 的网页 JS 在系统 WebKit 进程运行，由系统管理 JIT；不需要为 app 获得可执行内存 entitlement。执行 `21 * 2` 只证明 JS 可执行，**不证明 JIT 在某台手机已启动**，系统 lockdown 等策略仍可能限制 JIT。
- sing-box/蜂窝网络影响的是网络路径，不是这个模块的 JIT 激活流程。没有要求关闭 sing-box、Wi-Fi 或电脑。**本轮无法访问手机，该实际网络组合待实机验证**，不能保证所有 VPN 路由和 DNS 配置都正常。

## 3. 原生 WebExtensions 可行性

上游公开头文件：

- https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebExtension.h
- https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebExtensionContext.h
- https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebExtensionController.h

上游声明最低 iOS 18.4。不能把 WebKit/main 头文件当成实际 Apple SDK：`Test-WebKit.sh` 会归档所选 iphoneos SDK 的四个真实头文件、哈希和 Xcode/SDK 版本，并实际编译 arm64 对象；随后用 UIKit App 在 Simulator 初始化、load、执行、unload。

### 探测范围

两个自写 fixture（没有复制第三方扩展）：

1. MV2 非持久 scripts 后台。
2. MV3 service worker 后台。

真实链路：原生解析 manifest → 设置固定 localhost/storage 测试权限 → controller load → 启动后台 → WKWebView 内容脚本 → `browser.runtime.sendMessage` → 后台 `browser.storage.local.set/get` → 内容脚本修改 DOM → 原生读取结果 → unload。

报告分别记录 parse、load、background、timeout 和 runtime errors。原生不兼容是**探测结果**，不能抹去；workflow 绿色只代表编译及 WK 核心门禁通过，不代表扩展 fixture 或 Firefox 生态通过。具体结果单独见 `RESULTS.zh-CN.md`。

### 尚未核实/尚未实现的部分

- `.xpi`/ZIP 用户导入、安全解包、AMO 网络安装、稳定扩展身份、权限 UI 桥接、enable/disable/update、持久恢复和升级事务。
- 目标 iOS + SideStore 的实际 provision/sign 后 controller load。模拟器不需要设备签名，不能用于推出侧载 entitlement 一定通过。
- `browser.*` 不等于 Firefox 所有 API；Gecko-only 实现（例如特定实验 API）不能靠创建同名 JS 对象补齐。
- `webRequest`/阻断、DNR 规则/配额、Firefox 特有过滤语法、后台生命周期、native messaging 必须做各自测试，当前无兼容承诺。
- **uBlock Origin 未安装、未运行、未做拦截验证，不标记兼容。** 不可将 uBO Lite 或 WKContentRuleList 说成完整 uBO 的等价替代。
- Floorp 仅是允许参考方向；本轮未引入其代码，也未完成 Floorp 实现/许可证审计。

## 4. 视频与方向控制

已阅读 `FennecFullscreenRotation.swift` 和 `BrowserViewController.swift` 的 `applyFullscreenState`、`updateFullscreenOrientation`、方向锁/geometry 请求路径。

原实现：

- 全屏先 `.portrait`。
- 原应用自己的 44pt 左下角按钮（leading 12、safe bottom -56）。
- CMMotionManager 每 0.25s 采样；两个稳定样本、0.65 阈值及 0.15 死区，跟随左右横屏。
- 非全屏/失活停止采样，错误反馈避免过期 geometry 回调。
- 原版退出恢复**进入前方向**，不是无条件竖屏；本次新要求“退出竖屏”与原代码有差别，需要在正式适配时明确改为竖屏并回归。

WK 内嵌视频可配置 inline/PiP；HTML Fullscreen API 的 app-owned 内容路径可以复用上述按钮/控制器。WebKit 原生视频全屏控制器不是 app 的公开可编辑按钮树；公开 API 不提供随意替换其左下角内部按钮/全套控制栏的方法。不能用遍历私有类/selector 挂钩冒充合规实现。

**本轮没有迁移视频全屏事件，没有接入方向控制，也没有复刻系统播放器。** DRM、跨域 iframe、网站专用播放器不能笼统抽取 URL 后交给 AVPlayer；这样会破坏 MSE/EME、凭据、广告逻辑和同步。优先保留 WebKit 原始解码/DRM，再评估仅可控内容的自定义容器；必须给系统全屏路径明确限制。

另有公开 API 约束冲突：原 UI 的 `UIGlassEffect+Private.swift` 调用 glass/setAdaptive:/effectWithGlass:，第三方 `BlurFilterProvider.swift` 发现/调用 CAFilter。最终要求若覆盖整个 app，不能只移除 Gecko 就声称纯公开 API；替换视觉效果也可能影响 UI 基线，需逐屏比对，不能悄悄删除。

## 5. 数据审计与安全边界

| 数据 | 原存储/源码 | 初步处理 |
|---|---|---|
| 书签 | Application Support/AppData/Bookmarks，BookmarkStore SQLite | 原库原路径保留；无需转成 WebKit 的数据 |
| 历史 | AppData/History，HistoryStore SQLite | 保留应用自己的库，重新接入 WK 导航事件 |
| 标签/缩略图 | AppData/TabManagement/TabManagement 和 ThumbCache，TabManagementStore SQLite | 保留 ID/排序/分组；禁止先清空再重建 |
| 历史回退链 | AppData/TabSessions/<UUID>，NavigationHistoryStore Codable | 原 app 已有 backList/forwardList/currentID/ownsNav，可承接跨引擎 URL 级恢复 |
| Gecko session JSON | GeckoSessionState，TabManagerImpl.prepareRestoration | `history.index` 为 1-based；Gecko principal/docshell/form/scroll 不可直接写入 WK |
| 站点权限/设置 | AppData/SitePermissions、SiteSettings SQLite | 不删除旧 raw values；需建立 WebKit 支持能力映射和无效权限提示 |
| 下载 | Documents/Downloads；AppData/DownloadStore manifest | 文件和记录原样保留；临时 Gecko external-response 处理待迁移 |
| Cookie/DOM/扩展数据 | Gecko profile 管理；GeckoStorageController/AddonRuntime | 尚未完成 profile 文件路径、SQLite/IDB/扩展 UUID 映射的完整审计；不得假设能把 Gecko IDB 文件交给 WK |
| 偏好 | BrowserPreferences/原应用设置 | 不改键、不清除；Gecko-only 偏好不能假装已生效 |

`LegacySessionProjection.swift` 是**只读、未接入生产**的 URL/title/history 级投影：校验 1-based index，拒绝 private、非 HTTP(S)、凭据 URL 和坏数据，不复制表单/密码/POST/principal。不自动丢条目导致 index 位移。输出不能填充原生 WKBackForwardList，后续须由原应用历史管理；不是“完整会话无损迁移”。

原仓已记录私密 URL/title 落入 tab DB 的隐私风险。不能擅自清旧私密数据；也不能把 nonPersistent Cookie 测试说成已经修复应用的私密记录持久化。

## 6. 构建审计

实际阅读：`project.pbxproj`、`Configuration/Reynard.xcconfig`、两条 build workflow、`tools/release/build-app.sh`、`create-ipa.sh` 和 `docs/CI-AGENT-GUIDE.md`。

- 原最低 iOS 13；Xcode 26.6、macos-26；Release arm64 archive → 无签名构建 → IPA → SideStore 重签。
- 主 app、GeckoView framework、Gecko Helper、OpenIn 四 target；app/GeckoView/Helper 链接 XUL、mozglue、NSS、codecs 等，Copy Gecko Stuff 注入运行时。
- SDK/idevice 有完整性检查的缓存；不应为改 Swift UI 重新编译 Gecko。最终移除需连同 target、bridge、build phases、link/rpath、SDK/cache/tools、Helper/XPC 一起核对，不能只删 submodule。
- OpenIn 是用户功能，不是 Gecko 子进程，最终应保留。create-ipa.sh 当前硬编码检查 Helper，正式删除 Gecko Helper 时必须同步改 verifier/provenance/打包，不能让旧脚本通过假 appex 蒙混。
- 本轮在**已有手动入口**新增 `webkit_checks_only=true`；默认原 IPA 工作流不变。独立探测不恢复/构建 Gecko，不上传假 IPA，不更新 Release。

## 7. 后续阶段的硬门槛

1. 完成人工审计剩余代理、UI/资源、数据 writer、SDK/补丁和隐藏功能；给每个原功能建立迁移测试项。
2. 原 UI 后接入 WKSession 事件与 UIScrollView 手势、下载/权限/打印/reader；不能简单删除不编译的方法。
3. 用实际 SDK 与侧载设备确认原生扩展可用后，接入原 Addon UI，安全导入、持久权限/身份、更新回滚，再测真实 Firefox 扩展。
4. 验证 HTML fullscreen/系统播放器两条路径，复用方向 controller 并明确系统不可控部分。
5. 备份事务成功且恢复验证后，才能对真实用户库启用迁移；故障时旧资料仍可由 Gecko 打开。
6. 全功能/视觉/数据回归通过后，才移除 Gecko 并改生产 archive/IPA verifier。最后实测包体、启动/内存/网页时间，不把 smoke app 的大小或耗时当浏览器性能。
