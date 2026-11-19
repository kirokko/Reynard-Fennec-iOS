# Gecko → WebKit migration checkpoint

**Not a completed browser migration. The production app still uses Gecko.**
No new WebKit browser IPA is delivered at this checkpoint. Do not mistake the
preserved Gecko rollback IPA or isolated test apps for the requested final product.

- [中文源码审计 / API 与功能边界](AUDIT.zh-CN.md)
- [实测结果与剩余交付项](RESULTS.zh-CN.md)
- [完整版 uBlock Origin：官方包与实际网络取消能力诊断](FULL-UBLOCK-ORIGIN.zh-CN.md)
- [Floorp 参考记录（未引入其代码）](FLOORP-REFERENCE.zh-CN.md)
- [具体实机测试 / 数据保护 / 升级回滚](DEVICE-TESTS.zh-CN.md)
- [原版 UI fixture 截图来源与范围](ui-baseline/README.md)
- [665-file source/resource baseline](baseline.json)
- [Verified original Gecko IPA provenance](gecko-ipa.provenance.json)

Engine foundation: `browser/WebKitEngine/` (outside the production Xcode target).
Runtime tests: `tests/webkit-smoke/`.
Manual CI gate: existing `build-sidestore.yml`, opt in with `webkit_checks_only=true`.
All normal production IPA workflow defaults are preserved.
