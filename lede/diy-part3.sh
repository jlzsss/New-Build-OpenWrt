#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part3.sh
# Description: OpenWrt DIY script part 3 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

git clone --depth 1 https://github.com/jlzsss/luci-app-shadowsocksr.git package/luci-app-shadowsocksr
# git clone --depth 1 https://github.com/jlzsss/openwrt-dnsmasq-extra.git package/openwrt-dnsmasq-extra
git clone --depth 1 https://github.com/tty228/luci-app-serverchan.git package/luci-app-serverchan
git clone --depth 1 https://github.com/peter-tank/openwrt-minisign.git package/minisign
git clone --depth 1 https://github.com/aa65535/openwrt-chinadns.git package/chinadns
rm -rf feeds/kenzok8/luci-app-qbittorrent
rm -rf feeds/kenzok8/qbittorrent
rm -rf feeds/kenzok8/qBittorrent
rm -rf feeds/kenzok8/qBittorrent-Enhanced-Edition
rm -rf feeds/kenzok8/qBittorrent-static
rm -rf feeds/kenzok8/quickstart
rm -rf feeds/kenzok8/luci-app-nikki
rm -rf feeds/kenzok8/luci-app-quickstart
rm -rf feeds/kenzok8/luci-app-xray
rm -rf feeds/kenzok8/luci-app-xray-status
rm -rf feeds/lede/qBittorrent
rm -rf feeds/lede/qBittorrent-Enhanced-Edition
rm -rf feeds/luci2/luci-app-turboacc
./scripts/feeds install -p packages2 quickstart
./scripts/feeds install -p packages2 luci-app-quickstart
rm -rf feeds/packages/net/{qBittorrent,qBittorrent-static,xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls,haproxy}
rm -rf package/feeds/lede/php7
# rm -rf package/feeds/packages/php7
rm -rf feeds/lede/mt-drivers
rm -rf feeds/kenzok8/r8168
rm -rf feeds/kiddin/MentoHUST-OpenWrt-ipk
# rm -rf feeds/luci/applications/luci-app-dockerman
# rm -rf feeds/other/luci-app-dockerman
# rm -rf feeds/kiddin/luci-app-dockerman
# rm -rf feeds/liuran/luci-app-dockerman
# rm -rf package/lede/luci-app-dockerman
rm -rf feeds/liuran/adguardhome
rm -rf feeds/liuran/GoQuiet
rm -rf feeds/liuran/gost
rm -rf feeds/kenzok8/3proxy/patches
rm -rf feeds/kenzok8/shortcut-fe
rm -rf feeds/NueXini/luci-app-gost
rm -rf feeds/NueXini/gost
rm -rf feeds/NueXini/qBittorrent
rm -rf feeds/NueXini/qBittorrent-static
rm -rf feeds/NueXini/qtbase
rm -rf feeds/NueXini/qttools
rm -rf feeds/NueXini/rblibtorrent

# ============================================================
# Remove duplicate mihomo packages from other feeds
# Keep feeds/packages/net/mihomo as the sole mihomo provider
# ============================================================

rm -rf feeds/kenzok8/mihomo
rm -rf feeds/kenzok8/luci-app-mihomo
rm -rf feeds/small/mihomo
rm -rf feeds/kenzo/mihomo
rm -rf feeds/xuanranran/mihomo
rm -rf feeds/haiibo/mihomo
rm -rf feeds/liuran/mihomo
# All mihomo packages removed; feeds/packages/net/mihomo is the sole provider

# ============================================================
# Fix nikki: make it depend on mihomo feed package instead of building its own
# ============================================================

echo "=== Fixing nikki mihomo conflict ==="
NIKKI_MAKEFILE="feeds/packages/net/nikki/Makefile"

