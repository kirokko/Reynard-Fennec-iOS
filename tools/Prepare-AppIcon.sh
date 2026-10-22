#!/usr/bin/env bash
# Reframe the supplied artwork, not the Firefox/Gecko brand. Requires ffmpeg.
# Keep the original homepage logo untouched. Use an opaque square canvas: iOS
# applies its own corner mask. Longest artwork dimension is about 79% of canvas,
# visually comparable to the Safari reference, with the original aspect intact.
set -euo pipefail
cd "$(dirname "$0")/.."
ffmpeg -hide_banner -loglevel error -y \
  -i browser/Reynard/Resources/Assets.xcassets/ieynec-logo.imageset/logo.png \
  -filter_complex '[0:v]crop=784:704:120:192,scale=816:732:flags=lanczos,format=rgba,colorkey=white:0.035:0[art];color=c=white:s=1024x1024:d=1[bg];[bg][art]overlay=x=104:y=146:format=rgb,setsar=1,format=rgb24[out]' \
  -map '[out]' -frames:v 1 -update 1 browser/Reynard/Resources/Assets.xcassets/AppIcon.appiconset/icon.png
