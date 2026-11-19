#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Run the real pinned-package staging code against disposable test paths."""
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import sys
sys.dont_write_bytecode = True
from prepare import prepare

package = Path(sys.argv[1]).resolve()
passed = []
with tempfile.TemporaryDirectory(prefix='reynard-ubo-stage-test-') as temporary:
    root = Path(temporary)
    bad = root / 'tampered.xpi'
    bad.write_bytes(b'not the pinned official package')
    target = root / 'refused'
    try:
        prepare(bad, target)
        raise AssertionError('Tampered package was accepted')
    except ValueError as error:
        assert 'SHA-256' in str(error)
        assert not target.exists()
    passed.append('wrong hash refused before extraction or stage creation')

    existing = root / 'existing-profile'
    existing.mkdir()
    marker = existing / 'preserve.txt'
    marker.write_bytes(b'do not delete or merge')
    try:
        prepare(package, existing)
        raise AssertionError('Existing target was accepted')
    except FileExistsError:
        assert marker.read_bytes() == b'do not delete or merge'
        assert list(existing.iterdir()) == [marker]
    passed.append('existing directory/data preserved without merge')

    stage = root / 'fresh'
    with redirect_stdout(io.StringIO()):
        prepare(package, stage)
    provenance = json.loads((stage / 'port/provenance.json').read_text(encoding='utf-8'))
    assert provenance['licenseRetained'] is True
    assert provenance['mozillaSignatureRemoved'] is True
    assert provenance['upstreamHTMLCSSPatched'] is False
    assert set(provenance['upstreamJavaScriptPatches']) == {'js/vapi-common.js', 'js/vapi-background.js', 'js/i18n.js'}
    assert not (stage / 'META-INF').exists()
    assert 'vAPI.getURL = (...args) => browser.runtime.getURL(...args);' in (stage / 'js/vapi-common.js').read_text(encoding='utf-8')
    passed.append('explicit platform patches, unchanged-source verification, GPL and signature provenance')
print(json.dumps({'passed': passed, 'count': len(passed)}, indent=2))
