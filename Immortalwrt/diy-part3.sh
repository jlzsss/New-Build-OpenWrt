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
rm -rf feeds/luci/transmission
rm -rf feeds/luci/transmission-web-control
rm -rf feeds/luci2/luci-app-turboacc
./scripts/feeds install -p packages2 quickstart
./scripts/feeds install -p packages2 luci-app-quickstart
./scripts/feeds install -p luci2 transmission
./scripts/feeds install -p luci2 transmission-web-control
rm -rf feeds/packages/net/{qBittorrent,qBittorrent-static,xray-core,v2ray-geodata,sing-box,chinadns-ng,nikki,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls,haproxy}
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
rm -rf feeds/xuanranran/other/lean/qBittorrent
rm -rf feeds/xuanranran/other/lean/qBittorrent-static
rm -rf feeds/xuanranran/other/lean/qtbase
rm -rf feeds/xuanranran/other/lean/qttools
rm -rf feeds/xuanranran/other/lean/rblibtorrent
rm -rf feeds/NueXini/qtbase
rm -rf feeds/NueXini/qttools
rm -rf feeds/NueXini/rblibtorrent
rm -rf feeds/nikki
rm -rf feeds/kenzok8/mihomo
rm -rf feeds/kenzok8/luci-app-mihomo
rm -rf feeds/small/mihomo
rm -rf feeds/kenzo/mihomo
rm -rf feeds/xuanranran/mihomo
rm -rf feeds/haiibo/mihomo
rm -rf feeds/liuran/mihomo
# feeds/nikki completely removed; feeds/packages/net/nikki is the sole nikki provider

# ============================================================
# Fix nikki: make it depend on mihomo feed package instead of building its own
# ============================================================

echo "=== Fixing nikki mihomo conflict ==="
NIKKI_MAKEFILE="feeds/small/nikki/Makefile"

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
  
  # Add symlink for init scripts
  sed -i '/^define Package\/nikki\/install/a\\t$(INSTALL_DIR) $(1)/usr/libexec\n\t$(LN) /usr/bin/mihomo $(1)/usr/libexec/nikki' "$NIKKI_MAKEFILE"
  echo "  -> Added symlink /usr/libexec/nikki -> /usr/bin/mihomo"
else
  echo "  WARNING: nikki Makefile not found!"
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

# Fix v2dat: the package Makefile forces CGO_ENABLED=0, but golang-package.mk's
# GO_PKG_DEFAULT_LDFLAGS always carries "-linkmode external", and Go rejects that
# combination with: "-linkmode requires external (cgo) linking, but cgo is not enabled".
# Solution: force CGO_ENABLED=1 at the golang build system level and override ldflags.
echo "=== Fixing v2dat linkmode issue ==="

# Step 1: Patch golang-package.mk to set CGO_ENABLED=1
# This is the primary fix - golang-package.mk defines CGO_ENABLED which gets passed
# to golang-build.sh as an environment variable prefix
echo "=== Patching golang-package.mk ==="
GOLANG_PKG_MK=$(find feeds/packages/lang/golang -name "golang-package.mk" -type f 2>/dev/null | head -1)
if [ -n "$GOLANG_PKG_MK" ]; then
  echo "  Found: $GOLANG_PKG_MK"
  # Try multiple patterns: CGO_ENABLED := 0, CGO_ENABLED ?= 0, CGO_ENABLED = 0, etc.
  if grep -qE '^\s*CGO_ENABLED\s*[:?]?=' "$GOLANG_PKG_MK"; then
    sed -i -E 's/^[[:space:]]*CGO_ENABLED[[:space:]]*[:?]?=[[:space:]]*.*/CGO_ENABLED := 1/' "$GOLANG_PKG_MK"
    echo "  -> Set CGO_ENABLED := 1 in golang-package.mk"
  else
    # If not found, add it at the top
    sed -i '1iCGO_ENABLED := 1' "$GOLANG_PKG_MK"
    echo "  -> Added CGO_ENABLED := 1 at top of golang-package.mk"
  fi
else
  echo "  WARNING: golang-package.mk not found in feeds/packages/lang/golang"
fi

