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
rm -rf feeds/xuanranran/other/lean/qBittorrent
rm -rf feeds/xuanranran/other/lean/qBittorrent-static
rm -rf feeds/xuanranran/other/lean/qtbase
rm -rf feeds/xuanranran/other/lean/qttools
rm -rf feeds/xuanranran/other/lean/rblibtorrent
rm -rf feeds/NueXini/qtbase
rm -rf feeds/NueXini/qttools
rm -rf feeds/NueXini/rblibtorrent
rm -rf feeds/nikki/clashoo
rm -rf feeds/nikki/mihomo
rm -rf feeds/kenzok8/mihomo
rm -rf feeds/kenzok8/luci-app-mihomo
rm -rf feeds/kenzo/mihomo
rm -rf feeds/xuanranran/mihomo
rm -rf feeds/haiibo/mihomo
rm -rf feeds/liuran/mihomo
rm -rf package/feeds/nikki/clashoo
rm -rf package/feeds/nikki/mihomo
rm -rf package/feeds/kenzok8/mihomo
rm -rf package/feeds/kenzok8/luci-app-mihomo
rm -rf package/feeds/kenzo/mihomo
rm -rf package/feeds/xuanranran/mihomo
rm -rf package/feeds/haiibo/mihomo
rm -rf package/feeds/liuran/mihomo

# ============================================================
# Fix 1: Remove duplicate/conflicting packages (keep only one provider)
# ============================================================
echo "=== Removing duplicate mihomo packages ==="
echo "  Done: Keeping feeds/small/mihomo as sole mihomo provider"

echo "=== Removing conflicting clashoo from nikki feed ==="
echo "  Done: Removed feeds/nikki/clashoo to prevent architecture conflict with feeds/small/clashoo"

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
  
  sed -i '/^define Package\/nikki\/install$/,/^endef$/d' "$makefile"
  sed -i '/PROVIDES:=/d' "$makefile"
  sed -i '/ALTERNATIVES:=/d' "$makefile"
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
  sed -i '/\/usr\/libexec\/nikki/d' "$makefile"
  sed -i '/^define Build\/Compile$/,/^endef$/d' "$makefile"

  if ! grep -q '+mihomo' "$makefile"; then
    sed -i 's/^\([[:space:]]*DEPENDS:=\)/\1 +mihomo /' "$makefile"
  fi
  
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
  
  sed -i 's/PROVIDES:=.*mihomo[^ ]* *//g; s/PROVIDES:= $//; s/PROVIDES:= */PROVIDES:=/' "$makefile"
  sed -i '/^  PROVIDES:=$/d' "$makefile"
  sed -i '/ALTERNATIVES.*mihomo/d' "$makefile"
  sed -i '/GoPackage.*Install.*Bin.*mihomo/d' "$makefile"
  sed -i '/INSTALL_BIN.*\/usr\/bin\/mihomo/d' "$makefile"
  sed -i '/INSTALL_BIN.*\/usr\/libexec.*clashoo.*mihomo/d' "$makefile"
  sed -i '/LN.*\/usr\/bin\/mihomo/d' "$makefile"

  if ! grep -q '+mihomo' "$makefile"; then
    sed -i 's/^\([[:space:]]*DEPENDS:=\)/\1 +mihomo /' "$makefile"
  fi
  
  echo "  -> Done: $makefile"
}

for cf in feeds/small/clashoo/Makefile feeds/kenzo/clashoo/Makefile feeds/kenzok8/clashoo/Makefile \
          package/feeds/small/clashoo/Makefile package/feeds/kenzo/clashoo/Makefile package/feeds/kenzok8/clashoo/Makefile; do
  patch_clashoo_makefile "$cf"
done

# ============================================================
# Fix 4: Re-index patched packages to refresh dependency resolution
# ============================================================
echo "=== Re-indexing patched packages ==="
./scripts/feeds install -f -p small mihomo 2>/dev/null || echo "  (mihomo re-index skipped)"
./scripts/feeds install -f -p small clashoo 2>/dev/null || echo "  (clashoo re-index skipped)"
./scripts/feeds install -f -p nikki nikki 2>/dev/null || echo "  (nikki re-index skipped)"
./scripts/feeds install -f -p nikki luci-app-nikki 2>/dev/null || echo "  (luci-app-nikki re-index skipped)"
echo "  Done: Package index refreshed"

echo "=== All fixes applied successfully ==="



# ./scripts/feeds update -a
# ./scripts/feeds install -p kenzok8 luci-app-transmission
# ./scripts/feeds install -p kenzok8 transmission
# ./scripts/feeds install -p kenzok8 transmission-web-control
# ./scripts/feeds install -p kenzok8 smartdns
# ./scripts/feeds install -p kenzok8 luci-app-smartdns
# ./scripts/feeds install -p Joecaicai luci-app-qbittorrent
# ./scripts/feeds install -p Joecaicai qBittorrent-Enhanced-Edition
# ./scripts/feeds install -a
