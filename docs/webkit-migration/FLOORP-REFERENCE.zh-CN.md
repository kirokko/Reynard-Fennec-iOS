# Floorp 原生扩展实现参考记录

参考仓库：<https://github.com/Floorp-Projects/floorp-ios>

本轮获取 revision：`7070ffcc950a9f5a1695610a0f881ea71ed3322b`。
仅在工作区外检查，没有复制其源码、扩展包、UI 或架构进主项目。
根许可证及所读 Swift 文件注明 MPL-2.0；若后续复用代码，需保留相应许可/来源并检查具体文件义务，不能笼统当作无许可片段。

实际阅读：

- `FloorpNativeWebExtensionInstaller.swift` 全文件：由 WebKit 解包/解析，installer 负责大小/格式/digest、不可变 digest-addressed 包、registry 验证/原子保存及损坏隔离。
- `FloorpNativeWebExtensionAdapters.swift` 的 tab 适配开头：浏览器继续拥有自己的 Tab/WKWebView，adapter 持有弱引用和稳定身份，对每次操作检查 realm 权限。这一思路适合接到 Reynard 原有标签，不适合整体替换 UI。
- `FloorpNativeWebExtensionHost.swift` 的 controller/registry 初始化和 makeContext：稳定 context identifier/base URL、单独 private opt-in、grant/deny/expiry 持久化、错误通知。只读了相关段落，未声称完整审计 7,229 行 host。
- `docs/app-review-notes-native-webextensions.md` 全文及 `docs/floorp-ios-wkwebextension-native-replacement-design.md` 开头实现/问题记录。其文档是第三方自述，不是本项目已验证的结果。

重要区别：

1. Floorp 该 revision 的产品策略是**只内置两个受控扩展**，明确不提供任意 ZIP/XPI/URL/商店安装路径。它不能直接满足本任务的用户导入 Firefox XPI 目标，也不能把这个 App Review 策略误报为 iOS 所有侧载场景的系统禁令。
2. 它使用修改过的 Dark Reader 和 **uBlock Origin Lite**，不是完整 Firefox uBlock Origin。即使照搬成功，也不等于 uBO 兼容。
3. 它记录了 iOS 26.5 下 service worker cold start/idle wake、存储、popup close、DNR 等问题，并有特定包的派生补丁与 provenance。因此只看 `WKWebExtension` 能构造对象，不能承诺一般 Firefox 扩展稳定运行。
4. 本项目不采用它的白名单限制作为最终产品需求，不引入它的浏览器 UI，也不静默改写用户导入扩展来掩盖错误。若以后提供可选兼容转换，须明确显示原/派生包哈希、变化及限制，并保留原包和用户授权。

后续可参考的原则：稳定身份、WebKit 官方解析/执行、薄 tab/window adapter、逐操作私密检查、真实错误透传、不可变包与事务回滚。不能用几段 JS 同名 API 或少量 fixture 成功替代这些生命周期工作。