# Step 2: Patch golang-build.sh to force CGO_ENABLED=1
# golang-build.sh may set CGO_ENABLED=0 internally via CGO_ENABLED="${CGO_ENABLED:-0}"
echo "=== Patching golang-build.sh ==="
GOLANG_BUILD_SH=$(find feeds/packages/lang/golang -name "golang-build.sh" -type f 2>/dev/null | head -1)
if [ -n "$GOLANG_BUILD_SH" ]; then
  echo "  Found: $GOLANG_BUILD_SH"
    # Replace CGO_ENABLED=0 and CGO_ENABLED="${CGO_ENABLED:-0}" patterns
    sed -i 's/CGO_ENABLED=0/CGO_ENABLED=1/g' "$GOLANG_BUILD_SH"
    sed -i 's/CGO_ENABLED="${CGO_ENABLED:-0}"/CGO_ENABLED="${CGO_ENABLED:-1}"/g' "$GOLANG_BUILD_SH"
    # Also ensure CGO_ENABLED=1 is exported at the top
  if ! grep -q 'export CGO_ENABLED=1' "$GOLANG_BUILD_SH"; then
    sed -i '1iexport CGO_ENABLED=1' "$GOLANG_BUILD_SH"
    echo "  -> Added export CGO_ENABLED=1 at top"
  fi
  echo "  -> Fixed CGO_ENABLED references"
else
  echo "  WARNING: golang-build.sh not found"
fi

# Step 3: Patch the golang build script in the openwrt tree (if already installed)
echo "=== Patching installed golang scripts ==="
GOLANG_BUILD_INSTALLED=$(find openwrt/feeds/packages/lang/golang -name "golang-build.sh" -type f 2>/dev/null | head -1)
if [ -n "$GOLANG_BUILD_INSTALLED" ]; then
  if grep -q 'CGO_ENABLED=0' "$GOLANG_BUILD_INSTALLED"; then
    sed -i 's/CGO_ENABLED=0/CGO_ENABLED=1/g' "$GOLANG_BUILD_INSTALLED"
    echo "  -> Fixed installed golang-build.sh"
  fi
fi
GOLANG_PKG_INSTALLED=$(find openwrt/feeds/packages/lang/golang -name "golang-package.mk" -type f 2>/dev/null | head -1)
if [ -n "$GOLANG_PKG_INSTALLED" ]; then
  if grep -qE 'CGO_ENABLED' "$GOLANG_PKG_INSTALLED"; then
    sed -i -E 's/^[[:space:]]*CGO_ENABLED[[:space:]]*[:?]?=[[:space:]]*.*/CGO_ENABLED := 1/' "$GOLANG_PKG_INSTALLED"
    echo "  -> Fixed installed golang-package.mk"
  fi
fi

# Step 4: Fix v2dat Makefile - override GO_PKG_DEFAULT_LDFLAGS to drop -linkmode external
echo "=== Fixing v2dat Makefile ==="
V2DAT_MAKEFILE="feeds/haiibo/v2dat/Makefile"
if [ -f "$V2DAT_MAKEFILE" ]; then
  echo "  Found: $V2DAT_MAKEFILE"
  # Remove any previous patches
  sed -i '/^# CGO_ENABLED=0: keep Go.*internal linker/d' "$V2DAT_MAKEFILE"
  sed -i '/^GO_PKG_DEFAULT_LDFLAGS=-buildid/d' "$V2DAT_MAKEFILE"
  # Remove any previous appended blocks
  sed -i '/^# Enable CGO so -linkmode external works/,/^V2DAT_PATCH$/d' "$V2DAT_MAKEFILE"
  # Append the fix
  cat >> "$V2DAT_MAKEFILE" <<'V2DAT_PATCH'

# Override Go linker flags: drop -linkmode external so it works with any CGO setting
GO_PKG_DEFAULT_LDFLAGS=-buildid '$(SOURCE_DATE_EPOCH)'
V2DAT_PATCH
  echo "  -> Overrode GO_PKG_DEFAULT_LDFLAGS (dropped -linkmode external)"
else
  echo "  WARNING: v2dat Makefile not found at $V2DAT_MAKEFILE"
fi
echo "=== v2dat fix done ==="

# ./scripts/feeds update -a
# ./scripts/feeds install -p kenzok8 luci-app-transmission
# ./scripts/feeds install -p kenzok8 transmission
# ./scripts/feeds install -p kenzok8 transmission-web-control
# ./scripts/feeds install -p kenzok8 smartdns
# ./scripts/feeds install -p kenzok8 luci-app-smartdns
# ./scripts/feeds install -p Joecaicai luci-app-qbittorrent
# ./scripts/feeds install -p Joecaicai qBittorrent-Enhanced-Edition
# ./scripts/feeds install -a
