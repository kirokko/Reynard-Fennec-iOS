#!/usr/bin/env bash
# Reframe the supplied fox, not Apple's compass artwork. Requires ffmpeg.
# Preserve the original homepage logo and fox aspect ratio. The Safari reference
# has a light dimensional surface, NOT a flat white plate: use a neutral vertical
# white-to-light-gray gradient, subtle edge illumination and a soft artwork shadow.
# No baked outer corners: iOS applies its own icon mask.
set -euo pipefail
cd "$(dirname "$0")/.."
ffmpeg -hide_banner -loglevel error -y \
  -i browser/Reynard/Resources/Assets.xcassets/ieynec-logo.imageset/logo.png \
  -filter_complex "[0:v]crop=784:704:120:192,scale=816:732:flags=lanczos,format=rgba,colorkey=white:0.035:0,split[art][silhouette];[silhouette]pad=1024:1024:104:146:color=black@0,lutrgb=r=0:g=0:b=0,colorchannelmixer=aa=0.14,gblur=sigma=12[shadow];color=c=white:s=1024x1024:d=1,format=gbrp,geq=r='min(255,255-22*pow(Y/(H-1),1.6)+5*pow(abs(2*X/(W-1)-1),12))':g='min(255,255-22*pow(Y/(H-1),1.6)+5*pow(abs(2*X/(W-1)-1),12))':b='min(255,255-22*pow(Y/(H-1),1.6)+5*pow(abs(2*X/(W-1)-1),12))'[bg];[bg][shadow]overlay=x=0:y=16[base];[base][art]overlay=x=104:y=146:format=rgb,setsar=1,format=rgb24[out]" \
  -map '[out]' -frames:v 1 -update 1 browser/Reynard/Resources/Assets.xcassets/AppIcon.appiconset/icon.png
