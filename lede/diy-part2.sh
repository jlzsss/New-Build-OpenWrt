#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# rm -rf feeds/packages2/lang/python
rm -rf feeds/packages/net/transmission
rm -rf feeds/packages/net/transmission-web-control

# Fix transmission-daemon missing libcrypto.so.3 / libssl.so.3 (OpenSSL 3.x) dependency
# Find the actual Makefile location (cloned from jlzsss/openwrt-transmission in diy-part1)
TRANSMISSION_MK="$(find package/transmission -maxdepth 2 -name 'Makefile' -print -quit 2>/dev/null)"
if [ -z "$TRANSMISSION_MK" ]; then
  for p in package/transmission/Makefile package/transmission/transmission/Makefile; do
    [ -f "$p" ] && TRANSMISSION_MK="$p" && break
  done
fi

if [ -n "$TRANSMISSION_MK" ] && [ -f "$TRANSMISSION_MK" ]; then
  echo "=== Fixing transmission-daemon OpenSSL dependency in $TRANSMISSION_MK ==="
  if grep -q 'libopenssl' "$TRANSMISSION_MK"; then
    echo "  -> libopenssl already in DEPENDS, skipping"
  else
    if grep -q 'Package/transmission-daemon' "$TRANSMISSION_MK"; then
      awk '
        /^define Package\/transmission-daemon/,/^endef/ {
          if (/DEPENDS:=.*[^\\]/) { sub(/$/, " +libopenssl") }
          else if (/DEPENDS:=.*\\/) { sub(/$/, " +libopenssl \\") }
        }
        { print }
      ' "$TRANSMISSION_MK" > "${TRANSMISSION_MK}.tmp" && mv "${TRANSMISSION_MK}.tmp" "$TRANSMISSION_MK"
    else
      sed -i '/^  DEPENDS:=/s/$/ +libopenssl/' "$TRANSMISSION_MK"
    fi
    grep -q 'libopenssl' "$TRANSMISSION_MK" && echo "  -> Successfully added +libopenssl" || {
      sed -i '/^  DEPENDS:=/s/$/ +libopenssl/' "$TRANSMISSION_MK"
      grep -q 'libopenssl' "$TRANSMISSION_MK" && echo "  -> Force-add succeeded" || echo "  -> FAILED"
    }
  fi
else
  echo "!!! WARNING: Transmission Makefile not found, skipping OpenSSL fix"
fi

rm -rf feeds/small/geoview
rm -rf feeds/kenzok8/geoview
rm -rf feeds/packages/lang/golang
git clone --depth 1 https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/uwsgi && cd .. && rm -rf feeds/packages/net/uwsgi && mv temp-lede/net/uwsgi feeds/packages/net && rm -rf temp-lede
git clone --depth 1 --filter=blob:none --sparse https://github.com/openwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set lang/lua/lua5.4 && cd .. && rm -rf feeds/packages/lang/lua/lua5.4 && mv temp-lede/lang/lua/lua5.4 feeds/packages/lang/lua/ && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set libs/libb64 && cd .. && rm -rf feeds/packages/libs/libb64 && mv temp-lede/libs/libb64 feeds/packages/libs && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/transmission && cd .. && rm -rf feeds/packages/net/transmission && mv temp-lede/net/transmission feeds/packages/net && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/transmission-web-control && cd .. && rm -rf feeds/packages/net/transmission-web-control && mv temp-lede/net/transmission-web-control feeds/packages/net && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/coolsnowwolf/packages.git temp-lede && cd temp-lede && git sparse-checkout set lang/rust && cd .. && rm -rf feeds/packages/lang/rust && mv temp-lede/lang/rust feeds/packages/lang && rm -rf temp-lede
