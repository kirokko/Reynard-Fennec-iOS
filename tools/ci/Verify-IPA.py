#!/usr/bin/env python3
"""Verify newly packaged bytes, never select a previous successful artifact."""
import hashlib
import json
import os
import pathlib
import plistlib
import subprocess
import sys
import zipfile

ipa = pathlib.Path(sys.argv[1])
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
if os.environ.get('EXPECTED_COMMIT', commit) != commit:
    raise SystemExit('Checkout does not match requested commit')
expected = {
    'Payload/Reynard.app/Info.plist': ('com.minh-ton.Reynard', None),
    'Payload/Reynard.app/PlugIns/OpenIn.appex/Info.plist': ('com.minh-ton.Reynard.OpenIn', 'com.apple.share-services'),
    'Payload/Reynard.app/PlugIns/Reynard Helper.appex/Info.plist': ('com.minh-ton.Reynard.Helper', 'com.apple.ar.viewer'),
}
with zipfile.ZipFile(ipa) as archive:
    bad = archive.testzip()
    if bad:
        raise SystemExit(f'ZIP checksum failure: {bad}')
    plists = []
    for name, (identifier, extension) in expected.items():
        p = plistlib.loads(archive.read(name))
        if p['CFBundleIdentifier'] != identifier or p['CFBundleVersion'] != commit[:7]:
            raise SystemExit(f'Wrong identity/build: {name}')
        if extension and p['NSExtension']['NSExtensionPointIdentifier'] != extension:
            raise SystemExit(f'Wrong extension: {name}')
        plists.append({'path': name, 'identifier': identifier, 'build': p['CFBundleVersion'], 'version': p['CFBundleShortVersionString'], 'minimumOS': p.get('MinimumOSVersion')})
    for name in ['Payload/Reynard.app/Reynard', 'Payload/Reynard.app/Frameworks/XUL', 'Payload/Reynard.app/Frameworks/GeckoView.framework/GeckoView', 'Payload/Reynard.app/Frameworks/GeckoView.framework/Frameworks/default-theme/manifest.json']:
        if archive.getinfo(name).file_size == 0:
            raise SystemExit(f'Empty required product: {name}')
digest = hashlib.sha256()
with ipa.open('rb') as stream:
    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
        digest.update(chunk)
report = {
    'commit': commit,
    'run': f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/{os.environ.get('GITHUB_RUN_ID', '')}",
    'file': ipa.name,
    'bytes': ipa.stat().st_size,
    'sha256': digest.hexdigest(),
    'plists': plists,
}
ipa.with_suffix(ipa.suffix + '.provenance.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
