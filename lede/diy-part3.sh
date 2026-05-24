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
# Fix nikki/mihomo/clashoo file conflict
#
# Problem: nikki, mihomo, and clashoo all install /usr/bin/mihomo
#   - nikki: compiles mihomo from source, installs to /usr/libexec/nikki,
#            then uses ALTERNATIVES to create /usr/bin/mihomo symlink
#   - mihomo: compiles mihomo from source, installs directly to /usr/bin/mihomo
#   - clashoo: similar to nikki, also provides /usr/bin/mihomo
#
# Solution:
#   1. Patch nikki Makefile: remove mihomo binary compilation/installation,
#      add +mihomo dependency so it uses the standalone mihomo package
#   2. Patch clashoo Makefile: same approach as nikki
#   3. Keep one mihomo package (from small feed) as the sole provider
#   4. Remove duplicate mihomo packages from other feeds
#   5. Reinstall the patched feeds so the package index is updated
# ============================================================

echo "=== Step 1: Remove duplicate mihomo packages ==="
rm -rf feeds/kenzok8/mihomo
rm -rf feeds/kenzok8/luci-app-mihomo
rm -rf feeds/kenzo/mihomo
rm -rf feeds/xuanranran/mihomo
rm -rf feeds/haiibo/mihomo
rm -rf feeds/liuran/mihomo
rm -rf package/feeds/kenzok8/mihomo
rm -rf package/feeds/kenzo/mihomo
rm -rf package/feeds/xuanranran/mihomo
rm -rf package/feeds/haiibo/mihomo
rm -rf package/feeds/liuran/mihomo
echo "  Removed mihomo from kenzok8, kenzo, xuanranran, haiibo, liuran feeds"
echo "  Keeping feeds/small/mihomo as the sole mihomo provider"

echo "=== Step 2: Patch nikki Makefile ==="
patch_nikki_makefile() {
  local makefile="$1"
  if [ ! -f "$makefile" ]; then
    echo "  WARNING: $makefile not found!"
    return 1
  fi
  
  echo "  Patching: $makefile"
  
  sed -i '/PROVIDES:=/d' "$makefile"
  sed -i '/ALTERNATIVES:=/d' "$makefile"
  sed -i '/mihomo/d' "$makefile"
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
  sed -i '/\/usr\/bin\/mihomo/d' "$makefile"
  sed -i '/\/usr\/libexec\/nikki/d' "$makefile"
  
  if ! grep -q '+mihomo' "$makefile"; then
    sed -i 's/^\(  DEPENDS:=\)/\1 +mihomo/' "$makefile"
  fi
  
  sed -i '/^define Package\/nikki\/install$/,/^endef$/d' "$makefile"
  sed -i '/^define Package\/nikki\/install$/a\\t$(INSTALL_DIR) $(1)/usr/libexec/\n\t$(LN) /usr/bin/mihomo $(1)/usr/libexec/nikki\n\t$(INSTALL_DIR) $(1)/etc/init.d\n\t$(INSTALL_BIN) ./files/nikki.init $(1)/etc/init.d/nikki' "$makefile"
  
  echo "  -> Done: $makefile"
}

patch_nikki_makefile "feeds/nikki/nikki/Makefile"
patch_nikki_makefile "package/feeds/nikki/nikki/Makefile"

echo "=== Step 3: Patch clashoo Makefile ==="
patch_clashoo_makefile() {
  local makefile="$1"
  if [ ! -f "$makefile" ]; then
    return 1
  fi
  
  echo "  Patching: $makefile"
  sed -i '/PROVIDES:=/d' "$makefile"
  sed -i '/ALTERNATIVES:=/d' "$makefile"
  sed -i '/mihomo/d' "$makefile"
  sed -i '/GoBinPackage/d' "$makefile"
  sed -i '/GoPackage/d' "$makefile"
  sed -i '/golang-build/d' "$makefile"
  sed -i '/GO_PKG/d' "$makefile"
  sed -i '/GO_BUILD/d' "$makefile"
  
  if ! grep -q '+mihomo' "$makefile"; then
    sed -i 's/^\(  DEPENDS:=\)/\1 +mihomo/' "$makefile"
  fi
  
  echo "  -> Done: $makefile"
}

