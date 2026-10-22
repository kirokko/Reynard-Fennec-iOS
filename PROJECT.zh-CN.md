# ieynec（原 Reynard / Fennec iOS）改版记录

## 最新源码变更：视频对照、取消 JIT（新包尚待构建验收）

用户提供 Android / iOS 录屏及 Android 私密模式补拍视频，明确取消 JIT 功能，并再次要求去掉地址栏聚焦的原生过渡。新要求覆盖下面历史记录中“保留 JIT”的约定。

本轮源码：移除设置的 JIT 分组，旧开关强制失效；启动只保留向 Gecko 子进程回报无 JIT 状态的必要握手，不建立配对隧道、不下载 DDI、不启动调试或 JIT 后台音频。不擅自删除已有配对文件。旧 #7 IPA 未因此改变。

私密首页/总览使用深色和真实空态说明，不再显示普通品牌标题、捐赠 More；修正总览菜单、繁体中文、主页控件设置和地址栏/键盘布局的直接提交路径。标签切换不再等待异步首页预览完成，缓存小图标，关闭保护卡片时不遍历计算计数。保留 Gecko、扩展和版本基线，不改 SDK 缓存 key。

详细对照和未完成差异：[docs/VIDEO-REVIEW.md](docs/VIDEO-REVIEW.md)。书签/下载/历史深层页面并未全部复刻 Android，不能宣称全完成。无 JIT 原生性能优化也不代表补齐 JavaScript 性能差距。

最新工作路径：`C:\Users\Orie\Downloads\ieynec-项目\source`。下文旧下载路径/状态均为历史。当前可回滚完整 IPA 仍是 `ieynec-项目\IPA\current\ieynec-ui-fix.ipa`（#7）；本轮新 IPA 尚未交付。

## 历史状态

第一轮完整云端构建 #2 已成功，IPA 已交付，用户已在 iPhone 上安装并提供实际 UI 截图。用户确认第一轮仍太像 Reynard，要求整体按 Fennec 界面重做。当前第二轮源码已改名 **ieynec**，应用新图标并重排首页、菜单、标签与库页面；本轮完整编译和标准 IPA 打包已于构建 #3 成功，`Downloads\ieynec.ipa` 已下载核验；第二轮真机回归仍待用户安装后检查。安装成功不等于 JIT 或全部浏览功能已验收。

本地位置：`C:\Users\Orie\Downloads\Reynard-Fennec-iOS`。
公开仓库：https://github.com/kirokko/Reynard-Fennec-iOS
本地分支：`fennec-ios`。`origin` 是上游，`github` 是用户的公开仓库。

## 最新：界面、导航与无动画修正（构建 #7，待真机确认）

用户的新截图表明 #4 已能显示首页、网页及标签总览，但存在内容横向裁切、Continue 大块空白、总览分类图标不当，以及群组页缺少退出入口。用户再次强调不需要 App 自有过渡动画。用户照片只在本地查看，未提交。

本轮 App 源码 `39a3adf`，成功完整构建 #7：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39603345135 ，构建任务 28m19s。新包 `Downloads\ieynec-ui-fix.ipa`，SHA-256 `B322495A79600C75BAC0BDD381C4FE36C8A75D9837D89F75C7F021D1A26FF40A`。两项原有应用扩展仍在包内，技术标识、引擎及 JIT 流程不变，旧文件未覆盖。

- 首页宽度增加不可突破的 viewport 上限，防长 URL / 图片固有尺寸把内容撑出屏幕；Continue 图片压缩优先级降低、卡片有可随辅助字体增长的 88pt 优先高度，不再受整页缩略图原始高度支配。
- 隐私图标先按纵横比缩入 26pt 画布，不再用任意 imageEdgeInsets；普通标签计数改为方框内数字，移除 `▢ 2` 文本拼接。
- 独立页面的根返回入口在 init 后及 willShow 时确保存在；快速 push/pop 期间请求关闭会等 UIKit 生命周期完成，不添加自有动画；关闭恢复回调只触发一次。群组空态文字有边距和换行，删除后刷新空态。
- 删除旧总览的 phone/pad 缩放、弹簧、快照过渡实现，直接提交显示/关闭状态；进入总览不等待缩略图回调，过期回调不能重新打开已关闭总览。标签自动切换不再模拟滑动快照，类别切换直接执行。使用固定 false 的浏览器动画策略约束布局、工具栏 display link 和 collection 更新，原全局 UIKit 策略保留。网页与系统拥有的行为未改。

