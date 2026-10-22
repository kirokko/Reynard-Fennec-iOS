// Convert already-downloaded, pinned Mozilla Android vectors without changing paths.
// Usage: node tools/Import-FennecReferenceIcons.mjs <directory-containing-xml>
import fs from 'node:fs';
import path from 'node:path';
const source = process.argv[2];
if (!source) throw Error('XML directory required');
for (const [file, asset] of Object.entries({
  tab: 'FennecTabOutline', bookmark_tray: 'FennecBookmarkTray',
  tab_tray: 'FennecTabTray', history: 'FennecHistory', settings: 'FennecSearchSettings',
  private_circle: 'FennecPrivateBadge', private_mode_circle_fill_stroke_20: 'FennecPrivateTabBadge',
})) {
  const xml = fs.readFileSync(path.join(source, file + '.xml'), 'utf8');
  const w = xml.match(/viewportWidth="([^"]+)"/)[1];
  const h = xml.match(/viewportHeight="([^"]+)"/)[1];
  const paths = [...xml.matchAll(/<path\b[\s\S]*?\/>/g)].map((m, i) => {
    const d = m[0].match(/android:pathData="([^"]+)"/)[1];
    const colored = file.startsWith('private');
    const fill = colored ? (i === 0 ? '#7542E5' : '#FFFFFF') : '#000000';
    const stroke = m[0].includes('strokeWidth') ? ' stroke="#FFFFFF" stroke-width="1"' : '';
    return `  <path fill="${fill}"${stroke} d="${d}"/>`;
  });
  const svg = `<!-- Mozilla FIREFOX-ANDROID_158_0_RELEASE; original path data, wrapper/fill adaptation.\n     This Source Code Form is subject to the Mozilla Public License, v. 2.0.\n     https://mozilla.org/MPL/2.0/ -->\n<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">\n${paths.join('\n')}\n</svg>\n`;
  const dir = path.join('browser/Reynard/Resources/Assets.xcassets', asset + '.imageset');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'icon.svg'), svg);
  fs.writeFileSync(path.join(dir, 'Contents.json'), JSON.stringify({
    images: [{ filename: 'icon.svg', idiom: 'universal' }], info: { author: 'xcode', version: 1 },
    properties: { 'preserves-vector-representation': true, 'template-rendering-intent': file.startsWith('private') ? 'original' : 'template' },
  }, null, 2) + '\n');
}
