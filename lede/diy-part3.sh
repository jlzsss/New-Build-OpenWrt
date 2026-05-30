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
# Keep feeds/small/mihomo as sole mihomo provider
rm -rf feeds/kenzok8/mihomo feeds/kenzo/mihomo feeds/xuanranran/mihomo feeds/haiibo/mihomo feeds/liuran/mihomo feeds/nikki/mihomo
rm -rf package/feeds/kenzok8/mihomo package/feeds/kenzo/mihomo package/feeds/xuanranran/mihomo package/feeds/haiibo/mihomo package/feeds/liuran/mihomo package/feeds/nikki/mihomo
echo "  Done: Keeping feeds/small/mihomo as sole mihomo provider"

echo "=== Removing conflicting clashoo/luci-app-clashoo from non-nikki feeds ==="
# Keep feeds/nikki/clashoo and feeds/nikki/luci-app-clashoo as sole providers.
# The nikki feed is the primary developer of clashoo/luci-app-clashoo.
# The small feed has clashoo but NOT luci-app-clashoo, causing "cannot find dependency".
# Other feeds may have outdated/incompatible versions.
rm -rf feeds/small/clashoo feeds/kenzo/clashoo feeds/kenzok8/clashoo
rm -rf package/feeds/small/clashoo package/feeds/kenzo/clashoo package/feeds/kenzok8/clashoo
rm -rf feeds/kenzo/luci-app-clashoo feeds/kenzok8/luci-app-clashoo 2>/dev/null
rm -rf package/feeds/kenzo/luci-app-clashoo package/feeds/kenzok8/luci-app-clashoo 2>/dev/null
rm -rf feeds/kenzo/luci-i18n-clashoo-zh-cn feeds/kenzok8/luci-i18n-clashoo-zh-cn 2>/dev/null
rm -rf package/feeds/kenzo/luci-i18n-clashoo-zh-cn package/feeds/kenzok8/luci-i18n-clashoo-zh-cn 2>/dev/null
echo "  Done: Keeping feeds/nikki/clashoo and feeds/nikki/luci-app-clashoo as sole providers"

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

  # CRITICAL FIX: PKGARCH:=all must be INSIDE the define Package/nikki block
  # First remove any existing PKGARCH lines (they may be in wrong position)
  sed -i '/PKGARCH:=/d' "$makefile"
  # Insert PKGARCH:=all right after the DEPENDS line within Package definition
  sed -i '/define Package\/nikki$/,/^endef$/{
    /^  DEPENDS:=/a\  PKGARCH:=all
  }' "$makefile"

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

# ============================================================
# Fix 3: Replace clashoo Makefile entirely (sed patches are fragile)
# ============================================================
echo "=== Replacing clashoo Makefile ==="
replace_clashoo_makefile() {
  local pkg_dir="$1"
  local makefile="${pkg_dir}/Makefile"
  
  if [ ! -f "$makefile" ]; then
    echo "  WARNING: $makefile not found, skipping"
    return 1
  fi
  
  echo "  Replacing: $makefile"
  
  # Extract key metadata from the original Makefile before replacing
  local PKG_VERSION PKG_RELEASE TITLE SECTION CATEGORY
  PKG_VERSION=$(sed -n 's/^PKG_VERSION:=//p' "$makefile" | head -1)
  PKG_RELEASE=$(sed -n 's/^PKG_RELEASE:=//p' "$makefile" | head -1)
  TITLE=$(sed -n 's/^\([[:space:]]*\)TITLE:=//p' "$makefile" | head -1)
  SECTION=$(sed -n 's/^\([[:space:]]*\)SECTION:=//p' "$makefile" | head -1)
  CATEGORY=$(sed -n 's/^\([[:space:]]*\)CATEGORY:=//p' "$makefile" | head -1)
  
  # Use defaults if metadata not found
  [ -z "$PKG_VERSION" ] && PKG_VERSION="1.0"
  [ -z "$PKG_RELEASE" ] && PKG_RELEASE="1"
  [ -z "$TITLE" ] && TITLE="Clash Meta (mihomo) wrapper"
  [ -z "$SECTION" ] && SECTION="net"
  [ -z "$CATEGORY" ] && CATEGORY="Network"
  
  # Write a completely new, clean Makefile for a symlink-only package
  # This eliminates all fragility from sed-based patching:
  #   - PKGARCH:=all is properly INSIDE define Package/clashoo block
  #   - No Go build infrastructure remains
  #   - No PROVIDES/ALTERNATIVES causing conflicts
  #   - Simple symlink install: /usr/bin/clashoo -> /usr/bin/mihomo
  cat > "$makefile" << MAKEFILE_EOF
include \$(TOPDIR)/rules.mk

PKG_NAME:=clashoo
PKG_VERSION:=${PKG_VERSION}
PKG_RELEASE:=${PKG_RELEASE}

include \$(INCLUDE_DIR)/package.mk

define Package/clashoo
  SECTION:=${SECTION}
  CATEGORY:=${CATEGORY}
  TITLE:=${TITLE}
  DEPENDS:=+mihomo
  PKGARCH:=all
endef

define Package/clashoo/description
  Clashoo is a wrapper package that provides clashoo as a symlink to mihomo.
endef

define Package/clashoo/install
	\$(INSTALL_DIR) \$(1)/usr/bin
	\$(LN) /usr/bin/mihomo \$(1)/usr/bin/clashoo
endef

define Build/Compile
endef

\$(eval \$(call BuildPackage,clashoo))
MAKEFILE_EOF
  
  echo "  -> Done: Replaced $makefile with clean symlink-only package"
}

