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
# Fix kmod-ixgbe dependency: add +kmod-libie
# Replaces 005-fix-kmod-ixgbe-dependency.patch to avoid patch context mismatch
# ============================================================
echo "=== Adding kmod-libie to kmod-ixgbe DEPENDS ==="
sed -i '/^define KernelPackage\/ixgbe$/,/^endef$/{
  s/DEPENDS:=@PCI_SUPPORT +kmod-libcrc32c +kmod-ptp/DEPENDS:=@PCI_SUPPORT +kmod-libcrc32c +kmod-ptp +kmod-libie/
}' package/kernel/linux/modules/netdevices.mk
echo "=== kmod-ixgbe fix done ==="

# ============================================================
# Fix v2dat: the package Makefile forces CGO_ENABLED=0, but golang-package.mk's
# GO_PKG_DEFAULT_LDFLAGS always carries "-linkmode external", and Go rejects that
# combination with: "-linkmode requires external (cgo) linking, but cgo is not enabled".
# Redefine GO_PKG_DEFAULT_LDFLAGS (the variable actually used by GO_PKG_INSTALL_ARGS);
# GO_LDFLAGS does not exist in golang-package.mk.
# ============================================================
echo "=== Fixing v2dat linkmode issue ==="
V2DAT_MAKEFILE="feeds/haiibo/v2dat/Makefile"
if [ -f "$V2DAT_MAKEFILE" ]; then
  echo "  Found: $V2DAT_MAKEFILE"
  if grep -q 'GO_PKG_DEFAULT_LDFLAGS' "$V2DAT_MAKEFILE"; then
    echo "  -> Already patched"
  else
    cat >> "$V2DAT_MAKEFILE" <<'V2DAT_PATCH'

# CGO_ENABLED=0: keep Go's internal linker, drop -linkmode external
GO_PKG_DEFAULT_LDFLAGS=-buildid '$(SOURCE_DATE_EPOCH)'
V2DAT_PATCH
    echo "  -> Overrode GO_PKG_DEFAULT_LDFLAGS (dropped -linkmode external)"
  fi
else
  echo "  WARNING: v2dat Makefile not found at $V2DAT_MAKEFILE"
fi
echo "=== v2dat fix done ==="

# ============================================================
# Fix luci-app-netspeedtest: replace python3-pkg-resources with python3-light
# python3-pkg-resources doesn't exist in OpenWrt feeds; python3-light provides equivalent
# ============================================================
echo "=== Fixing netspeedtest python3-pkg-resources dependency ==="
NETSPEEDTEST_MAKEFILE="package/netspeedtest/Makefile"
if [ -f "$NETSPEEDTEST_MAKEFILE" ]; then
  echo "  Found: $NETSPEEDTEST_MAKEFILE"
  sed -i 's/python3-pkg-resources/python3-light/g' "$NETSPEEDTEST_MAKEFILE"
  echo "  -> Replaced python3-pkg-resources with python3-light"
else
  # Also try in feeds
  find feeds -path "*/netspeedtest/Makefile" -exec sed -i 's/python3-pkg-resources/python3-light/g' {} \; 2>/dev/null
  echo "  -> Patched feeds netspeedtest Makefiles"
fi
echo "=== netspeedtest fix done ==="

# ============================================================
# Fix luci-app-ssr-plus: replace bind-dig with bind-tools
# bind-dig is not a valid package name; bind-tools provides dig
# ============================================================
echo "=== Fixing ssr-plus bind-dig dependency ==="
SSR_PLUS_FOUND=0
for ssr_makefile in feeds/kenzok8/luci-app-ssr-plus/Makefile feeds/small/luci-app-ssr-plus/Makefile feeds/kenzo/luci-app-ssr-plus/Makefile; do
  if [ -f "$ssr_makefile" ]; then
    echo "  Found: $ssr_makefile"
    sed -i 's/bind-dig/bind-tools/g' "$ssr_makefile"
    echo "  -> Replaced bind-dig with bind-tools"
    SSR_PLUS_FOUND=1
  fi
done
# Also search package/ directory
for ssr_makefile in package/*/Makefile; do
  if [ -f "$ssr_makefile" ] && grep -q "bind-dig" "$ssr_makefile" 2>/dev/null; then
    echo "  Found: $ssr_makefile"
    sed -i 's/bind-dig/bind-tools/g' "$ssr_makefile"
    echo "  -> Replaced bind-dig with bind-tools"
    SSR_PLUS_FOUND=1
  fi
done
if [ "$SSR_PLUS_FOUND" -eq 0 ]; then
  echo "  WARNING: luci-app-ssr-plus Makefile not found, searching all feeds..."
  find feeds -name "Makefile" -exec sed -i 's/bind-dig/bind-tools/g' {} \; 2>/dev/null
  echo "  -> Searched all feed Makefiles"
fi
echo "=== ssr-plus fix done ==="

# ============================================================
# Fix architecture incompatibility: ensure packages support x86_64
# Remove architecture restrictions from problematic packages
# ============================================================
echo "=== Fixing architecture compatibility ==="
# Remove any Build/NoArchitecture or similar restrictions
find feeds package -name "Makefile" \( -path "*/netspeedtest/*" -o -path "*/luci-app-ssr-plus/*" \) -exec sed -i '/^  ARCH:/d; /^ARCH:=/d' {} \; 2>/dev/null
echo "=== architecture fix done ==="

# ============================================================
# Ensure python3-light and bind-tools are available
# ============================================================
echo "=== Ensuring required packages are available ==="
[ -d "feeds/packages/python/python3-light" ] && echo "python3-light available in feeds" || echo "WARNING: python3-light not found in feeds"
[ -d "feeds/packages/net/bind-tools" ] && echo "bind-tools available in feeds" || echo "WARNING: bind-tools not found in feeds"
echo "=== package availability check done ==="
