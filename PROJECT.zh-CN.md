# Reynard / Fennec iOS 改版记录

## 当前状态

这是开发中的源码，不是已完成并通过真机验收的浏览器。已实现第一轮界面修改，等待云端完整编译及设备测试。静态策略检查不能代替 Xcode 编译、模拟器或真机测试。

本地位置：`C:\Users\Orie\Downloads\Reynard-Fennec-iOS`。
公开仓库：https://github.com/kirokko/Reynard-Fennec-iOS
本地分支：`fennec-ios`。`origin` 是上游，`github` 是用户的公开仓库。

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
- 应用显示名为 **Reynard Fennec**，源码链接指向改版仓库，上游作者与许可证保留。
- `BrowserUpdates` 保持原 API，但不联网、不提示安装原版、不删除手动下载的 IPA。
- 移除上游 nightly/release/source 自动工作流，仅保留手动 SideStore 构建及其复用工作流。

## 明确尚未完成的验收

目前是第一轮 UIKit 实现，不是 Android Compose 代码移植，也未声称全部页面像素级一致。深层设置、扩展管理、历史/书签等页面仍基于原版控件与交互，需要逐页对照微调。

尚需验证：

- 完整 Xcode 编译与 IPA 打包。
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

第二次构建：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39544125387 。本次尝试复用完整引擎缓存，将任务上限调整到托管 runner 的 360 分钟，并移除任务名称中误导性的 TrollStore 字样。缓存是否命中、App 是否编译成功仍以该运行页面为准，不能仅凭有缓存就承诺成功或完成时间。

`tools/Watch-Build.ps1` 是有时限的一次性收件脚本：只等指定的这一次运行，成功后下载对应 IPA，失败则写状态并退出。它不重试编译、不跟踪未来版本、不安装/更新应用，也不创建开机启动项或计划任务。状态文件为 Downloads 中的 `Reynard-Fennec-build-status.txt`。

本版沿用原始 bundle identifiers，避免引擎/helper 集成发生未经测试的变动。因此同一签名身份下可能覆盖原版 Reynard，不能保证与原版并存。测试前备份重要数据，不要为了测试随意卸载原应用。

SideStore 安装必须保留 App Extensions。安装不等于 JIT 已启用；配对文件属于敏感资料，不上传公开仓库或 Actions。上游指南：

- https://github.com/minh-ton/reynard-browser/issues/130
- https://github.com/minh-ton/reynard-browser/wiki/Manually-Enabling-JIT

发布 IPA 时应提供对应源码、引擎版本引用、补丁和构建说明，遵守根目录 GPLv3 与 Gecko 补丁 MPL2 许可证。
