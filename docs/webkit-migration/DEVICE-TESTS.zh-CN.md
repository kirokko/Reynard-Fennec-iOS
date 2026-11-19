# 验收、备份、升级与回滚清单

**全部设备项目当前均为「待实机验证」。现在不要把重构分支当作已完成的 WebKit 浏览器安装。**

## A. 本轮可重现命令（Windows，无需本地 Xcode）

```bash
git switch refactor/webkit-migration
node tools/ci/WebKitBaseline.mjs
node --test tests/*.test.mjs
gh workflow run build-sidestore.yml --ref refactor/webkit-migration -f webkit_checks_only=true
```

按触发时间和精确 headSha 找到 run，下载 `webkit-feasibility`，检查
`WebKitSmoke.json` 的 failures 和 `ExtensionProbe.json`/`extension-verdict.json`。
**此选项不生成浏览器 IPA**；默认原 SideStore IPA 流程仍构建 Gecko。
不能把默认流程生成的 Gecko IPA 交作 WebKit 版本。

## B. 原版备份

- 源码/config：远端 tag `backup/gecko-before-webkit-14452d3`。
- 原版成功 run：<https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/40082560152>。
- 本轮下载的原版 IPA：工作区外 `../IPA/rollback/gecko-14452d3/Reynard.ipa`。
- 大小 `106814569` bytes。
- SHA-256：`d35fce4cb6409bb962cf35239a8d8dd7b9071712184b2589de305627beb21fe5`。
- provenance 原件：`gecko-ipa.provenance.json`，含主 App/OpenIn/Helper 的 build/identifier。
- 本轮用 `sha256sum` 独立核对下载文件，和原 provenance 一致。这是**回滚包，不是本轮新构建包**。

Git tag 和 IPA 都不包含用户数据。浏览器沙盒数据尚未从手机备份，本轮无权宣称已有可恢复的手机数据备份。

正式升级前须先建立并验证用户数据备份：通过可用的系统/设备备份或明确实现的应用内导出，保留 Application Support、Documents、Preferences、Gecko profile 及扩展存储。SQLite 必须在写入停止/一致快照下连同必要 WAL 数据备份，不能在运行中随便复制主数据库后说是完整备份。密钥链、文件保护、容器身份也需验证。

应用内原子备份/迁移事务**尚未实现**。不得先写 migration-success 标记，不得清 Gecko profile，不得用“安装成功”代替数据可读验证。

## C. 正式实现后的升级/失败恢复顺序

1. 记录旧 app build、SideStore 重签后的标识/Team、原包哈希和备份位置。
2. 导出/备份并用副本验证书签/历史/标签/下载文件数、校验和和扩展设置。可用系统备份是否覆盖该侧载容器需实际核对。
3. 新包必须通过 archive/IPA 架构、依赖、签名/entitlement 检查后，使用相同身份覆盖安装；不要先卸载旧版。
4. 迁移只读旧数据、写版本化新位置，验证成功后才切换。旧数据保持不可变；Cookie/IDB/扩展存储若无法转换，应显示具体不可转换项，保留原件。
5. 新版异常时停止继续写入，不清库；保存可脱敏日志。确认旧库未变后，SideStore 用备份旧 IPA 覆盖回滚，保持同一签名身份。签名身份变化可能生成独立容器，不能承诺“任何重签都自动保留数据”。
6. 若后续发生共享 app 库 schema 升级，必须先提供 down-migration 或旧库副本恢复。当前分支没有改 schema，所以暂不存在这种升级。

重建原版源码：

```bash
git switch -c recovery/gecko backup/gecko-before-webkit-14452d3
# 如要重新云编译，从该 ref 调用原手动工作流；不要覆盖稳定 Release。
```

## D. UI/交互回归（待实机验证）

同一设备、系统、字号、语言、深浅色主题，先录原版，再录新版。每项对照截图和操作事件：

