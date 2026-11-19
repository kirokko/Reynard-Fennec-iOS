# WebKit 重构检查点：实测报告

## 完成程度

**未完成用户要求的全面重构。没有新的 WebKit 浏览器 IPA。生产 app 仍从 GeckoRuntime.main 启动。**

| 阶段 | 本轮交付 | 未完成 |
|---|---|---|
| 一：审计/可行性 | 关键源代码定向审计、665-file 基线、原版 fixture 截图、SDK 与 runtime 探测、Floorp 参考 | 全仓逐行人工审计、SideStore 实机 API/签名验证 |
| 二：架构迁移 | 独立 WKSession/profile 真实实现、23 项运行检查 | 接入原 UI/TabManager；下载、权限、弹窗 UI、reader/打印、历史/书签写入等完整适配 |
| 三：扩展 | 原生 MV2/MV3 fixture 探测（不是产品扩展管理系统） | 任意 XPI 导入、管理/升级/持久权限、真实 Firefox 扩展兼容、uBO |
| 四：视频 | 确认原控制器可复用及系统播放器公开 API 限制、具体测试清单 | WK 全屏事件接入、原按钮/横竖屏/DRM/跨域/PiP 回归 |
| 五：回归/性能 | 原44项 Node检查、源/资源基线、旧 IPA 校验 | 浏览器 UI/实机功能和前后性能对比 |
| 六：清理/IPA | 保留旧源码/config、可回滚包和既有工作流 | 移除 Gecko、生产 WebKit archive/IPA 和 SideStore 设备验收 |

没有为编译通过而增加假的 GeckoSession 替身/空成功回调，没有复制 Floorp UI，没有清库/更新稳定 Release。

## 本地与原版验证

- Windows：`node --test tests/*.test.mjs`，**44/44 通过**。
- `node tools/ci/WebKitBaseline.mjs`：原 browser 源码/资源/config 不变；仅原手动 workflow 的 opt-in 探测入口有变化。
- `bash -n tools/ci/Test-WebKit.sh`、`git diff --check` 通过。
- 原版 IPA 从 run `40082560152` 下载，独立 SHA-256 与 provenance 一致。
- 原 app Mach-O header 检查：magic `feedfacf`、CPU type `0x0100000c`（arm64），主执行文件 `6414160` bytes。ZIP 中保留 GeckoView framework、OpenIn 和 Gecko Helper；这是原版备份，不是假称已清 Gecko 的新包。

## 实际 CI 工具链

从第一次探测 artifact 读取：

```text
Xcode 26.6
Build version 17F113
iphoneos SDK 26.5
```

两组源码都实际通过 iPhone arm64 编译门禁，随后运行 Simulator app。Swift 模块 emit-module 和 Objective-C 对象编译不等于完整浏览器 archive/link/sign。

原生 WebExtensions 最低 API 的实际 SDK 声明、SDK 头文件 SHA-256 均归档在每次 `webkit-feasibility` artifact，而不是只依赖 WebKit/main。

## 探测历史（不隐藏失败）

### 第一次：`85454f1`

<https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/44494356525>

- 编译成功并实际运行。
- WK 多项基本检查通过，但 stop 用例在只观察到初始 isLoading、异步 policy 尚未完成时调用停止，随后等待超时。改用真正已提交的慢速流式响应测试，不伪造 loading 状态、不修改 stop 为无效果成功。
- 两个 manifest 被实际 SDK 报告缺少 description；此时没有继续标记安装成功。补齐 fixture 后复测。
- Job 失败，不生成 IPA。

### 第二次：`f2fdec0`

<https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/44496349797>

- 44项原 Node 回归和基线通过。
- `WebKitSmoke.json`：**23 项通过，failures 为空**。
- 实际覆盖：URL/title、WebKit JS 执行、前进/后退、刷新、新 document、实际在途停止、close、拒绝 closed session load、普通 persistent store、私密 nonPersistent store、Cookie roundtrip/普通与新私密容器隔离、跨 profile popup 拒绝、旧 Gecko 扩展 URL 拒绝；以及5组只读旧会话转换/坏数据/私密与不安全 URL 拒绝测试。
- **ExtensionProbe 超时，没有完成扩展验收，整体 Job 失败。** 此时没有完整的 phase 结果，不能归因成已证明的 iOS service worker 禁令。
- 下一版增加全链路45秒 watchdog、过期 callback 防护，并在原生背景启动前建立 normal WKWebView/tab/window 与 controller 数据容器。普通探测不再使用默认禁止扩展访问的私密网页容器。

### 第三次：`501dee1`

<https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/44498435298>

**探测门禁成功，Job 6m44s**，headSha 已核对为 `501dee1672e8f5450b5d1d2387aa5894b2e7bfe5`。最终文档提交不改该次通过的代码/测试/工作流。

