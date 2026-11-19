# 完整版 uBO → WebKit：非官方移植实验

## 状态：有真实网络拦截的原型，不是已完成的浏览器

用户已授权尝试移植，工作位于独立分支 `port/full-ubo-webkit`。没有改动默认稳定分支、已有 Release 或生产用户数据；生产浏览器仍是原 Gecko 实现，本原型尚未接入其 UI/TabManager。

**使用官方完整版 Firefox uBlock Origin 1.76.4 源码，不是 uBO Lite。也不是官方 XPI 原样运行或完整 Firefox API 等价兼容。** 新增了 WebKit 声明式网络后端，平台能力上限不会因为用了完整版源码就消失。

核心已实测：由完整包自带的解析器/编译器生成规则，通过真正的 WebKit 原生 DNR 阻止网页请求。不是 DOM 隐藏，也不是返回假成功的 `webRequestBlocking` shim。

## 实现位置与源码来源

- `ports/ublock-webkit/`：平台 overlay、worker、编译边界、明确的源码补丁。
- `tools/ublock/prepare.py`：先核对官方 XPI 的固定 SHA-256，再受限解压、移除失效的 Mozilla 签名、记录源文件哈希和补丁。
- `tools/ublock/test-prepare.py`：真实暂存逻辑的完整性/现有目录保护测试。
- `tools/ublock/test-compiler.mjs`：实际完整版模块的编译集成测试和真实内置列表审计。
- `tests/webkit-smoke/UBlockPortProbe.m`：独立 UIKit/WKWebView 原生宿主。
- `tools/ci/Test-UBlockPort.sh`：arm64 编译和 Simulator 实际运行。

固定输入和许可证见 `tests/webkit-smoke/ublock-package.json`；输入哈希：
`66d0e3f21ce3b32b1bc0a9399b93cb2c9aa598ef18805d92118c76f66e266c1e`。

完整包的 `js/static-dnr-filtering.js` 确实可作为平台无关模块使用。它与其他上游项目共享代码，但本实验不下载/安装/重命名 Lite。保留上游过滤引擎、原始内容脚本、popup/dashboard 及资源；仅对 `patches.json` 列出的5个共享JS文件做显式适配，原HTML/CSS不改。每个修改文件保留前后哈希，其他原文件逐个核对。

改过 manifest 和源码后，原 Mozilla 签名不再有效，因此明确删除 `META-INF`，包名注明 unofficial research port。GPL许可证、上游版权声明和可重建补丁均保留。不把派生包宣称为官方签名版本。

## 后端工作方式

1. 在独立 module Worker 中调用完整版原始 parser/compiler，不另写简化 ABP 解析器。
2. 保留上游生成的条件、action 和 priority；移除的只是 `__important` 等非 DNR schema 的编译注解，不丢弃其真实优先级。
3. 原始转换错误和每条外观/scriptlet/HTML/响应头规则的处置都写入报告。
4. 使用原生 `updateDynamicRules` 一次替换规则集，读取完整结果校对；结果不符则尝试恢复之前的集合。原生拒绝不会被当成成功。
5. 当前仅桥接 `user-filters`。原版完整列表、白名单、动态防火墙等尚未接入这个后端。
6. 单独启动原版 `js/start.js`，观察实际初始化和原版内容脚本，不给缺失的浏览器权限/API造成功对象。

**DNR API 中的“dynamic rules”指可更新的声明式规则，不等于 uBO 的动态防火墙/动态 URL 过滤已移植。**

## 当前测试与边界

最终代码：`3e2dc16f7fc601cc24ec76d7923481cd29c5aed7`。
本轮最终实验：<https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/44516894753>。

最终run成功完成，精确headSha已核对。网络后端的三项gate通过；原版后台和scriptlet明确未通过，不能将绿色扩展为完整版验收。以下结果以最后一次运行为准：

| 能力 | 目前证据 |
|---|---|
| 普通网络阻断 | blocked请求失败，服务器未收到该请求；control正常200 |
| 例外规则 | 相同目标有block与allow规则时，按上游priority允许 |
| important | important block优先于普通例外，目标被阻止 |
| 请求类型 | image-only规则不阻止Fetch，但阻止真正的图片；控制PNG加载成功 |
| 原生非法更新 | 非法ID批次被拒，旧规则读回未变；不是磁盘故障/进程崩溃回滚验收 |
| 存储变更后的重编译 | 新目标先200，写入user-filters并触发重编译后被阻止 |
| 原版弹窗 | 第3次已显示1.76.4、站点及原控件；不等于控件都已连到DNR |
| 完整后台初始化 | **未通过**：initialization-timeout，readyToFilter虽true但完成时间仍为占位符?；JS错误明确保留 |
| 原版外观过滤 | **本fixture warm页通过**：原版引擎使.port-ad的computed display为none，诊断脚本没有添加隐藏CSS；不代表完整程序化外观过滤覆盖 |
| 原版scriptlet | **未通过**：测试常量未出现，Firefox browser.contentScripts.register接口缺失 |
| 内置完整列表 | 仅转换审计，不是安装或真实站点验收 |
| SideStore、真机、冷启动、私密模式 | 未验证 |