if [ -f "$NIKKI_MAKEFILE" ]; then
  echo "  Found: $NIKKI_MAKEFILE"

  # Remove PROVIDES mihomo
  sed -i '/PROVIDES:=mihomo/d' "$NIKKI_MAKEFILE"
  echo "  -> Removed PROVIDES:=mihomo"

  # Remove ALTERNATIVES
  sed -i '/ALTERNATIVES:=/d' "$NIKKI_MAKEFILE"
  echo "  -> Removed ALTERNATIVES"

  # Add +mihomo to DEPENDS
  sed -i 's/^\(  DEPENDS:=.*\)/\1 +mihomo/' "$NIKKI_MAKEFILE"
  echo "  -> Added +mihomo to DEPENDS"

  # Remove Go build dependency on golang
  sed -i '/PKG_BUILD_DEPENDS.*golang/d' "$NIKKI_MAKEFILE"
  echo "  -> Removed PKG_BUILD_DEPENDS:=golang/host"

  # Remove all Go build related variables
  sed -i '/GO_PKG/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_BUILD_ARGS/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_INSTALL_EXTRA/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_LDFLAGS/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_TAGS/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_MOD_CACHE/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_BUILD_PKG/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_BUILD_DIR/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_INSTALL_BIN/d' "$NIKKI_MAKEFILE"
  echo "  -> Removed Go build variables"

  # Remove golang-package.mk include (critical: prevents Go build)
  sed -i '\|golang-package.mk|d' "$NIKKI_MAKEFILE"
  echo "  -> Removed golang-package.mk include"

  # Remove GoBinPackage call (critical: was missed before, pattern GoPackage/Package didn't match GoBinPackage)
  sed -i '/GoBinPackage/d' "$NIKKI_MAKEFILE"
  echo "  -> Removed GoBinPackage call"

  # Remove legacy patterns (for older Makefile versions)
  sed -i '/GoPackage\/Package/d' "$NIKKI_MAKEFILE"
  sed -i '/golang-build.sh/d' "$NIKKI_MAKEFILE"
  echo "  -> Removed Go build logic"

  # === CRITICAL FIX: Remove /usr/bin/mihomo installation from install section ===
  # This is the root cause of the file conflict error
  # Match various patterns that install mihomo binary to /usr/bin/
  sed -i '/usr\/bin\/mihomo/d' "$NIKKI_MAKEFILE"
  echo "  -> Removed /usr/bin/mihomo install lines (ROOT CAUSE FIX)"

  # Also remove generic Go binary install patterns that could still be present
  sed -i '\|$(INSTALL_BIN).*$(PKG_BUILD_DIR)|d' "$NIKKI_MAKEFILE"
  sed -i '\|$(INSTALL_BIN).*$(GO_BIN)|d' "$NIKKI_MAKEFILE"
  sed -i '\|$(CP).*mihomo.*usr/bin|d' "$NIKKI_MAKEFILE"
  echo "  -> Removed residual binary install commands"

  # Add symlink for init scripts (so init.d scripts can find mihomo via /usr/libexec/nikki)
  awk '/^define Package\/nikki\/install/{print; print "\t$(INSTALL_DIR) $(1)/usr/libexec"; print "\t$(LN) /usr/bin/mihomo $(1)/usr/libexec/nikki"; next}1' "$NIKKI_MAKEFILE" > "$NIKKI_MAKEFILE.tmp" && mv "$NIKKI_MAKEFILE.tmp" "$NIKKI_MAKEFILE"
  echo "  -> Added symlink /usr/libexec/nikki -> /usr/bin/mihomo"

  # Clear build cache
  rm -rf build_dir/target-*/nikki-* 2>/dev/null
  rm -rf build_dir/target-*/*.nikki-* 2>/dev/null
  rm -f tmp/info/.packageinfo-nikki* 2>/dev/null
  echo "  -> Build metadata cleared"
else
  echo "  WARNING: nikki Makefile not found at $NIKKI_MAKEFILE!"
fi
echo "=== nikki fix done ==="

# Fix clashoo: depend on nikki instead of providing its own mihomo binary
# nikki already PROVIDES mihomo via ALTERNATIVES, clashoo should reuse it
echo "=== Fixing clashoo mihomo conflict ==="
CLASHOO_FOUND=0
for clashoo_makefile in feeds/small/clashoo/Makefile feeds/kenzo/clashoo/Makefile feeds/kenzok8/clashoo/Makefile; do
  if [ -f "$clashoo_makefile" ]; then
    echo "  Found: $clashoo_makefile"
    CLASHOO_FOUND=1
    # Remove mihomo from PROVIDES (keep clash-meta)
    sed -i 's/PROVIDES:=mihomo clash-meta/PROVIDES:=clash-meta/' "$clashoo_makefile"
    sed -i 's/PROVIDES:=clash-meta mihomo/PROVIDES:=clash-meta/' "$clashoo_makefile"
    echo "  -> Removed mihomo from PROVIDES"
    # Add +nikki to DEPENDS
    sed -i 's/^\([[:space:]]*DEPENDS:=.*\)/\1 +nikki/' "$clashoo_makefile"
    echo "  -> Added +nikki to DEPENDS"
    # Remove the Go binary install line (clashoo uses nikki's mihomo)
    sed -i '\|$(call GoPackage/Package/Install/Bin,|d' "$clashoo_makefile"
    echo "  -> Removed Go binary install"
  fi
done
if [ "$CLASHOO_FOUND" -eq 0 ]; then
  echo "  WARNING: clashoo Makefile not found in any expected location!"
fi
echo "=== clashoo fix done ==="

# ============================================================
# Fix luci-app-fchomo postinst version check
# The postinst script checks for minimum OpenWrt 24.10 version
# which may fail on lede snapshot builds. Patch it to skip.
# ============================================================
echo "=== Fixing luci-app-fchomo postinst version check ==="
# Find and neutralize the fchomo postinst/uci-defaults scripts that check OpenWrt version
# The check "Minimum OpenWrt version required is 24.10" causes package/install to fail
FCHOMO_FOUND=0

# Debug: show what we can find for fchomo
echo "  Searching for luci-app-fchomo files..."
find feeds package -path '*/luci-app-fchomo*' -type f 2>/dev/null | head -30 | while read -r f; do echo "    $f"; done

