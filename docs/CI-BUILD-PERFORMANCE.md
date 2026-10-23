# SideStore Actions 优化与实测

## 范围与审计

在独立分支 `ci/sidestore-cache-optimization` 实施，基于
`5a77612abae8722b31272a627752e6116b5a71cd`；不修改 `browser/` 应用代码、工程、
Gecko patch、SDK 基线、动画、JIT 或扩展。没有新增 Workflow。

| 原工作流 | 保留用途与入口 |
|---|---|
| `build.yml` / Build Reynard | 原 `workflow_call`，保留 checkout_ref、nightly、normal IPA、TrollStore TIPA、jailbroken IPA 输入与产物；standard/nojemalloc 矩阵不变 |
| `build-sidestore.yml` / Build SideStore IPA (manual) | 原手动入口；默认 standard SideStore；`ui_checks_only=true` 仍强制执行 UIKit、无 IPA |
| `capture-protection-experiment.yml` | 完全不改；仍独立手动实验，本次没有触发 |

只补缺失控制：`test_strategy=auto/full/light`，默认 auto；`rebuild_native=true`
用于慢速原生源码恢复/验证，日常不启用。源策略/简繁、真实 Foundation 与全部 Swift
解析在三种测试策略下都必须通过，实际 Xcode archive 始终执行。

### 改动依据

- **不能直接跳过 Gecko 源码。** 原 SDK 只含 `bin/include`，`AddGecko.sh` 还需要
  `toolkit/mozapps/extensions/default-theme`。新 v2 SDK 包含主题、输入身份与逐文件
  SHA-256 清单，校验通过才跳过初始化/更新/补丁/编译。可迁移精确兼容的旧 v1：
  从固定 engine gitlink 获取主题，并校验 Git blob SHA；若主题被 patch 修改则拒绝
  迁移，真实源码构建。没有按宽泛前缀复用不兼容引擎。
- **idevice 原命中仍无条件 Cargo build。** 新缓存只保存实际预编译库与清单；键包括
  子模块 gitlink、Rust、Xcode/iPhoneOS SDK、平台和构建脚本。校验身份、SHA-256、
  arm64、非空 archive 后才免编译；失败走原真实 Cargo 构建。
- SDK 命中不再安装仅 Gecko 需要的 Homebrew 工具、恢复庞大 `.mozbuild` 或初始化
  Gecko；idevice 命中也不初始化其源码。普通 SideStore 不安装仅非普通包需要的 ldid。
  根仓库只浅取当前提交，发布脚本仅需 HEAD SHA，不依赖完整历史。
- 固定原来成功使用的 Xcode 26.6、Rust 1.99.1，而非每日跟随 Rust stable 变化。
- **只恢复 DerivedData 不够。** 实测 Swift 仍重编译。因此启用 Xcode 自带的 Swift/
  Clang CAS、显式模块和诊断；CAS 放在跨运行缓存的 DerivedData 内。Release `-O`/
  wholemodule 不改，源码不同仍正常重新编译。兼容前缀隔离工具链、SDK、native 输入、
  工程/脚本与 nightly；每次保存新快照。仅内容哈希相同的源码恢复旧时间戳。
  缓存快照约 216 MiB，恢复/保存时间计入表格，不是免费加速。
- 复用同一个 UIKit 脚本，不新建重复 UI Workflow。auto 的成功标记绑定工具链、夹具
  实际声明的 Swift 源码、fixture、资源和测试脚本；未编入夹具的浏览器路由修改不再
  重跑相同宿主。未知声明形式保守扩大范围。所有浏览器源策略/Swift 解析和 App 编译
  仍执行。full 强制重测；light 明确不跑 Simulator，不能伪称完整测试已执行。
- Simulator 提前发送异步 boot 请求，与独立夹具编译重叠；安装/启动前仍等待 bootstatus。
  慢速 native recovery 与普通 IPA 使用独立 concurrency group，不阻塞正常功能构建。
- **不缓存最终 IPA/xcarchive。** 每次清空 dist、新建 archive、写当前 SHA、重新打包。
  上传前校验 ZIP CRC、主 App 与两个扩展标识/构建号、Gecko/XUL/默认主题；额外提供
  `*.provenance.json`，含完整 commit 和 IPA SHA-256。失败摘要明确没有新 IPA。
  IPA 本身已压缩，上传 artifact 不再二次压缩。所有原 artifact 名称保留。

