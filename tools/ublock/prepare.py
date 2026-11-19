#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Stage a HASH-PINNED full Firefox uBO package, not an arbitrary XPI importer."""
import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import stat
import sys
import zipfile

REPO = Path(__file__).resolve().parents[2]

def prepare(package, target):
    metadata = json.loads((REPO / 'tests/webkit-smoke/ublock-package.json').read_text(encoding='utf-8'))
    digest = hashlib.sha256(package.read_bytes()).hexdigest()
    if digest != metadata['sha256']:
        raise ValueError('Official package SHA-256 mismatch; extraction refused')
    # Never erase/merge an existing profile or stage directory.
    target.mkdir(parents=True, exist_ok=False)
    original = {}
    with zipfile.ZipFile(package) as archive:
        entries = archive.infolist()
        if len(entries) > 10000 or sum(e.file_size for e in entries) > 256 * 1024 * 1024:
            raise ValueError('Pinned package exceeded extraction limits')
        for entry in entries:
            path = PurePosixPath(entry.filename)
            if path.is_absolute() or '..' in path.parts or '\\' in entry.filename or ':' in entry.filename:
                raise ValueError('Unsafe archive path')
            if stat.S_ISLNK(entry.external_attr >> 16):
                raise ValueError('Archive symlink refused')
            if entry.is_dir():
                continue
            if entry.file_size > 32 * 1024 * 1024 or entry.filename in original:
                raise ValueError('Oversized or duplicate archive entry')
            data = archive.read(entry)
            original[entry.filename] = hashlib.sha256(data).hexdigest()
            output = target.joinpath(*path.parts)
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(data)
    manifest_path = target / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    if manifest['version'] != metadata['version'] or manifest['manifest_version'] != 2:
        raise ValueError('Unexpected upstream manifest')
    # Explicitly UNOFFICIAL, modified source. Mozilla signature is no longer valid.
    manifest['name'] = 'uBlock Origin (unofficial WebKit research port)'
    manifest['description'] = 'Experimental full-uBO port; incomplete network compatibility. Not an official uBO release.'
    manifest['background'] = {'page': 'port/background.html', 'persistent': False}
    manifest['permissions'].append('declarativeNetRequest')
    removed_commands = []
    for key, value in list(manifest.get('commands', {}).items()):
        if key.startswith('_execute_') and not value:
            removed_commands.append(key)
            del manifest['commands'][key]
    manifest['content_scripts'].append({
        'matches': ['http://127.0.0.1/*'], 'js': ['port/diagnostic-content.js'], 'run_at': 'document_idle'
    })
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    shutil.rmtree(target / 'META-INF')
    shutil.copytree(REPO / 'ports/ublock-webkit', target / 'port')
    patched = {}
    for patch in json.loads((REPO / 'ports/ublock-webkit/patches.json').read_text(encoding='utf-8')):
        name = patch['path']
        if name not in original:
            raise ValueError('Patch target not in original package')
        file = target / name
        text = file.read_bytes().decode('utf-8')
        if text.count(patch['old']) != 1:
            raise ValueError('Pinned upstream patch no longer matches: ' + name)
        replacement = patch.get('new')
        if 'insertFile' in patch:
            insert_file = patch['insertFile']
            if Path(insert_file).name != insert_file:
                raise ValueError('Unsafe patch insertion path')
            replacement = (REPO / 'ports/ublock-webkit' / insert_file).read_text(encoding='utf-8') + '\n' + patch['old']
        file.write_bytes(text.replace(patch['old'], replacement).encode('utf-8'))
        entry = patched.setdefault(name, {'before': original[name], 'reasons': []})
        entry['after'] = hashlib.sha256(file.read_bytes()).hexdigest()
        entry['reasons'].append(patch['reason'])
    unchanged = 0
    for name, expected in original.items():
        if name == 'manifest.json' or name.startswith('META-INF/'):
            continue
        if name in patched:
            continue
        if hashlib.sha256((target / name).read_bytes()).hexdigest() != expected:
            raise ValueError('Unexpected upstream source modification: ' + name)
        unchanged += 1
    provenance = {
        'officialInput': metadata, 'unmodifiedUpstreamFiles': unchanged,
        'upstreamJavaScriptPatches': patched, 'upstreamHTMLCSSPatched': False,
        'modifiedManifestFields': ['name', 'description', 'background', 'permissions', 'commands', 'content_scripts'],
        'removedEmptyReservedCommands': removed_commands,
        'mozillaSignatureRemoved': True, 'licenseRetained': (target / 'LICENSE.txt').is_file(),
        'probeOnly': True, 'fullUBlockOriginVerified': False,
    }
    (target / 'port/provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(provenance, indent=2))

if __name__ == '__main__':
    prepare(Path(sys.argv[1]), Path(sys.argv[2]))