验证：11 项源码检查、分组 Foundation 测试、Swift 语法与完整 App 编译打包通过；Windows 6 项下载器隔离测试通过（新增跳过成功但无 IPA 的 UI-only run）。模拟器测试真实首页框架/卡片、群组列表和编辑器、导航控制器与总览 presentation 逻辑；首页数据库/引擎 sections、总览引擎和 collection/context 为替身，不是完整浏览器/Gecko/SideStore/JIT 端到端测试。

扩大测试覆盖 320/393/430/844/1024pt 宽度、长标题/URL、1800pt 高缩略图、More/隐私切换、群组编辑保存/子页返回/根页关闭与恢复回调、私密页不可进组，以及开启 UIKit 动画后反复 16 次总览打开/选中关闭/迟到缩略图，确保该路径无 layer animation 且内容 transform 为 identity。构建 #5、#6 被扩大测试拦截，未交付；调整关闭协调与测试对 UIKit 生命周期的等待后 #7 通过。

另完成 UI-only 实际屏幕复查：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39608419357 。初次实际截屏复查失败是冷 Simulator 的截图 IPC 超过 fixture 等待期限；延长测试端超时后重跑通过，没有为此修改 App。已下载并查看 simctl 实际屏幕图，确认群组返回箭头/加号为深色可见，分组空态/保存/关闭通过；普通 CALayer.render 导出将系统导航图标画成白色，不能当作实际屏幕颜色。该 UI-only run 不产 IPA，不能替代 #7 下载链接；后续 App 源码与 `39a3adf` 无差异。手动工作流新增可选 ui_checks_only，不增自动触发。

仍待用户覆盖安装后的完整浏览器回归；不以 fixture 截图（含灰色占位测试 sections）冒充完整首页验收。请安装新 `ieynec-ui-fix.ipa`，不卸载、不清数据、不改变 JIT，保留所有应用扩展。

## 历史：第二轮真机启动故障与 #4 修复候选

用户已安装 #3（构建号 `685b36a`），报告全白界面后退出；JIT 在前后两版均未开启，启动时连接 Wi-Fi 和 LocalDevVPN。设备日志确认 FRONTBOARD `0x8BADF00D`、`scene-create watchdog`，约 19.79 秒首界面创建超时，采样主线程处于 UIKit 自动布局/首帧提交，应用消耗约 19.6 秒 CPU。不是已确认的普通异常、内存终止或 JIT 失败。日志没有直接给出具体 Swift 源码行，不能宣称已经证明唯一根因。原始日志含设备/签名标识，仅本地使用，不上传仓库。

针对本轮布局风险的修复候选：
- 首页不再从 `viewDidLayoutSubviews` 回写必需宽度，移除初始 1pt 宽度，改成相对 scroll frame 的约束与最大宽度。
- More 下的固定高度子页面按需创建，收起时脱离 arranged hierarchy，不再把带必需高度的嵌套 UIStackView 隐藏成 0 高度。
- 没有可继续标签时，Continue 子树脱离布局，不再给 88pt 最小高度卡片施加隐藏 0 高度；相同内容刷新不重复改 UILabel / UIImage。
- Show all 的最小触控高度降为非必需优先级，以便隐藏时无约束冲突；移除工具栏隐藏的 arranged 加号。
- 新增 UIKit Simulator 首帧 smoke host，编译真实 homepage root / summary / theme / menu，数据库/引擎子页面为固定高度测试替身。测试覆盖空/有 Continue、反复展开收起 More、隐私切换。它不是完整 Gecko/SideStore/JIT 测试；runner 无已安装 iOS runtime 时明确报告未运行。

