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
# Fix nikki: completely overwrite Makefile to prevent /usr/bin/mihomo conflict
# The upstream nikki uses GoBinPackage which auto-installs the mihomo binary,
# but the separate mihomo package already provides it. We rewrite the Makefile
# to make nikki a pure config/script package that depends on mihomo.
# ============================================================

echo "=== Fixing nikki mihomo conflict ==="
NIKKI_MK="feeds/nikki/nikki/Makefile"
NIKKI_MK2="package/feeds/nikki/nikki/Makefile"

write_nikki_makefile() {
  local target="$1"
  local target_dir
  target_dir="$(dirname "$target")"
  [ -d "$target_dir" ] || return 1

  cat > "$target" << 'NIKKI_EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=nikki
PKG_VERSION:=2026.04.08
PKG_RELEASE:=1

PKG_LICENSE:=GPL3.0+
PKG_MAINTAINER:=Joseph Mory <morytyann@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/nikki
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Transparent Proxy with Mihomo on OpenWrt.
  URL:=https://github.com/nikkinikki-org
  DEPENDS:=+ca-bundle +curl +yq firewall4 +ip-full +kmod-inet-diag +kmod-nft-socket +kmod-nft-tproxy +kmod-tun +kmod-dummy +mihomo
endef

define Package/nikki/conffiles
/etc/config/nikki
/etc/nikki/mixin.yaml
endef

define Package/nikki/install
	$(INSTALL_DIR) $(1)/etc/nikki
	$(INSTALL_DIR) $(1)/etc/nikki/ucode
	$(INSTALL_DIR) $(1)/etc/nikki/scripts
	$(INSTALL_DIR) $(1)/etc/nikki/nftables
	$(INSTALL_DIR) $(1)/etc/nikki/profiles
	$(INSTALL_DIR) $(1)/etc/nikki/subscriptions
	$(INSTALL_DIR) $(1)/etc/nikki/run
	$(INSTALL_DIR) $(1)/etc/nikki/run/providers
	$(INSTALL_DIR) $(1)/etc/nikki/run/providers/rule
	$(INSTALL_DIR) $(1)/etc/nikki/run/providers/proxy

	$(INSTALL_DATA) $(CURDIR)/files/mixin.yaml $(1)/etc/nikki/mixin.yaml

	$(INSTALL_BIN) $(CURDIR)/files/ucode/include.uc $(1)/etc/nikki/ucode/include.uc
	$(INSTALL_BIN) $(CURDIR)/files/ucode/mixin.uc $(1)/etc/nikki/ucode/mixin.uc
	$(INSTALL_BIN) $(CURDIR)/files/ucode/hijack.ut $(1)/etc/nikki/ucode/hijack.ut

	$(INSTALL_BIN) $(CURDIR)/files/scripts/include.sh $(1)/etc/nikki/scripts/include.sh
	$(INSTALL_BIN) $(CURDIR)/files/scripts/firewall_include.sh $(1)/etc/nikki/scripts/firewall_include.sh
	$(INSTALL_BIN) $(CURDIR)/files/scripts/debug.sh $(1)/etc/nikki/scripts/debug.sh

	$(INSTALL_BIN) $(CURDIR)/files/nftables/geoip_cn.nft $(1)/etc/nikki/nftables/geoip_cn.nft
	$(INSTALL_BIN) $(CURDIR)/files/nftables/geoip6_cn.nft $(1)/etc/nikki/nftables/geoip6_cn.nft

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/nikki.conf $(1)/etc/config/nikki

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/nikki.init $(1)/etc/init.d/nikki

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/firewall.sh $(1)/etc/uci-defaults/99_firewall_nikki
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/init.sh $(1)/etc/uci-defaults/99_init_nikki
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/migrate.sh $(1)/etc/uci-defaults/99_migrate_nikki

	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) $(CURDIR)/files/nikki.upgrade $(1)/lib/upgrade/keep.d/nikki
endef

define Package/nikki/postrm
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ]; then
	uci -q batch <<-EOF > /dev/null
		del firewall.nikki
		commit firewall
	EOF
fi
endef

$(eval $(call BuildPackage,nikki))
NIKKI_EOF

  echo "  -> Written: $target"
}

# Write to feeds source directory
if write_nikki_makefile "$NIKKI_MK"; then
  echo "  -> Overwrote feeds nikki Makefile (no GoBinPackage, no Go build)"
else
  echo "  WARNING: Cannot write to $NIKKI_MK"
fi

# Also write to package/feeds if it exists (build system may use either)
if [ -d "$(dirname "$NIKKI_MK2")" ]; then
  write_nikki_makefile "$NIKKI_MK2"
  echo "  -> Also overwrote package/feeds nikki Makefile"
fi

# Force clean rebuild
rm -rf build_dir/target-*/nikki-* 2>/dev/null
rm -rf build_dir/target-*/*.nikki-* 2>/dev/null

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