for cf in feeds/small/clashoo/Makefile feeds/kenzo/clashoo/Makefile feeds/kenzok8/clashoo/Makefile \
          package/feeds/small/clashoo/Makefile package/feeds/kenzo/clashoo/Makefile package/feeds/kenzok8/clashoo/Makefile; do
  patch_clashoo_makefile "$cf"
done

echo "=== Step 4: Update feeds ==="
./scripts/feeds install -p nikki nikki luci-app-nikki 2>/dev/null || true
./scripts/feeds install -p small clashoo 2>/dev/null || true
./scripts/feeds install -p kenzo clashoo 2>/dev/null || true
./scripts/feeds install -p kenzok8 clashoo 2>/dev/null || true

echo "=== mihomo conflict fix done ==="

# ============================================================
# Fix luci-app-fchomo postinst version check failure
#
# Problem: fchomo postinst checks OpenWrt version >= 24.10
# During make package/install, /etc/openwrt_release may not
# exist in staging root, causing postinst to fail with exit 1
#
# Solution: Replace the postinst with a no-op script
# ============================================================

echo "=== Fixing luci-app-fchomo postinst version check ==="

# Function to patch postinst file
patch_postinst() {
  local target_dir="$1"
  if [ -d "$target_dir" ]; then
    mkdir -p "$target_dir/files"
    cat > "$target_dir/files/luci-app-fchomo.postinst" << 'POSTINST_EOF'
#!/bin/sh
# [patched] Original version check removed - always succeeds
exit 0
POSTINST_EOF
    chmod 755 "$target_dir/files/luci-app-fchomo.postinst"
    echo "  -> Patched: $target_dir"
    
    # Also patch preinst if exists
    if [ -f "$target_dir/files/luci-app-fchomo.preinst" ]; then
      cat > "$target_dir/files/luci-app-fchomo.preinst" << 'PREINST_EOF'
#!/bin/sh
# [patched] Original preinst removed - always succeeds
exit 0
PREINST_EOF
      chmod 755 "$target_dir/files/luci-app-fchomo.preinst"
      echo "  -> Also patched preinst: $target_dir"
    fi
  fi
}

# Patch both feed source and package/feeds copy
PATCHED=0
for feed_dir in feeds/helloworld/luci-app-fchomo feeds/small/luci-app-fchomo feeds/kenzo/luci-app-fchomo feeds/kenzok8/luci-app-fchomo; do
  patch_postinst "$feed_dir"
  PATCHED=1
done

for pkg_dir in package/feeds/helloworld/luci-app-fchomo package/feeds/small/luci-app-fchomo package/feeds/kenzo/luci-app-fchomo package/feeds/kenzok8/luci-app-fchomo; do
  patch_postinst "$pkg_dir"
  PATCHED=1
done

# Reinstall the feed to make sure changes are picked up
if [ "$PATCHED" -eq 1 ]; then
  echo "  -> Reinstalling luci-app-fchomo feed..."
  for feed in helloworld small kenzo kenzok8; do
    if [ -d "feeds/$feed/luci-app-fchomo" ]; then
      ./scripts/feeds install -p "$feed" luci-app-fchomo 2>/dev/null || true
    fi
  done
fi

if [ "$PATCHED" -eq 0 ]; then
  echo "  WARNING: luci-app-fchomo not found in any feed!"
fi
echo "=== fchomo postinst fix done ==="


# ./scripts/feeds update -a
# ./scripts/feeds install -p kenzok8 luci-app-transmission
# ./scripts/feeds install -p kenzok8 transmission
# ./scripts/feeds install -p kenzok8 transmission-web-control
# ./scripts/feeds install -p kenzok8 smartdns
# ./scripts/feeds install -p kenzok8 luci-app-smartdns
# ./scripts/feeds install -p Joecaicai luci-app-qbittorrent
# ./scripts/feeds install -p Joecaicai qBittorrent-Enhanced-Edition
# ./scripts/feeds install -a