修复候选已在构建 #4 成功：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39594572656 ，源码提交 `185fef2`，构建任务用时 24m7s。11 项源码检查、分组持久化测试、Swift 语法检查通过；UIKit Simulator smoke host 实际运行并产生 PASS 标记（没有因 runtime 不可用而跳过）；完整 App 编译、标准 IPA 打包与上传成功，Gecko 缓存命中、引擎重编译跳过。

新包：`C:\Users\Orie\Downloads\ieynec-startup-fix.ipa`；对应来源记录：`.ipa.build.txt`；SHA-256：`9DFDDC157F9C483846AEF9AC5ED33B4065196A69C57CF38EDB377C25153E427B`。旧 `ieynec.ipa` 是已报告白屏的 #3，不应再作为推荐安装包；这次没有覆盖旧文件。

修复是否解决用户设备问题仍必须用新包覆盖安装验证，不能以源码检查或 smoke host 代替真机结果。保持 JIT、引擎、bundle identifiers 与用户数据不变。

## 固定基线

- Reynard 最新发布版：**0.18.0 alpha**。
- Git tag：`0.18.0`，commit `860bb6f4d0ff2b5d45f7dbe48eca8f39ee88a4fa`。
- 不自动合并 main/nightly，不自动升级 Gecko。
- UI 参考：F-Droid 推荐 **Fennec 158.0.0**，arm64 versionCode **1580020**。
- F-Droid 构建元数据 commit：`3b36d79f5e6e43779a0b661a34bc6b1ec30c8bcd`。
- 元数据指定的 Mozilla UI 源码 tag：`FIREFOX-ANDROID_158_0_RELEASE`。
- 目标设备：iPhone 17 / iOS 26.6 / SideStore。
- 详细参考来源：[docs/UI-REFERENCE.md](docs/UI-REFERENCE.md)。

注意：Mozilla 的 preferences.xml 也包含功能开关隐藏的选项，不能把其中所有条目都当成 F-Droid 实际显示的页面。官网截图可能独立更新，不能据此宣称已经精确还原最新版。

## 已确认的需求和差异处理

1. 保留 Reynard 的 Gecko、扩展、JIT 等功能，不换为 WebKit。
2. 浏览器 UI 和可对应的选项位置参照 Android Fennec。
3. 不制作“设为默认浏览器”选项。
4. JIT / 配对文件保留为“iOS / JIT”设置分组。
5. 无对应位置的兼容性、UA 和开发设置归入“高级 → Reynard 专属”。原有 Browsing 页也保留在此，避免丢失预览等选项。
6. 文件选择、分享、相机及系统权限等 OS 弹窗保留 iOS 原生 UI。
7. Fennec 有而 Reynard 没有实现的账号/同步、原生密码/银行卡管理、Collection 等入口不做假按钮、不空白占位，不把书签冒充同步/Collection。
8. Reynard 首页 JIT/性能建议移到 JIT 设置；其余专属内容放在首页“更多”中。
9. **应用更新全由用户手动维护**：移除原版应用更新源，不建立自动更新源，不计划定时构建/自动合并。保留扩展自身的原有更新行为。
10. 使用用户的 **公开 GitHub 仓库**进行手动云端构建，不使用付费的大型 runner，不收集 Apple ID、配对文件或签名私钥。
11. 新发现的功能/位置冲突仍应先告知用户，不能擅自删功能或以假设置替代。

## 第一轮实现

