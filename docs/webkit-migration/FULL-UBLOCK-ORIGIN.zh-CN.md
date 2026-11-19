# 完整版 uBlock Origin：不可用 Lite 替代的能力门槛

## 用户要求与发布门槛

本轮明确要求完整版 Firefox uBlock Origin，不接受 uBO Lite。没有将 Lite、DNR 白名单或单纯 DOM 隐藏冒充完整版，也没有因为要发布第二个项目就降低要求。

**没有发布“完整 uBO WebKit 浏览器”的 Release/IPA，也没有把未完成的分支重新包装成完成品。** “完成后作为第二项目发布”的前提尚未满足；当前诊断仍在隔离重构分支。新建 fork 本身不会改变 iOS/WebKit 提供的网络 API。

## 官方完整版包（不是第三方修改版）

- 上游：`gorhill/uBlock`，release `1.76.4`。
- 文件：`uBlock0_1.76.4.firefox.signed.xpi`。
- 下载：<https://github.com/gorhill/uBlock/releases/download/1.76.4/uBlock0_1.76.4.firefox.signed.xpi>
- 大小：6,332,093 bytes。
- SHA-256：`66d0e3f21ce3b32b1bc0a9399b93cb2c9aa598ef18805d92118c76f66e266c1e`。
- 本地独立校验与 GitHub release asset 的 `digest` 一致。
- Manifest V2，ID `uBlock0@raymondhill.net`，后台为 `background.html`，popup 为 `popup-fenix.html`。
- 必需权限含 `webRequest`、`webRequestBlocking`；另有 dns/publicSuffix/privacy 等权限。并非每项缺失都会使 uBO 完全不能启动，但**网络阻断缺失直接影响核心能力**。

CI 下载后只将外部文件名改为 `.zip` 以交给官方 WKWebExtension 解析，所有包内容和哈希不变。第三方包不提交到本仓库；遵守原包 GPL，不修改或重新签名声称是官方兼容版本。

## 根本 API 差异的源码证据

核对的 WebKit upstream revision：`f32f24bc7251eb561f65943d6f59c77827c97d53`。

