# ieynec（原 Reynard / Fennec iOS）改版记录

## 最新交付：首次计数图标／隐私遗留／整块底栏（构建 #21）

用户新增四图和9.5s录屏仅本地分析。计数边框由动态文字色转为CGColor后可能在首次继承主题前取色；新增共享`FennecTabCountLabel`在挂到window／layout／trait变化刷新，避免第二次点击才正确。删除TabOverviewCollection旧Reynard狐狸说明的factory／背景绑定／空数据切换，保留TabOverview单套面具说明，不删除隐私数据。

底栏由“56pt行裁切＋底部单独透明／补偿”改为整块（例如56+34=90pt）从上到下平移；背景、行、OS inset同一UIView，视觉位移和Gecko bottom offset相同，不再分段，不留下不透明底部空白。Android原始盾牌矢量保留MPL2.0来源；显示真实网址而非域名／标题拼接，隐藏scheme但尊重完整地址偏好，不改变输入／提交。16pt文字、24pt盾牌、20pt regular加号；44pt触控目标保留。原App图标和捷径修正不变。

完整[#21](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39755850470)成功，30m04s，SDK缓存命中、引擎未重编；源码`6ce67d68482ebf1f4e940135153fc0310deda603`，包内`6ce67d6`。当前IPA已下载双重哈希核验：106,731,181 bytes，SHA-256 `EF9E93FD6303CBDF880DDA72FEA4577616D762CBC83C4070984F824FACFA003F`；主App与两扩展plist原标识、0.18.0／6ce67d6、最低系统13.0保留。

25项源码／本地化、Foundation组、Swift解析、扩大UIKit与完整App打包、6项下载器隔离测试通过。新增真实计数初次挂到深色host／多次主题变化／二次点击不变、实际actool盾牌加载、网址格式运行用例；五段底栏导出检查同位移不淡出，截图已查看。地址视图／引擎边界仍有替身，隐私collection清理有源码检查，不冒称完整Gecko／真机总览已验收。测试仍有fixture生命周期／region和原deprecated等警告，不是无警告构建。

当前`IPA\current\ieynec-no-jit.ipa`为#21，原#20及来源已按旧哈希归档`IPA\rollback\ieynec-no-jit-build20.ipa`；更早回滚保留。SideStore覆盖、保留全部扩展、不卸载／清数据；无JIT。完整Gecko一段式隐藏、初次总览深色框、私密总览单套说明和地址栏实际观感待手机确认。系统键盘动画等原边界不变；Codeberg旧包未更新上传。

## 历史交付：底部网页区域／捷径首次显示（构建 #20）

新五图仅本地分析。按新要求，底栏收起后不再保留不透明的底部安全区空白，网页可用区域同步释放整行和底部安全区；不是恢复旧的小网址条。保留底栏既有跟手／收尾方式，不重写系统手势。捷径原本不在“更多”内，问题是首次布局读取尚未有宽度的内部collection导致1pt高度；改为从已经解析的外层section宽度计算，不再依赖点击“更多”触发布局。

测试首次编译真实`FavoritesSectionViewController`和`FavoritesCollectionViewLayout`，强制“section有宽度、collection仍0宽”的条件，检查未点More就有两行／六个cell，另测空书签／通知恢复。bookmark store、图标cell、编辑／菜单仍有替身；模拟器首页橙色cell不是正式App的捷径外观。滚动夹具检查额外34pt区域补偿和背景透明。23项源码／简繁、Foundation组、Swift解析、扩大UIKit运行、完整App打包及6项Windows下载器隔离测试通过，组件图与实际首页截图已下载查看。

完整[#20](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39740615453)成功，App源码`c670ded36f1cc911059db42004d252f646307999`，构建号`c670ded`。第一次在模拟器准备阶段12min超时，未生成新包；同源码第二次运行成功，构建任务28m04s，SDK缓存命中、引擎重编译跳过。已核验下载`IPA\current\ieynec-no-jit.ipa`，106,727,821 bytes，SHA-256 `1480011DFAD406118EB8DF5E19ACB9B287ECBA4F378B904659B13998C6796DC8`。主App及两扩展plist／原标识／0.18.0／最低系统声明13.0保留。

旧#19及来源按原哈希核验后归档`IPA\rollback\ieynec-no-jit-build19.ipa`，更早回滚不变。SideStore覆盖、保留全部扩展、不先卸载／清数据；无JIT。完整Gecko底部文字／fixed页脚／系统手势区以及用户真实书签首次显示仍待真机确认，不把夹具通过冒充真机验收。键盘自身动画等原有未完成边界不变；Codeberg旧包未更新／上传。

## 历史交付：图标底色／捷径与整条底栏滚动（构建 #19）

依据新增三张截图和 Android／iOS 两段对比视频，在本地完成分析，未上传私人素材。图标改为参考 Safari 的浅色渐变、边缘亮度和柔和投影，不再纯白底；狐狸比例和主页原图保留，不冒称复制 Apple 分层图标或各种系统光照均完全相同。删除首页“经常造访的网站”区块及其设置入口，旧 true 偏好也不能重新显示；不删除历史。真实捷径默认开启，并按每个 profile 一次性迁移覆盖升级，之后仍可手动关闭，不写入虚假书签。

底部搜索框不再变成 Reynard 式小字网址：胶囊、网址、＋、计数和菜单作为一整行随网页滚动 1:1 平移，去掉原 0.8 跟随系数、速度限制和提前淡出。完整收起后仅保留系统底部安全区。对照固定 Android 158 源码，松手按半高选展开／收起，150ms 减速收尾；停住手指不触发定时吸附；反向滚动或新的触摸从当前位移中断。补测只按下未滚动也能在松手恢复未完成收尾。当前桥接无 APZ 惯性结束通知，惯性滚动后沿用 100ms 静默判定；完整 Gecko 时序仍需真机对比，不能称已逐帧一致。聚焦／键盘／托盘等非指定路径继续无 App 动画。

完整 [#19](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39733757293) 成功，任务 26m48s、Gecko SDK 缓存命中，源码 `bba987627c85912aa9eac240d8e6928a5c7ae946`，包内构建号 `bba9876`。已下载并校验 `IPA\current\ieynec-no-jit.ipa`，106,729,811 bytes，SHA-256 `82F110EF40A7CC9FCBF4B95A9C086BD6ACA17B86C8C73AE31A0B5F208A202AE4`。主 App／OpenIn／Helper plist、原标识、最低系统声明 13.0 均核验。

22 项源码／本地化、Foundation 标签组、Swift 解析、包含真实 ToolbarController 和 BottomToolbar 的 UIKit 回归、完整编译打包及 6 项 Windows 下载器测试通过。已下载复查实际私密页面与工具栏组件图；展开／半隐藏／完全隐藏导出未残留小网址，隐藏行触控穿透测试通过。夹具引擎／地址框／存储仍有替身，不代替真机浏览器。#18 测试通过后主动取消打包，为加入触摸打断修正；不是失败交付或下载源。

#17 及来源已按原哈希归档到 `IPA\rollback\ieynec-no-jit-build17.ipa`，#11／#7／#2 保留。安装仍为 SideStore 覆盖，保留全部扩展，不卸载／清数据；无 JIT。系统键盘自身动画仍未解决，视频方向等既有真机边界不变。新图标实际桌面观感、完整网页滚动效果等仍待用户确认。Codeberg 旧包未更新／上传。

## 历史交付：新增圈注／短视频对照（构建 #17）

新增四张圈注图和四段短视频仅本地查看，不上传。恢复上／下工具栏真实独立加号（三个 44pt 触控目标），重新分配窄屏地址栏宽度；狐狸形私密图标改为同一 Android 158 参考版本的原始隐私面具矢量（路径不变、保留 MPL-2.0 声明，SVG/template 适配），标签计数改横向矩形，托盘加号修正紫色／阴影。第四个设备分类属于未实现的同步，按既定要求不增加假入口，不添加不活跃标签或假统计。

全屏增加独立方向状态：手机先竖屏，左下角按钮切换感应左右横屏／恢复竖屏；网站方向锁不能强制覆盖此选择。加速度重力判定带死区和连续采样确认，非全屏／后台停止。iOS 16+ 使用 scene geometry 请求，不修改系统锁定开关，拒绝请求会显示提示。系统竖屏锁定下的实际效果、左右映射、播放器兼容与退出恢复均待真机确认，不以状态测试冒充实现验收。

刷新改为浮动圆盘，不再拉伸移动整个网页；真实 Gecko reload 不变，阈值 96pt。依新增录屏，仅手机地址栏随网页滚动隐藏／复位的显示链补间，以及刷新进度，作为指定动画例外；其余聚焦／键盘／导航／托盘路径仍无 App 动画。焦点输入框避让时长进一步设为零。用户已取消“保留系统键盘动画”的旧约定，但目前未核实可支持地关闭系统键盘自身动画，不能声称这点已完成。

App 图标保留原狐狸图案，白色方画布、去除烘焙圆角／近白底块，主体按比例居中、最长边约占 79%；由 iOS 遮罩外角。Safari 圆形罗盘和宽狐狸的四边轮廓留白无法不变形地完全相等，最终桌面观感待检查。生成脚本 `tools/Prepare-AppIcon.sh`，主页原图不改。

19 项本地源码／简繁检查已通过；新增 UIKit 真实工具栏／全屏状态／刷新组件回归已于 UI-only #15 通过，离屏画布须显式刷新布局才可读编辑后 frame；生产工具栏未为夹具问题修改。#16 在打包前取消，用原始参考矢量替代近似面具；最终 SVG 资产已在 #17 夹具中真实 actool 编译／加载并通过检查，实际私密页面和分类图标也已复查。没有更新引擎、SDK、标识、应用扩展、JIT 决策或用户数据。

**完整构建 #17 成功**：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39725171193 ，App revision `12dec95dc2612e23063dacff8881de71138b9bec`，构建任务 24m32s，Gecko SDK 缓存命中。新包已下载核验并放入 `IPA\current\ieynec-no-jit.ipa`：106,640,271 bytes，SHA-256 `67DD4CC8A841EE952EF788D5255B0A7C4CCF0CD5977454E6563CA7EC55DE77CC`。主 App 名称／技术标识及 `OpenIn.appex`、`Reynard Helper.appex` plist 已检查保留，构建号均为 `12dec95`。19 项源码／简繁检查、Foundation 标签组、Swift 解析、最终 UIKit fixture 和完整 App 打包通过；6 项 Windows 下载器隔离测试通过。仍有原有编译警告，不代表无警告或真机验收。

旧 #11 包及来源记录已保留到 `IPA\rollback\ieynec-no-jit-build11.ipa`；下方 #11 段落里的旧 current 路径为历史，现已归档。系统键盘自身动画、竖屏锁定／左右横屏／视频退出、完整 Gecko 手势与扩展、图标实际桌面观感／性能仍待用户真机覆盖安装确认。详见 [docs/VIDEO-REVIEW.md](docs/VIDEO-REVIEW.md)。

## 历史交付：视频对照、取消 JIT（构建 #11，已归档）

用户提供 Android / iOS 录屏及 Android 私密模式补拍视频，明确取消 JIT 功能，并再次要求去掉地址栏聚焦的原生过渡。新要求覆盖下面历史记录中“保留 JIT”的约定。

本轮源码：移除设置的 JIT 分组，旧开关强制失效；启动只保留向 Gecko 子进程回报无 JIT 状态的必要握手，不建立配对隧道、不下载 DDI、不启动调试或 JIT 后台音频。不擅自删除已有配对文件。旧 #7 IPA 未因此改变。

私密首页/总览使用深色和真实空态说明，不再显示普通品牌标题、捐赠 More；修正总览菜单、繁体中文、主页控件设置和地址栏/键盘布局的直接提交路径。标签切换不再等待异步首页预览完成，缓存小图标，关闭保护卡片时不遍历计算计数。保留 Gecko、扩展和版本基线，不改 SDK 缓存 key。

详细对照和未完成差异：[docs/VIDEO-REVIEW.md](docs/VIDEO-REVIEW.md)。书签/下载/历史深层页面并未全部复刻 Android，不能宣称全完成。无 JIT 原生性能优化也不代表补齐 JavaScript 性能差距。

最新工作路径：`C:\Users\Orie\Downloads\ieynec-项目\source`。下文旧下载路径/状态均为历史。可回滚完整 IPA 是 `ieynec-项目\IPA\rollback\ieynec-ui-fix.ipa`（#7）；本轮新 IPA 已成功下载核验：`ieynec-项目\IPA\current\ieynec-no-jit.ipa`。#7 及来源文件已移至 `IPA\rollback` 保留，不覆盖旧数据。

完整构建 #11：https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39712078402 ，App revision `98d694d34a4319ec3b0e4c0bc7d9f93285bcdc24`，构建任务 28m23s，Gecko SDK 缓存命中。IPA 大小 106,590,894 bytes，SHA-256 `9C68D4F63649F692C21F62F8FAE55D378417B712381AF46C049749D3AB94D5FD`。主 App 及两个扩展 plist 已检查保留。

16 项源码/简繁本地化检查、Foundation 标签组测试、Swift 语法、完整 App 编译打包和扩大 UIKit fixture 通过；6 项 Windows 下载器隔离测试通过。fixture 新增真实私密首页、主页两个开关的四种组合、无 JIT 控制器旧偏好迁移及子进程状态回报、下载分类/按钮和书签排序方向检查；引擎/存储边界仍用替身。已查看 #11 的实际私密页面与群组页面屏幕截图；没有把先前合成宽度截图的裁切当作真机结果。

另补上视频里的下载类型筛选和书签正反排序，保留原数据、受保护文件夹位置和额外网址排序。Android 悬浮搜索按钮、详细历史分组、部分深层页面仍未完全复刻；地址栏聚焦/键盘联动的最终真机录屏验收尚未完成。无 JIT 性能尚无设备基准，不声称达到 Safari。

Codeberg 发布准备 ZIP 仍是之前 `4cb058f`，不含本轮修改；本次没有重新打包或上传 Codeberg。发布当前版本应使用最新 Git 分支或另行更新准备包。

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
