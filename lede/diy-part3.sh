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
# Fix 1: Remove duplicate/conflicting packages (keep only one provider)
# ============================================================
echo "=== Removing duplicate mihomo packages ==="
rm -rf feeds/kenzok8/mihomo feeds/kenzo/mihomo feeds/xuanranran/mihomo feeds/haiibo/mihomo feeds/liuran/mihomo feeds/nikki/mihomo
rm -rf package/feeds/kenzok8/mihomo package/feeds/kenzo/mihomo package/feeds/xuanranran/mihomo package/feeds/haiibo/mihomo package/feeds/liuran/mihomo package/feeds/nikki/mihomo
echo "  Done: Keeping feeds/small/mihomo as sole mihomo provider"

echo "=== Removing conflicting clashoo from nikki feed ==="
rm -rf feeds/nikki/clashoo package/feeds/nikki/clashoo
rm -rf feeds/nikki/luci-app-clashoo package/feeds/nikki/luci-app-clashoo
rm -rf feeds/nikki/luci-i18n-clashoo-zh-cn package/feeds/nikki/luci-i18n-clashoo-zh-cn 2>/dev/null
echo "  Done: Removed feeds/nikki/clashoo and luci-app-clashoo to prevent architecture conflict with feeds/small/clashoo"

# ============================================================
# Fix 2: Patch nikki Makefile - depend on mihomo instead of providing it
# ============================================================
echo "=== Patching nikki Makefile ==="
patch_nikki_makefile() {
  local makefile="$1"
  if [ ! -f "$makefile" ]; then
    echo "  WARNING: $makefile not found!"
    return 1
  fi
  
  echo "  Patching: $makefile"
  
  # Remove old install section (entire block)
  sed -i '/^define Package\/nikki\/install$/,/^endef$/d' "$makefile"
  
  # Remove PROVIDES and ALTERNATIVES (mihomo conflict)
  sed -i '/PROVIDES:=/d' "$makefile"
  sed -i '/ALTERNATIVES:=/d' "$makefile"
  
  # Remove all Go compilation related lines
  sed -i '/GoBinPackage/d' "$makefile"
  sed -i '/GoPackage/d' "$makefile"
  sed -i '/golang-build/d' "$makefile"
  sed -i '/GO_PKG/d' "$makefile"
  sed -i '/GO_BUILD/d' "$makefile"
  sed -i '/GO_MOD/d' "$makefile"
  sed -i '/GO_INSTALL/d' "$makefile"
  sed -i '/GO_LDFLAGS/d' "$makefile"
  sed -i '/GO_TAGS/d' "$makefile"
  sed -i '/GO_EXTRA/d' "$makefile"
  sed -i '/GOLANG_PKG/d' "$makefile"
  sed -i '/PKG_BUILD_DEPENDS.*golang/d' "$makefile"
  sed -i '/include.*golang/d' "$makefile"
  
  # Remove old mihomo binary install lines (but keep symlink in new install section)
  sed -i '/\/usr\/libexec\/nikki/d' "$makefile"

  # Remove empty Build/Compile section if exists
  sed -i '/^define Build\/Compile$/,/^endef$/d' "$makefile"

  # Force PKGARCH:=all (symlink-only package is arch-independent)
  sed -i 's/^PKGARCH:=.*/PKGARCH:=all/' "$makefile"
  if ! grep -q 'PKGARCH:=' "$makefile"; then
    sed -i '/^include.*$/i PKGARCH:=all' "$makefile"
  fi

  # Add +mihomo dependency with proper spacing (handle various indent formats)
  if ! grep -q '+mihomo' "$makefile"; then
    sed -i 's/^\([[:space:]]*DEPENDS:=\)/\1 +mihomo /' "$makefile"
  fi
  
  # Append new clean install section at end of file
  cat >> "$makefile" << 'INSTALL_EOF'

define Package/nikki/install
	$(INSTALL_DIR) $(1)/usr/libexec/
	$(LN) /usr/bin/mihomo $(1)/usr/libexec/nikki
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/nikki.init $(1)/etc/init.d/nikki
endef
INSTALL_EOF
  
  echo "  -> Done: $makefile"
}