- 首页普通/私密/空态/捷径/More；上下地址栏；四个搜索 provider 浮窗与原图标。
- 中文组合输入 c→cn、候选栏、输入框焦点/键盘避让、返回普通模式；程序性转换不新增动画。
- 菜单、设置每个入口、书签层级/排序、历史筛选、下载筛选/分享/打开文件。
- 普通/私密标签、分组、关闭/恢复、多窗口/侧栏；退出/重启后 ID、排序、标题恢复。
- 网页根滚动/内层滚动/缩放/惯性/反向拖拽/停住手指；工具栏整行 1:1 位移、150ms 收尾、隐藏后无点击拦截、fixed 页脚与底部手势区。
- 边缘历史手势、下拉刷新阈值/圆盘、状态栏回顶、上下文菜单/图片/链接预览、打印/PDF、reader。

## E. 蜂窝 + sing-box（待实机验证）

1. 关闭 Wi-Fi，确认 4G/5G；先启动并连接自己的 sing-box，整个测试不关闭。
2. 启动浏览器；不能弹出配对/DDI/LocalDevVPN/电脑/JIT 激活要求。
3. 访问静态页面、重 JS 页面、HTTPS 重定向、视频、文件下载、登录 Cookie；记录错误、首个内容时间、白屏/进程退出。
4. 切后台再返回、锁屏解锁、多标签连续浏览、4G/5G切换；对照同一路由下 Safari 的网络可达性，仅用于诊断，不改浏览器 UI。
5. 系统 WebKit 决定 JIT；网页执行结果或主观“很快”不等于已测量 JIT 状态。若锁定模式/系统策略限制，记录条件，不能借私有 API 强行开启。

## F. Firefox 扩展兼容（待实机验证）

每个实际扩展记录名称、ID、版本、下载 URL、包 SHA-256、MV 版本、声明权限和所有错误：

1. 正常/破损/超大/危险路径/ZIP bomb/重复文件名 XPI；失败必须不改已安装版本。
2. 内容脚本在顶层/跨域 iframe/动态 SPA/多标签的执行，`browser.*` 消息与 ports。
3. MV2 scripts、MV3 worker 启停、挂起/唤醒；扩展后台不等于 iOS 可无限后台运行。
4. storage.local 与权限在重启、禁用/启用、升级失败/回滚后持久；卸载清理必须有用户明确选择。
5. action popup、options、tab/window 操作连接现有 UI，不新开 Safari 样式外壳。
6. `webRequest` 监听与实际阻断分别验证；DNR 静态/动态/session 规则及重定向、配额、反馈权限分别测。不能只看 API 对象存在。
7. uBlock Origin 独立测试原版 XPI，检查后台错误、列表更新、实际请求/DOM 过滤和 popup 状态；失败即报告不兼容，不能换成 uBO Lite 后打勾。
8. 默认禁止访问私密标签；用户批准后验证隔离策略，不把私密 URL/存储发给普通后台。

## G. 视频/方向（待实机验证）

分别测试顶层 HTML video、网页 HTML Fullscreen、WebKit 系统全屏、跨域 iframe、MSE 流媒体、DRM、网站自绘控制栏：

- 内嵌播放、暂停/拖动/缓冲、音画同步、画中画/返回页面。
- 手机竖屏进入全屏仍为竖屏，原左下角 44pt 旋转按钮可用。
- 按按钮后分别向左右横转；死区/抖动/平放不过度切换；后台/退出后停止采样。
- 网站请求横屏/方向锁不能覆盖 app 可控全屏策略；退出按新需求回竖屏。
- 系统竖屏锁开/关、横屏入场、旋转请求被系统拒绝、切标签/关闭全屏标签、退后台。
- 原生全屏若没有公开修改内部控制栏的方法，记录为限制；不得添加私有 selector 或把 DRM 视频抽成裸 URL 破坏播放。

## H. 性能对照（待实机验证）

同机、同版本系统/网络/代理、同一网页列表和扩展集合；冷启动/暖启动分组各至少10次，明确缓存状态。分别记录启动至首帧、网页首个有用内容、标签切换、连续多标签峰值内存、空闲 CPU/能耗及崩溃。报告中位数/范围及原始测量方法。

原版包体和 CI 时长已可记录；没有最终 WebKit 浏览器 IPA/设备测量前，不给百分比提速或减小结论，不用 smoke app 与完整浏览器比较。