- 单行不透明工具栏：地址胶囊、新标签、标签数量、竖向三点菜单。
- 默认顶部地址栏；仍允许通过设置切换到底部。
- 自绘主菜单布局：收藏页面、页内查找、桌面版、扩展、可展开“更多”、书签/历史/下载快捷区、设置。
- 前进/后退、分享、刷新/停止移到菜单导航栏；长按历史导航和强制刷新仍有实际操作。
- 扩展按钮连接原有 AddonCoordinator，原生扩展管理仍使用 Reynard 实现。
- 标签页顶部隐私/普通分类；隐藏没有实现的同步分类。标题和关闭按钮移到卡片顶部，底部增加浮动菜单/新建按钮，保留批量关闭和按时间关闭。
- 设置按 Fennec 类别重新排序，新增 Tabs、Accessibility 入口承接 Reynard 已有的相关设置；未支持的 Fennec 项不显示。
- 首页保留快捷方式/浏览记录；最近关闭等额外内容折叠到“更多”。
- 浅色/深色 Material 风格配色，新 UI 的简体中文翻译。
- 第一轮应用显示名为 **Reynard Fennec**（第二轮改为 **ieynec**），源码链接指向改版仓库，上游作者与许可证保留。
- `BrowserUpdates` 保持原 API，但不联网、不提示安装原版、不删除手动下载的 IPA。
- 移除上游 nightly/release/source 自动工作流，仅保留手动 SideStore 构建及其复用工作流。

## 第二轮：截图驱动的界面重做（2026-10-21）

- 经用户授权重新核实 F-Droid 推荐版本，仍为 **158.0.0 / 1580020**，没有更新 Reynard / Gecko 基线。
- 用户提供 13 张对比图。照片仅本地参考，不上传公开仓库；第 8 张为黑屏，不能据此推断隐私主页布局。
- 用户明确暂不做不活跃标签归档／自动关闭；其他继续。新增本机标签组：引用真实普通标签 UUID，选择标签建组、重命名、增减成员、解散、从组切换到原标签。分组不复制页面、不冒充书签，不存隐私标签；无账号/同步。分组关闭页面后可重新打开，普通标签 ID 沿用原持久化。已关闭标签不作为有效成员展示。
- 应用显示名 **ieynec**，底层包标识不改。图标采用用户 PNG，1024px RGB、不透明，旧深色和着色图标移除；SVG 源稿保留。
- 首页改为居中 logo/标题、小圆形快捷方式、底部 Show all，以及连接真实已打开普通标签的纵向 Continue 卡片（没有可继续标签则隐藏）。常访、最近关闭、捐赠仍在 More 中。
- 首页跟踪保护按钮打开真实设置。计数仅在无障碍描述中标明当前普通标签的已知拦截数，不伪造 Fennec 的持久全局统计。
- 主菜单增加关闭手柄、白色卡片分组，History → Bookmarks → Downloads 顺序。原有导航、扩展、打印、缩放等路由保留。
- 工具栏移除冗余独立加号，保留标签长按菜单；标签托盘紧凑加号长按仍可恢复最近关闭标签。标签托盘为图标分类、白色卡片与紫色选中描边、搜索/菜单胶囊和紧凑加号。
- 手机的设置、书签、历史、下载不再共用底部 Library 标签栏/半屏 sheet，改为独立全屏页面；存储和操作仍接原实现。深层设置统一 plain 列表、字体/间距，系统文件/分享/权限弹窗不重写。
- App 启动关闭 UIKit 动画；菜单和自有全屏导航显式无动画；标签托盘走无动画状态分支，跳过插入占位，工具栏显示链补间直接到最终值。拖动/滚动的直接手势响应保留，不修改网页 CSS/JS 动画或系统进程动画。
- 新增 Foundation 分组存储测试，由 macOS Actions 在编译前执行。静态检查不等于触控/布局回归。

## 明确尚未完成的验收

目前是第一轮 UIKit 实现，不是 Android Compose 代码移植，也未声称全部页面像素级一致。深层设置、扩展管理、历史/书签等页面仍基于原版控件与交互，需要逐页对照微调。

尚需验证：

- 第二轮在 iPhone 上的安装与回归（完整 Xcode 编译与 IPA 打包在 #3 已通过）。
- iPhone 17 / iOS 26.6 真机上地址栏聚焦、键盘避让、横屏、深浅色、动态字体和 VoiceOver。
- 主菜单展开、关闭后触发分享/打印/扩展弹窗的时序。
- 普通/隐私标签切换、卡片缩略图动画、重排、关闭/恢复、历史跳转。
- Firefox 扩展安装、权限提示、弹窗与更新。
- SideStore 签名、应用扩展保留、冷启动、JIT 配对文件导入及启用。
- 对照目标 F-Droid 版本实际画面，检查首页、菜单、设置及深层页面的位置和视觉差异。