patch_nikki_makefile "feeds/nikki/nikki/Makefile"
patch_nikki_makefile "package/feeds/nikki/nikki/Makefile"

# ============================================================
# Fix 3: Patch clashoo Makefile - depend on mihomo instead of providing it
# ============================================================
echo "=== Patching clashoo Makefile ==="
patch_clashoo_makefile() {
  local makefile="$1"
  if [ ! -f "$makefile" ]; then
    return 1
  fi
  
  echo "  Patching: $makefile"

  # Step 1: Remove old install section (entire block)
  sed -i '/^define Package\/clashoo\/install$/,/^endef$/d' "$makefile"

  # Step 2: Remove PROVIDES and ALTERNATIVES (mihomo conflict)
  sed -i '/PROVIDES:=/d' "$makefile"
  sed -i '/ALTERNATIVES:=/d' "$makefile"
  sed -i '/ALTERNATIVES.*mihomo/d' "$makefile"

  # Step 3: Remove ALL Go compilation related lines (prevents auto-install of mihomo binary)
  sed -i '/GoBinPackage/d' "$makefile"
  sed -i '/GoPackage/d' "$makefile"
  sed -i '/golang-build/d' "$makefile"
  sed -i '/GO_PKG/d' "$makefile"
  sed -i '/GO_BUILD/d' "$makefile"
  sed -i '/GO_MOD/d' "$makefile"
  sed -i '/GO_INSTALL/d' "$makefile"
  sed -i '/GO_LDFLAGS/d' "$makefile"
  sed -i '/GO_TAGS/d' "$makefile"
  sed -i '/GO_EXTRA/d' "$makefile"
  sed -i '/GOLANG_PKG/d' "$makefile"
  sed -i '/PKG_BUILD_DEPENDS.*golang/d' "$makefile"
  sed -i '/include.*golang/d' "$makefile"

  # Step 4: Remove any remaining INSTALL_BIN/LN lines that reference mihomo
  sed -i '/INSTALL_BIN.*mihomo/d' "$makefile"
  sed -i '/LN.*mihomo/d' "$makefile"
  sed -i '/\/usr\/bin\/mihomo/d' "$makefile"
  sed -i '/\/usr\/libexec\/clashoo/d' "$makefile"

  # Step 5: Remove empty Build/Compile section if exists
  sed -i '/^define Build\/Compile$/,/^endef$/d' "$makefile"

  # Step 5.5: Force PKGARCH:=all (symlink-only package is arch-independent)
  sed -i 's/^PKGARCH:=.*/PKGARCH:=all/' "$makefile"
  if ! grep -q 'PKGARCH:=' "$makefile"; then
    sed -i '/^include.*$/i PKGARCH:=all' "$makefile"
  fi

  # Step 6: Add +mihomo dependency with proper spacing
  if ! grep -q '+mihomo' "$makefile"; then
    sed -i 's/^\([[:space:]]*DEPENDS:=\)/\1 +mihomo /' "$makefile"
  fi

  # Step 7: Append new clean install section (symlink-only, no binary)
  cat >> "$makefile" << 'INSTALL_EOF'

define Package/clashoo/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(LN) /usr/bin/mihomo $(1)/usr/bin/clashoo
endef
INSTALL_EOF
  
  echo "  -> Done: $makefile"
}

for cf in feeds/small/clashoo/Makefile feeds/kenzo/clashoo/Makefile feeds/kenzok8/clashoo/Makefile \
          package/feeds/small/clashoo/Makefile package/feeds/kenzo/clashoo/Makefile package/feeds/kenzok8/clashoo/Makefile; do
  patch_clashoo_makefile "$cf"
done

