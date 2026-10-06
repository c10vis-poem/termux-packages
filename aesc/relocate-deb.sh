#!/usr/bin/env bash
# Relocate one Termux deb from /data/data/com.termux/ to /data/data/aethx.aesc/ (same length, byte swap).
# usage: relocate-deb.sh <in.deb> <workdir> <outdir>
set -euo pipefail
d=$1; r="$2/$(basename "$d" .deb)"; out=$3
trap 'rm -rf "$r"' EXIT
dpkg-deb -R "$d" "$r"
find "$r" -type f ! -path '*/DEBIAN/md5sums' -exec perl -pi -e 's#/data/data/com\.termux/#/data/data/aethx.aesc/#g' {} +
if [ -d "$r/data/data/com.termux" ]; then mv "$r/data/data/com.termux" "$r/data/data/aethx.aesc"; fi
find "$r/DEBIAN" \( -name preinst -o -name postinst -o -name prerm -o -name postrm -o -name config \) -exec chmod 755 {} +
# Upstream conffiles can list paths the payload lacks (cups: cupsd/log/down); dpkg-deb -b rejects those.
if [ -f "$r/DEBIAN/conffiles" ]; then
  while IFS= read -r c; do if [ -e "$r$c" ] || [ -L "$r$c" ]; then printf '%s\n' "$c"; fi; done < "$r/DEBIAN/conffiles" > "$r/conffiles.tmp"
  if [ -s "$r/conffiles.tmp" ]; then mv "$r/conffiles.tmp" "$r/DEBIAN/conffiles"; else rm -f "$r/conffiles.tmp" "$r/DEBIAN/conffiles"; fi
fi
# Metapackages have no data/ tree; md5sums covers whatever payload exists.
( cd "$r" && find . -path ./DEBIAN -prune -o -type f -printf '%P\0' | xargs -0r md5sum > DEBIAN/md5sums )
dpkg-deb -b --root-owner-group "$r" "$out/" >/dev/null