[WebExtensionAPIWebRequestEventCocoa.mm](https://github.com/WebKit/WebKit/blob/f32f24bc7251eb561f65943d6f59c77827c97d53/Source/WebKit/WebProcess/Extensions/API/Cocoa/WebExtensionAPIWebRequestEventCocoa.mm)

- `addListener` 保留的 extraInfo 只有 `requestBody`、`requestHeaders`、`responseHeaders`，`blocking` 被移除。
- `invokeListenersWithArgument` 只调用 listener，没有把 `{cancel: true}` 返回值用于取消请求。
- 因此 API/event 存在或 listener 调用成功，不等于 Firefox 的同步阻断语义可用。

反观官方 XPI 中的 `js/vapi-background.js`，`vAPI.Net` 在 HTTP(S) 的 `onBeforeRequest` 注册 `[ 'blocking' ]`，并把过滤结果返回给浏览器。另有相同阻断接口保护扩展自己的 web-accessible resources。没有这一引擎层能力，显示 popup、更新列表或隐藏广告元素，仍不等于完整网络过滤体验。

上游源码不是所选 Apple SDK 的二进制证明，所以增加了实际运行诊断，不能只根据 WebKit/main 宣布结论。

## 可复现诊断（不把探测当成已支持）

代码：

- `tests/webkit-smoke/FullUBlockProbe.m`
- `tests/webkit-smoke/blocking/`
- `tests/webkit-smoke/ublock-package.json`
- `tools/ci/Test-WebKit.sh`

测试分开两件事：

1. **完整版官方 XPI 的原生解析**：记录版本、manifest、权限和所有原生错误。没有执行完整 uBO 后台/界面，绝不将解析成功算作完整兼容。
2. **最小原生阻断能力**：MV2 测试扩展注册真正的 `webRequest.onBeforeRequest` `['blocking']` listener，对 `/blocked.txt` 返回 `{cancel:true}`。网页 world（不是 extension-origin）依次请求 control 和 blocked 两个唯一 URL，记录服务器响应、callback 观察次数、错误及能力查询。

只有 control 成功、target 被阻止且 listener 实际观察到 target，才可能通过这个**必要条件**。即使通过，仍不能证明完整版 uBO 已经通过。

为避免仅凭 parser 的 unsupported 警告漏掉真实行为，**诊断 fixture** 会保留警告并尝试运行；这不是生产安装策略，也没有把未知权限假装授予成功。所有实际结果都写进 JSON。

本轮 Actions：<https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/44500800485>

### 实际结果

该作业成功完成，代码 headSha 已核对为 `518cff7a0ba9593a26cfa1e5ec12145fa753dfdc`。绿色仅表示诊断顺利执行，**完整版 uBO 必要能力未通过**，日志有明确 warning。

| 项目 | 实测 |
|---|---|
| 官方完整版解析 | 名称 uBlock Origin，版本1.76.4，MV2；不是 Lite |
| 官方后台 manifest | 报错：iOS/iPadOS 要求 non-persistent background；另有 commands 解析错误 |
| 官方包原生识别权限 | 含 webRequest，但没有 webRequestBlocking、dns、publicSuffix、privacy |
| 最小 fixture 的 blocking listener 注册 | 没抛异常，原生 context.errors 为空 |
| listener 是否收到目标请求 | **收到1次**，执行了 `{cancel:true}` 返回 |
| control 请求 | 正常 HTTP 200 |
| 应当取消的 target 请求 | **仍 HTTP 200 且正文读取得到**；服务器日志也记录了请求 |
| 原生 filterResponseData | `undefined` |
| 原生 dns.resolve / publicSuffix | `undefined` |
| 完整版 uBO 验收 | **未通过**；官方包没有执行，未做完整 UI/列表/实际广告站点测试 |

最关键的结论不是“没检测到 callback”或“一次超时”，而是 callback 确实执行且注册不报错，**取消返回值没有阻止网络请求**。这和已核对的上游实现一致。在该实际 SDK 的公开 API 路径下，不能把 listener 可调用宣称为 Firefox 阻断兼容。

JSON 原件与受控服务器日志：`evidence/44500800485/`。工具链仍为 Xcode26.6、iphoneos SDK26.5；Simulator 结果不冒充 SideStore 真机验证，但缺少公开阻断能力也不是重签即可补齐。

只修改官方 manifest 为非持久后台，最多绕开第一个解析错误，并不会让被忽略的取消返回值生效，因此不把这类修改称为“完整移植完成”。

## 为什么不采用“看起来一样”的替代

- `declarativeNetRequest` / WKContentRuleList 可以覆盖部分过滤需求，但不是让 uBO 的每个请求决策、动态过滤和所有 Firefox 特有能力原样运行的通用替代。
- JavaScript 中造一个同名 `webRequestBlocking` 对象不能阻止已经发出的网络请求。
- WKNavigationDelegate 不能作为所有网页 subresource 的通用 Firefox webRequest 替代。
- 单独创建新仓库、改扩展名、通过 SideStore 重签或给 app 开 JIT，都不会补出系统 WebKit 缺少的网络阻断返回通道。
- 不使用私有 WebKit API、HTTPS 拦截代理/额外 VPN、越狱或 Gecko 视频后端绕过本任务约束。

## 后续用户已授权的移植实验

本页记录的是官方XPI原样兼容的诊断，不是对后续所有移植工作的最终判断。用户随后授权尝试移植：独立分支 `port/full-ubo-webkit` 已实现真实静态网络DNR后端，并实测原版基础外观过滤和原版弹窗；后台完整初始化、scriptlet及关键控制桥接尚未完成。它使用完整版源码但不是完整Firefox行为等价版，不是Lite替换，详见 `UBLOCK-PORT.zh-CN.md`。

## 后续可选方向，不暗中替用户更改条件

1. 若坚持当前 WebKit + 官方公开 API + 完整 uBO 的全部核心行为，需要 Apple/WebKit 提供并验证足够能力；不能承诺仅靠本项目改代码即可实现。
2. 若优先完整 Firefox uBO，可考虑保留 Gecko 的独立衍生项目，但这会改变“完全移除 Gecko”的要求，必须得到用户明确授权；同时仍需实测扩展和网络/JIT条件，不能自动等同于 Safari 系统 JIT。
3. 若继续 WebKit，只能明确列出部分兼容范围；这不是用户本轮要求的“完整版体验”，因此不擅自采用，也不发布为完整版。