# ============================================================
# Fix 3.5: Patch mihomo Makefile - remove ALTERNATIVES to prevent symlink conflicts
# ============================================================
echo "=== Patching mihomo Makefile ==="
patch_mihomo_makefile() {
  local makefile="$1"
  if [ ! -f "$makefile" ]; then
    return 1
  fi

  echo "  Patching: $makefile"

  sed -i '/ALTERNATIVES:=/d' "$makefile"
  sed -i '/ALTERNATIVES.*mihomo/d' "$makefile"

  echo "  -> Done: $makefile"
}

for mf in feeds/small/mihomo/Makefile package/feeds/small/mihomo/Makefile \
          feeds/kenzo/mihomo/Makefile package/feeds/kenzo/mihomo/Makefile \
          feeds/kenzok8/mihomo/Makefile package/feeds/kenzok8/mihomo/Makefile; do
  patch_mihomo_makefile "$mf"
done

# ============================================================
# Fix 3.6: Patch luci-app-clashoo Makefile - fix dependency on clashoo
# ============================================================
echo "=== Patching luci-app-clashoo Makefile ==="
patch_luci_clashoo_makefile() {
  local makefile="$1"
  if [ ! -f "$makefile" ]; then
    return 1
  fi
  
  echo "  Patching: $makefile"
  
  # Force PKGARCH:=all (luci app is arch-independent)
  sed -i 's/^PKGARCH:=.*/PKGARCH:=all/' "$makefile"
  if ! grep -q 'PKGARCH:=' "$makefile"; then
    sed -i '/^include.*$/i PKGARCH:=all' "$makefile"
  fi
  
  # Ensure +clashoo dependency exists
  if ! grep -q '+clashoo' "$makefile"; then
    sed -i 's/^\([[:space:]]*DEPENDS:=\)/\1 +clashoo /' "$makefile"
  fi
  
  echo "  -> Done: $makefile"
}

for lf in feeds/small/luci-app-clashoo/Makefile feeds/kenzo/luci-app-clashoo/Makefile feeds/kenzok8/luci-app-clashoo/Makefile \
          package/feeds/small/luci-app-clashoo/Makefile package/feeds/kenzo/luci-app-clashoo/Makefile package/feeds/kenzok8/luci-app-clashoo/Makefile; do
  patch_luci_clashoo_makefile "$lf"
done

# ============================================================
# Fix 3.7: Remove stale mihomo binary from staging to prevent alternatives conflict
# ============================================================
echo "=== Cleaning stale mihomo binary from staging ==="
# The error "/usr/bin/mihomo exists but is not a symlink" means a previous build
# left a real binary file. Clean it from staging/build dirs to prevent conflict.
STAGING_DIR="$(pwd)/staging_dir"
BUILD_DIR="$(pwd)/build_dir"
if [ -d "$STAGING_DIR" ]; then
  find "$STAGING_DIR" -name "mihomo" -type f ! -type l -delete 2>/dev/null || true
  echo "  Cleaned mihomo from staging_dir"
fi
if [ -d "$BUILD_DIR" ]; then
  find "$BUILD_DIR" -path "*/root-x86/usr/bin/mihomo" -type f ! -type l -delete 2>/dev/null || true
  echo "  Cleaned mihomo from build_dir/root-x86"
fi

# ============================================================
# Fix 4: Re-index patched packages to refresh dependency resolution
# ============================================================
echo "=== Re-indexing patched packages ==="
./scripts/feeds install -f -p small mihomo 2>/dev/null || echo "  (mihomo re-index skipped)"
./scripts/feeds install -f -p small clashoo 2>/dev/null || echo "  (clashoo re-index skipped)"
./scripts/feeds install -f -p small luci-app-clashoo 2>/dev/null || echo "  (luci-app-clashoo re-index skipped)"
./scripts/feeds install -f -p nikki nikki 2>/dev/null || echo "  (nikki re-index skipped)"
./scripts/feeds install -f -p nikki luci-app-nikki 2>/dev/null || echo "  (luci-app-nikki re-index skipped)"
echo "  Done: Package index refreshed"

echo "=== All fixes applied successfully ==="




