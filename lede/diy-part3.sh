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

rm -rf feeds/nikki/clashoo
rm -rf feeds/nikki/mihomo-meta
rm -rf feeds/nikki/mihomo-alpha
rm -rf feeds/kenzok8/mihomo
rm -rf feeds/kenzok8/luci-app-mihomo
rm -rf feeds/small/mihomo
rm -rf feeds/kenzo/mihomo
rm -rf feeds/xuanranran/mihomo
rm -rf feeds/haiibo/mihomo
rm -rf feeds/liuran/mihomo

# ============================================================
# Fix nikki: prevent it from installing /usr/bin/mihomo
# The nikki Makefile uses GoBinPackage macro which auto-generates
# install rules for /usr/bin/mihomo, conflicting with the separate
# mihomo package. We strip all Go build infrastructure so nikki
# becomes a pure config/script package depending on mihomo binary.
# ============================================================

echo "=== Fixing nikki mihomo conflict ==="
NIKKI_MAKEFILE="feeds/nikki/nikki/Makefile"

if [ -f "$NIKKI_MAKEFILE" ]; then
  echo "  Found: $NIKKI_MAKEFILE"

  # --- Remove Go build infrastructure ---
  # Remove golang-package.mk include (provides GoBinPackage macro)
  sed -i '\|golang-package\.mk|d' "$NIKKI_MAKEFILE"

  # Remove PKG_BUILD_DEPENDS golang
  sed -i '/PKG_BUILD_DEPENDS.*golang/d' "$NIKKI_MAKEFILE"

  # Remove all GO_PKG* variables (GO_PKG, GO_PKG_LDFLAGS_X, GO_PKG_TAGS, etc.)
  sed -i '/^GO_PKG/d' "$NIKKI_MAKEFILE"

  # Remove $(GO_ARCH_DEPENDS) from DEPENDS (with or without space after)
  sed -i 's/\$(GO_ARCH_DEPENDS) *//g' "$NIKKI_MAKEFILE"

  # Remove PROVIDES/ALTERNATIVES for mihomo (older versions)
  sed -i '/PROVIDES.*mihomo/d' "$NIKKI_MAKEFILE"
  sed -i '/ALTERNATIVES/d' "$NIKKI_MAKEFILE"

  # Remove empty Build/Compile override
  sed -i '/^define Build\/Compile$/,/^endef$/d' "$NIKKI_MAKEFILE"

  # --- CRITICAL: Replace GoBinPackage with BuildPackage ---
  # GoBinPackage auto-installs the Go binary to /usr/bin/mihomo
  # BuildPackage only uses the custom define Package/nikki/install
  sed -i 's/GoBinPackage/BuildPackage/g' "$NIKKI_MAKEFILE"

  # --- Catch any remaining Go-related lines ---
  sed -i '/GO_BUILD/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_INSTALL/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_LDFLAGS/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_TAGS/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_MOD/d' "$NIKKI_MAKEFILE"
  sed -i '/GoPackage/d' "$NIKKI_MAKEFILE"
  sed -i '/golang-build/d' "$NIKKI_MAKEFILE"

  # --- Ensure +mihomo dependency exists ---
  sed -i '/DEPENDS:=/{ /+mihomo/!s/\(DEPENDS:=.*\)/\1 +mihomo/ }' "$NIKKI_MAKEFILE"

  # --- Force clean rebuild to discard any cached Go build results ---
  rm -rf build_dir/target-*/nikki-* 2>/dev/null
  rm -rf package/feeds/nikki/nikki/*.ipk 2>/dev/null

  echo "  -> nikki fix applied successfully"
  echo "  --- Debug: modified Makefile key lines ---"
  grep -n 'GoBin\|BuildPackage\|GO_PKG\|golang\|PROVIDES\|ALTERNATIVES\|mihomo\|GoPackage' "$NIKKI_MAKEFILE" || echo "  (no matching Go/mihomo lines found)"
else
  echo "  WARNING: nikki Makefile not found at $NIKKI_MAKEFILE!"
fi
echo "=== nikki fix done ==="

# ============================================================
# Fix clashoo: depend on mihomo package instead of providing its own binary
# clashoo should use the mihomo package (not nikki) for the binary
# ============================================================
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
    # Add +mihomo to DEPENDS (not +nikki, since nikki doesn't provide mihomo)
    sed -i '/DEPENDS:=/{ /+mihomo/!s/^\([[:space:]]*DEPENDS:=.*\)/\1 +mihomo/ }' "$clashoo_makefile"
    echo "  -> Added +mihomo to DEPENDS"
    # Remove Go binary install lines
    sed -i '\|GoPackage/Package/Install/Bin|d' "$clashoo_makefile"
    sed -i '/GoBinPackage/d' "$clashoo_makefile"
    echo "  -> Removed Go binary install"
  fi
done
if [ "$CLASHOO_FOUND" -eq 0 ]; then
  echo "  WARNING: clashoo Makefile not found in any expected location!"
fi
echo "=== clashoo fix done ==="