存储测试同时存在显式诊断重编译调用，因此证明“存储写入＋重编译＋生效”，**不能单独证明只有onChanged事件就足以完成全链路**。自动事件链需独立测试。

最终本地/CI检查包括原44项源码策略和3项新增回归（共47项Node测试）、3项暂存测试、9项完整版编译集成检查。原有23项WK集成检查在先前检查点通过；本分支没有重新把那23项当成新的浏览器完整验收。

内置 `assets/ublock/filters.min.txt` 在当前明确记录的环境下生成3,821个候选网络规则，并记录2,005个转换错误条目、17,439个非网络条目。**这些候选没有在本原生fixture里安装；数量不是兼容比例，也不是逐条一一映射。** 原始完整审计在Actions artifact，源码/输入/工具可复现，不能把候选数量写成“已支持3,821条”。

## 已修正的探测问题及适配记录

历史原始JSON不覆盖，保存在 `evidence/<run>/`。

- `44511620934` / `113644a`：原生DNR网络、非法替换保留旧集、存储重编译通过；原后台卡在未绑定receiver的 `vAPI.getURL`，弹窗使用了不适合extension URL的普通配置。
- `44513530642` / `b24c100`：确认直接调用有URL、脱离receiver调用为undefined；真实转发修复。弹窗改用公开 `context.webViewConfiguration` 后加载，但暴露空i18n ID错误；后台缺失 `webNavigation.onCreatedNavigationTarget`。
- `44515122413` / `27f41bd`：原版弹窗显示版本和站点；后台缺 `requestIdleCallback`，WASM相对路径因后台位于port子目录而错误。**该轮探测错误地把默认 `allReadyAfter='?'` 当作完成时间，raw stage ready并不成立，review.json已明确更正为未完成。** 完整兼容标记始终为false。
- `3e2dc16`：就绪需真实时间值、无观察到的错误；新增回归测试。加入实际执行工作的、5ms协作预算的定时调度fallback（不是原生idle时间/性能保证），修正资源base，重新测warm页面内容脚本。

缺少navigation-target事件时使用真正的 `tabs.onCreated` 和已知openerTabId，不杜撰sourceFrameId；iframe来源相关popup过滤未等价实现。规则变更通知调用真实DNR重编译，而不是伪造 `browser.webRequest.handlerBehaviorChanged` 空函数。空翻译ID仅保留空标签；非空ID错误不吞掉。

## 仍未解决，不能发布为日用完整版

- 原版popup电源/白名单、动态防火墙、动态URL规则与DNR不同步。**即使UI看起来正常也不能让用户以为开关已生效。**
- 默认列表选择、订阅更新与原生后端尚未连通；当前只使用人工合成user-filters。
- scriptlet的Firefox `contentScripts` 注册、MAIN/ISOLATED世界、CSP、iframe及首次导航需独立移植验证，不能用DOM隐藏替代。
- HTML响应正文过滤、CNAME解析/连接结果的一致性、Firefox逐请求任意决策仍受公开API限制。
- 重定向、头部修改、regex方言及完整日志尚未完成原生行为对照。
- 背景休眠/恢复、首个请求、普通/私密隔离、升级回滚、生产数据及性能均未验收。

暂存引导故意在一次性CI身份中写入合成测试配置，**不能挂载到真实用户扩展数据，更不是生产XPI安装器**。自动授予权限仅用于哈希固定的可信测试包；不是任意用户扩展权限策略。

最后一次额外定位到两项实际JS错误：`browser.contentScripts.register` 缺失，以及上下文菜单的 `abp:*` targetUrlPatterns 被WebKit判为非法。不能通过造contentScripts空函数、删掉订阅功能或忽略错误来宣称初始化完成。框架context.errors为空不代表JS后台无错误；两条JS错误在port.errors中单独保留。WASM资源路径错误在本轮不再出现，但没有因此宣称已证明WASM/JIT性能。

原生宿主只用公开API，没有Gecko、私有WebKit钩子、自行激活JIT或额外VPN。localhost服务只是CI受控请求目标，不是要用户在手机运行的网络代理。模拟器成功不能冒充SideStore签名后的实际设备成功。

## 下一步顺序

1. 根据原始错误完成原后台/原内容引擎的平台适配；优先审计并实现公开API下的脚本注册与世界隔离，不造contentScripts空对象。
2. 对只有onChanged的事件更新、默认列表/更新、站点开关、例外及持久化建立真实端到端测试。
3. 明确动态过滤、HTML、CNAME等不能等价覆盖的能力，不把部分移植重新标为完整版。
4. 再接入现有浏览器UI/标签体系、生成明确标注的实验IPA，最后才做SideStore真机验收和独立第二项目发布。

复现入口：

```sh
gh workflow run build-sidestore.yml --ref port/full-ubo-webkit -f ublock_port_checks_only=true
```

最终验收标记仍为 `fullUBlockOriginVerified: false`、`sideStoreVerified: false`。绿色仅表示声明的网络后端必要条件/探测完成，不能当作完整版浏览器交付。