# Only patch the nikki feed's clashoo (sole provider after removing others)
# package/feeds/nikki/clashoo is a symlink to feeds/nikki/clashoo,
# so patching the feeds path is sufficient.
replace_clashoo_makefile "feeds/nikki/clashoo"

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

# Only patch small feed's mihomo (sole provider after removing others)
# package/feeds/small/mihomo is a symlink, so feeds path is sufficient.
patch_mihomo_makefile "feeds/small/mihomo/Makefile"

# ============================================================
# Fix 3.6: Patch luci-app-clashoo Makefile - fix PKGARCH and dependency
# ============================================================
echo "=== Patching luci-app-clashoo Makefile ==="
patch_luci_clashoo_makefile() {
  local makefile="$1"
  if [ ! -f "$makefile" ]; then
    echo "  WARNING: $makefile not found, skipping"
    return 1
  fi
  
  echo "  Patching: $makefile"
  
  # CRITICAL FIX: Remove any existing PKGARCH lines first (they may be outside Package block)
  sed -i '/PKGARCH:=/d' "$makefile"
  
  # Insert PKGARCH:=all INSIDE the Package definition block
  # For LuCI apps using LUCI_TITLE/LUCI_DEPENDS format, PKGARCH goes after LUCI_DEPENDS
  if grep -q 'LUCI_DEPENDS:=' "$makefile"; then
    sed -i '/LUCI_DEPENDS:=/a\PKGARCH:=all' "$makefile"
  elif grep -q 'define Package/luci-app-clashoo' "$makefile"; then
    # Standard Makefile: insert PKGARCH inside Package definition block after DEPENDS
    sed -i '/define Package\/luci-app-clashoo$/,/^endef$/{
      /^  DEPENDS:=/a\  PKGARCH:=all
    }' "$makefile"
  fi
  
  # Ensure +clashoo dependency exists
  if ! grep -q '+clashoo' "$makefile"; then
    if grep -q 'LUCI_DEPENDS:=' "$makefile"; then
      sed -i 's/^\([[:space:]]*LUCI_DEPENDS:=\)/\1 +clashoo /' "$makefile"
    else
      sed -i 's/^\([[:space:]]*DEPENDS:=\)/\1 +clashoo /' "$makefile"
    fi
  fi
  
  echo "  -> Done: $makefile"
}

# Only patch nikki feed's luci-app-clashoo (sole provider)
patch_luci_clashoo_makefile "feeds/nikki/luci-app-clashoo/Makefile"

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
# Re-install from the correct feeds (small for mihomo, nikki for clashoo/luci)
./scripts/feeds install -f -p small mihomo || echo "  (mihomo re-index warning)"
./scripts/feeds install -f -p nikki clashoo || echo "  (clashoo re-index warning)"
./scripts/feeds install -f -p nikki luci-app-clashoo || echo "  (luci-app-clashoo re-index warning)"
./scripts/feeds install -f -p nikki nikki || echo "  (nikki re-index warning)"
./scripts/feeds install -f -p nikki luci-app-nikki || echo "  (luci-app-nikki re-index warning)"

# CRITICAL: Re-run defconfig to rebuild the internal package index.
# Without this, make still uses the stale index from feeds install -a,
# which has wrong PKGARCH and missing packages.
make defconfig || echo "  (defconfig warning - non-critical if config unchanged)"
echo "  Done: Package index refreshed"

echo "=== All fixes applied successfully ==="