Xcode 缓存设置参考 Swift 官方实现（仅查阅，不引入代码依赖）：
[SwiftPM cache settings](https://github.com/swiftlang/swift-package-manager/blob/4caf32bf260fadbbe9b7f2155f1a58a444d20bf2/Sources/SwiftBuildSupport/BuildCacheConfiguration%2BSettingsOverrides.swift)、
[Swift build specifications](https://github.com/swiftlang/swift-build/blob/02d98b11db73d9a798c60d3f04444f0a904c1954/Sources/SWBUniversalPlatform/Specs/Swift.xcspec)。

## 已完成的实测（不是时间承诺）

Job 耗时含该 macOS Job 的收尾；“触发→可下载”从 workflow 创建到 Upload IPA 完成，
含排队/prepare；两者起止点不同，数值不能直接相减当收尾耗时。Agent 编写代码的时间
不在 Actions 指标中。

| Run | 场景 | Job | 触发→IPA 上传完成 |
|---|---|---:|---:|
| [#22 / 39767844014](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39767844014) | 用户指定原基线，Gecko SDK 命中 | 22:58 | 22:44 |
| [#29 / 39923535405](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39923535405) | v2 SDK 命中，idevice 二进制/Xcode 冷缓存；UIKit 复用 | 8:27 | 8:20 |
| [#30 / 39924880961](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39924880961) | 同 commit 暖缓存，尚未启用 compiler CAS | 4:01 | 4:05 |
| [#32 / 39926204311](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39926204311) | CAS 首次冷编译，UIKit 输入失效完整重跑 | 15:29 | 15:05 |
| [#33 / 39928185787](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39928185787) | CAS 暖缓存，同 commit 复测 | **2:23** | **2:27** |
| [#34 / 39928853833](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39928853833) | 新 commit、测试脚本变化，完整 UIKit；兼容 CAS 命中 | 11:00 | 10:42 |
| [#35 / 39930730750](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39930730750) | 最终 fixture 输入键首次建立，完整 UIKit；新 commit | 11:48 | 11:23 |

### 主要步骤（秒，跳过记为 —）

| 步骤 | 原 #22 | 冷 idevice/Xcode #29 | 暖、无 CAS #30 | 暖 CAS #33 |
|---|---:|---:|---:|---:|
| 必要检查 + UIKit | UIKit 单项 207 | 17，复用 UIKit | 13，复用 UIKit | 13，复用 UIKit |
| 初始化子模块 | 207 | 2，仅 idevice | — | — |
| 更新 Gecko / patch | 31 / 252 | — / — | — / — | — / — |
| idevice 编译 | 194 | 222 | — | — |
| App archive | 302 | 163 | 155 | **46** |
| Create IPA | 24 | 18 | 19 | 16 |

#33 相比原基线 Job 少 89.6%，但这是**同源码、有效暖缓存**，不是任意新功能修改都
需要 2:23。#34/#35 证明输入失效不会假装 UIKit 已测，也证明新 commit 重新打包后
三个 plist 使用新的构建号。它们没有改浏览器功能代码，不冒充真实 UI 功能改动基准。
完整 UIKit 在这些机器上耗时 6–9 分钟，Simulator/runner 波动明显；#34/#35 仍比原
约 23 分钟快，但不能用最短暖缓存数字掩盖该开销。

#30 仅恢复 DerivedData，App 仍耗 155 秒。#33 的日志真实出现 Swift/Clang
`replay cache hit`；App 降至 46 秒。并非把下载 cache 当成编译已命中。

### 失败记录与验证边界

首次 [#28 / 39921087887](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39921087887)
完成旧 SDK 迁移与真实 idevice 冷编译，但 lipo 验证参数顺序错误，失败且无 IPA。
已修正为 `lipo <archive> -verify_arch arm64`；#29 冷导出和 #30 二进制恢复均通过。
#28 不计为提速成功，也未用旧成功产物替代。

39 项 Node 源策略/简繁/缓存回归、真实 Foundation、Swift 解析、完整 UIKit、实际
Xcode archive/IPA 验证已实跑；actionlint 1.7.12 与 shell 语法检查通过。缓存测试
包含身份不符、内容损坏、缺失文件与源码字节变化；这些单元夹具不是 Gecko 编译。
normal IPA 是实际实测产物；其余保留模式经 actionlint/分支策略检查，本次不声称
重新完整编译过所有 TrollStore/jailbroken 组合。

## 日常 Agent 路径与缓存边界

见 [CI-AGENT-GUIDE.md](CI-AGENT-GUIDE.md)：普通修改默认只触发原入口一次，auto，
不额外触发无关实验/重复 UI-only，记录确切 run ID/commit，成功后核对 provenance
与下载 hash。失败报告实际错误，不取旧成功包冒充。

GitHub 缓存有分支作用域、容量淘汰和网络抖动。实验分支能读 default 的旧 SDK，
default 不能直接读取实验分支新缓存；合入后需真实预热，不能声称分支上 2:23 自动
代表首次 default 构建。原生输入变化、缓存失效或完整 UI/编译冷缓存都可能更慢。
不预设固定提速保证，不减少产品/扩展，不更改浏览器行为。