- 44项 Node 检查、原版源码/资源基线通过。
- iPhone arm64 源码编译通过，WK Simulator 运行 **23 项通过，failures 为空**。
- **MV2 非持久 scripts fixture**：原生解析/load、后台启动、内容脚本、`browser.runtime.sendMessage`、`browser.storage.local.set/get` 和 unload 完整往返成功；`context.errors` 为空。
- **MV3 service worker fixture 未通过**：原生解析/load 后，在 `background` 阶段45秒仍没有完成回调，记录 `native-callback-timeout`；随后正常 unload。没有假定安装成功或输出 Firefox 兼容。
- `extension-verdict.json` 明确 `fixturesPassed: false`、`sideStoreVerified: false`、`uBlockOriginVerified: false`，CI 发出 warning。绿色只代表探测流程完成和 WK 核心门禁通过。
- 仍有 linker `using sysroot for MacOSX but targeting iPhone` 警告，实际 app 可在 iOS Simulator 启动；不是零警告/完整生产 archive 验证。

原始 JSON、工具链和 SDK 头文件哈希保存在 `evidence/44498435298/`；完整 artifact 包含真实 SDK 头文件和日志。早先失败 JSON 也保存在 evidence，不覆盖历史结果。

**阻塞解释与合规方向：** 已确认的只是该 SDK/Simulator/最小 fixture 的 native background completion 不返回，不能凭45秒超时断言 Apple 永久禁用所有 MV3 worker。Floorp 同 SDK 代际的公开记录也有 cold-start/idle-wake 问题，但不替代本项目根因诊断。可继续利用已跑通的原生非持久 scripts/event-page 路径研究显式、可回滚的兼容转换；不能静默把任意 worker（可能依赖 worker/global/fetch 生命周期语义）改成页面并声称无损。当前只验证 MV2 fixture，没有实现/验证通用 MV3 转换，更没有私有 API 或假 background shim。

## 原生扩展兼容矩阵

| 能力 | 当前结论 |
|---|---|
| WKWebExtension/Context/Controller 编译、构造、原生 manifest 解析 | 已在所选 SDK 编译/运行；不是 SideStore 签名证明 |
| MV2 scripts 后台 → 内容脚本/消息/存储 | 最小 fixture 完整往返通过、runtime errors 为空；不能推及所有 MV2 |
| MV3 service worker 后台 → 内容脚本/消息/存储 | 未通过：background callback 超过45秒未返回；不能推及所有 MV3 或所有设备 |
| 用户 XPI、AMO 导入/更新/卸载管理 | 尚未实现，不冒充 fixture 是安装管理系统 |
| Firefox 专属 API、webRequest 阻断、DNR | 未完成具体兼容测试 |
| uBlock Origin | 未安装/运行/拦截验证，**不标记兼容** |
| 普通/私密扩展权限/后台数据隔离 | 未完成产品实现与验收；Cookie隔离通过不等于扩展隔离通过 |
| SideStore 重签后原生 extension load | 待实机验证 |

测试脚本会单独保存 `extension-verdict.json`，原生 fixture 失败会有 warning。绿色流程表示 WK 核心 gate/探测流程本身完成，**不自动等于 Firefox 扩展兼容**。

## 视频与性能报告

视频播放器/方向迁移**尚未实施/运行测试**。已确认原版的 portrait-first、左下角旋转按钮、Core Motion 死区/双样本、geometry 请求与退出回原方向的源码，见 AUDIT。系统播放器内部按钮没有已验证的公开改造路径，不声称完全复刻。

实际可比较的旧版数据：

| 指标 | Gecko 原版 | 完整 WebKit 浏览器 |
|---|---:|---:|
| IPA（非 artifact ZIP） | 106,814,569 bytes | 未生成 |
| 原成功 CI build job | 15m15s（已有缓存） | 未测 |
| 原 archive 步骤 | 5m51s | 未测 |
| 真机冷/暖启动、页面时间、标签切换、内存/能耗 | 本轮未测 | 未测 |

原时间来自 run `40082560152` 的步骤时间，不是本轮重新测量的冷构建。不拿小型 smoke app 体积/耗时和原完整浏览器相比，不给出没有测量依据的提速/体积下降百分比。

## 安全与回滚

旧包 `../IPA/rollback/gecko-14452d3/Reynard.ipa` 已校验；tag `backup/gecko-before-webkit-14452d3` 已推送。旧 Gecko profile、应用库和下载文件均未修改。**尚未备份手机沙盒数据，也没有实现生产迁移事务**，不能据此保证未来升级无损。

具体测试步骤、升级/失败恢复与签名身份注意事项见 `DEVICE-TESTS.zh-CN.md`。蜂窝 + sing-box、系统 JIT 策略、扩展侧载和视频/旋转都明确为「待实机验证」。