源代码测试在 `tests/source-policy.test.mjs`，检查字符串、手动更新策略、构建入口与关键操作路由。它们不是运行测试，不证明浏览器已经能在设备上正常使用。

## 构建和交付

Actions → **Build SideStore IPA (manual)** → Run workflow。
首次编译 Gecko 可能耗时数小时。构建会在编译 App 前缓存独立 Gecko SDK，以便修复 Swift 编译错误时尽可能复用引擎。缓存失效或被清理时仍需重编译。

成功后下载 **Reynard-Fennec-SideStore** artifact，其中是 `Reynard.ipa`。Downloads 中的手动下载工具可将最近一次成功的产物保存为 `Reynard-Fennec.ipa`；没有成功产物时应明确报错，不以原版 IPA 冒充成品。

首次构建：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39437471654 。该次运行通过源代码检查和 Swift 语法解析，Gecko 用时约 5 小时 40 分钟并已成功缓存，但在支持库编译阶段触及原先配置的 350 分钟任务上限，因此没有 IPA。

第二次构建：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39544125387 。已成功复用完整引擎缓存，跳过 Gecko 重编译，总用时约 16 分 23 秒，完成 App 编译、标准 IPA 打包和上传。该版本已安装；此处成功不代表后续第二轮 UI 改动也已通过编译。

第三次构建（第二轮 UI）：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39589249099 ，源码提交 `685b36afe334a7dc7c9b8a35931979e38786a4e8`。状态 **success**，构建任务用时 **16 分 29 秒**；Gecko SDK 缓存命中、引擎编译跳过，App 编译、标准 IPA 打包和上传成功。10 项源码检查、Swift 分组持久化测试及全部 Swift 语法解析均通过；本地 4 项下载器隔离测试通过。IPA 包内显示名为 `ieynec`，内部 bundle ID 不变，构建号 `685b36a`。

交付文件：`C:\Users\Orie\Downloads\ieynec.ipa`；来源和哈希：同路径 `.ipa.build.txt`。SHA-256：`B5060DC4103145CB260A0941B4B08B9EA461E2E6E1F12E96D935CCEFA9EE58E4`。两个应用扩展的 Info.plist 均在包中。旧 `Reynard-Fennec.ipa` 本次未覆盖。构建记录更新是文档改动，不需要再次编译。

`tools/Watch-Build.ps1` 是有时限的一次性收件脚本：只等指定的这一次运行，成功后下载对应 IPA，失败则写状态并退出。它不重试编译、不跟踪未来版本、不安装/更新应用，也不创建开机启动项或计划任务。状态文件为 Downloads 中的 `Reynard-Fennec-build-status.txt`。

本版沿用原始 bundle identifiers，避免引擎/helper 集成发生未经测试的变动。因此同一签名身份下可能覆盖原版 Reynard，不能保证与原版并存。测试前备份重要数据，不要为了测试随意卸载原应用。

SideStore 安装必须保留 App Extensions。浏览器已保留配对式内置 JIT，不需要为浏览器额外侧载 StikDebug。按上游指南连接 Wi-Fi、启用 App Store 安装的 LocalDevVPN、导入配对文件并在 iOS / JIT 中开启。LocalDevVPN 不占 SideStore 侧载名额。该能力不为 LiveContainer 内的其他 App 提供通用 JIT。安装不等于 JIT 已启用；配对文件属于敏感资料，不上传公开仓库或 Actions。上游指南：

- https://github.com/minh-ton/reynard-browser/issues/130
- https://github.com/minh-ton/reynard-browser/wiki/Manually-Enabling-JIT

发布 IPA 时应提供对应源码、引擎版本引用、补丁和构建说明，遵守根目录 GPLv3 与 Gecko 补丁 MPL2 许可证。