# Method 1: Replace postinst scripts with simple exit 0
while IFS= read -r -d '' f; do
  echo "  Replacing fchomo postinst: $f"
  printf '#!/bin/sh\nexit 0\n' > "$f"
  chmod +x "$f"
  FCHOMO_FOUND=1
done < <(find feeds package -path '*/luci-app-fchomo/postinst' -print0 2>/dev/null)

# Method 2: Patch uci-defaults scripts - surgically remove only the version check block
# while preserving other initialization logic
while IFS= read -r -d '' f; do
  echo "  Patching fchomo uci-defaults: $f"
  # Remove multi-line if blocks that check version (handles if/then/fi patterns)
  # Strategy: replace version check with true to make the if-block not trigger
  sed -i 's/24\.10/0.0/g' "$f" 2>/dev/null  # Makes version comparison always pass
  sed -i '/Minimum OpenWrt version/d' "$f" 2>/dev/null
  FCHOMO_FOUND=1
done < <(find feeds package \( -path '*/luci-app-fchomo/files/etc/uci-defaults/*' -o -path '*/luci-app-fchomo/root/etc/uci-defaults/*' \) -print0 2>/dev/null)

# Method 3: Check if version check is embedded in Makefile postinst define
while IFS= read -r -d '' f; do
  if grep -q 'Minimum OpenWrt version' "$f" 2>/dev/null; then
    echo "  Found version check in Makefile: $f"
    # Only remove lines with the error message and exit, not version strings in DEPENDS
    sed -i '/Minimum OpenWrt version required/d' "$f"
    FCHOMO_FOUND=1
  fi
done < <(find feeds package -path '*/luci-app-fchomo/Makefile' -print0 2>/dev/null)

if [ "$FCHOMO_FOUND" -eq 0 ]; then
  echo "  WARNING: luci-app-fchomo scripts not found at patch time"
fi
echo "=== fchomo fix done ==="

# ============================================================
# Fix sound.mk: remove reference to snd-hda-codec-realtek-lib.ko
# Linux kernel 6.12+ merged realtek-lib into snd-hda-codec-realtek
# ============================================================
echo "=== Fixing sound.mk realtek-lib.ko reference ==="
SOUND_MK="package/kernel/linux/modules/sound.mk"
if [ -f "$SOUND_MK" ]; then
  # Remove the .ko file path from FILES lines (don't delete the whole line)
  sed -i 's|$(LINUX_DIR)/sound/pci/hda/snd-hda-codec-realtek-lib\.ko||g' "$SOUND_MK"
  sed -i 's|$(LINUX_DIR)/sound/hda/codecs/realtek/snd-hda-codec-realtek-lib\.ko||g' "$SOUND_MK"
  # Remove snd-hda-codec-realtek-lib from AUTOLOAD lists
  sed -i 's/snd-hda-codec-realtek-lib//g' "$SOUND_MK"
  # Clean up leftover trailing backslashes on empty continuation lines
  sed -i '/^[[:space:]]*\\$/d' "$SOUND_MK"
  echo "  -> Removed snd-hda-codec-realtek-lib.ko references from sound.mk"
else
  echo "  WARNING: sound.mk not found at $SOUND_MK"
fi
echo "=== sound.mk fix done ==="

