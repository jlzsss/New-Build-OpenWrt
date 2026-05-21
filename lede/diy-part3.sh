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
echo "  Removed mihomo from kenzok8, kenzo, xuanranran, haiibo, liuran feeds"
echo "  Keeping feeds/small/mihomo as the sole mihomo provider"

echo "=== Step 2: Patch nikki Makefile ==="
NIKKI_MAKEFILE="feeds/nikki/nikki/Makefile"
if [ -f "$NIKKI_MAKEFILE" ]; then
  echo "  Found: $NIKKI_MAKEFILE"

  # Remove PROVIDES:=mihomo - nikki should not claim to provide mihomo
  sed -i '/PROVIDES:=mihomo/d' "$NIKKI_MAKEFILE"

  # Remove ALTERNATIVES - nikki should not create /usr/bin/mihomo
  sed -i '/ALTERNATIVES:=/d' "$NIKKI_MAKEFILE"

  # Add +mihomo to DEPENDS - nikki depends on mihomo package for the binary
  sed -i 's/^\(  DEPENDS:=.*\)/\1 +mihomo/' "$NIKKI_MAKEFILE"

  # Remove Go compilation - nikki no longer compiles mihomo itself
  sed -i '/^PKG_BUILD_DEPENDS:=golang\/host/d' "$NIKKI_MAKEFILE"
  sed -i '/^include.*golang-package\.mk/d' "$NIKKI_MAKEFILE"
  sed -i '/^GO_PKG:=/d' "$NIKKI_MAKEFILE"
  sed -i '/^GO_PKG_LDFLAGS_X:=/d' "$NIKKI_MAKEFILE"
  sed -i '/^GO_PKG_TAGS:=/d' "$NIKKI_MAKEFILE"

  # Remove Go binary install lines
  sed -i '/^\t\$(call GoPackage\/Package\/Install\/Bin,/d' "$NIKKI_MAKEFILE"
  sed -i '/^\t\$(INSTALL_BIN).*mihomo.*\/usr\/libexec\/nikki/d' "$NIKKI_MAKEFILE"
  sed -i '/^\$(eval \$(call GoBinPackage/d' "$NIKKI_MAKEFILE"

  # Add symlink /usr/libexec/nikki -> /usr/bin/mihomo
  # nikki's init script expects /usr/libexec/nikki
  sed -i '/^define Package\/nikki\/install/a\\t$(INSTALL_DIR) $(1)/usr/libexec/\n\t$(LN) /usr/bin/mihomo $(1)/usr/libexec/nikki' "$NIKKI_MAKEFILE"

  echo "  nikki Makefile patched: removed mihomo binary, added +mihomo dep"
else
  echo "  WARNING: $NIKKI_MAKEFILE not found!"
fi

echo "=== Step 3: Patch clashoo Makefile ==="
for clashoo_makefile in feeds/small/clashoo/Makefile feeds/kenzo/clashoo/Makefile feeds/kenzok8/clashoo/Makefile; do
  if [ -f "$clashoo_makefile" ]; then
    echo "  Found: $clashoo_makefile"

    # Remove mihomo from PROVIDES
    sed -i 's/PROVIDES:=mihomo clash-meta/PROVIDES:=clash-meta/' "$clashoo_makefile"
    sed -i 's/PROVIDES:=clash-meta mihomo/PROVIDES:=clash-meta/' "$clashoo_makefile"
    # Handle case where PROVIDES is only mihomo
    sed -i '/^  PROVIDES:=mihomo$/d' "$clashoo_makefile"

    # Remove ALTERNATIVES for mihomo
    sed -i '/ALTERNATIVES.*mihomo/d' "$clashoo_makefile"

    # Add +mihomo to DEPENDS
    sed -i 's/^\([[:space:]]*DEPENDS:=.*\)/\1 +mihomo/' "$clashoo_makefile"

    # Remove Go binary install
    sed -i '/^\t\$(call GoPackage\/Package\/Install\/Bin,/d' "$clashoo_makefile"
    sed -i '/^\t\$(INSTALL_BIN).*mihomo/d' "$clashoo_makefile"

    # Add symlink /usr/libexec/clashoo -> /usr/bin/mihomo if needed
    echo "  -> Patched clashoo Makefile"
  fi
done

echo "=== Step 4: Reinstall patched feeds to update package index ==="
./scripts/feeds install -p nikki nikki
./scripts/feeds install -p nikki luci-app-nikki
for clashoo_dir in feeds/small/clashoo feeds/kenzo/clashoo feeds/kenzok8/clashoo; do
  if [ -d "$clashoo_dir" ]; then
    feed_name=$(echo "$clashoo_dir" | cut -d/ -f2)
    ./scripts/feeds install -p "$feed_name" clashoo
  fi
done

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

# Find fchomo feed directory
FCHOMO_DIR=""
for d in feeds/helloworld/luci-app-fchomo feeds/small/luci-app-fchomo feeds/kenzo/luci-app-fchomo feeds/kenzok8/luci-app-fchomo; do
  if [ -d "$d" ]; then
    FCHOMO_DIR="$d"
    break
  fi
done

if [ -n "$FCHOMO_DIR" ]; then
  echo "  Found fchomo at: $FCHOMO_DIR"
  
  # Create files directory if not exists
  mkdir -p "$FCHOMO_DIR/files"
  
  # Replace postinst with a no-op script
  cat > "$FCHOMO_DIR/files/luci-app-fchomo.postinst" << 'POSTINST_EOF'
#!/bin/sh
# [patched] Original version check removed - always succeeds
exit 0
POSTINST_EOF
  chmod 755 "$FCHOMO_DIR/files/luci-app-fchomo.postinst"
  echo "  -> Replaced postinst with no-op script"
  
  # Also check if there's a preinst script
  if [ -f "$FCHOMO_DIR/files/luci-app-fchomo.preinst" ]; then
    cat > "$FCHOMO_DIR/files/luci-app-fchomo.preinst" << 'PREINST_EOF'
#!/bin/sh
# [patched] Original preinst removed - always succeeds
exit 0
PREINST_EOF
    chmod 755 "$FCHOMO_DIR/files/luci-app-fchomo.preinst"
    echo "  -> Also replaced preinst with no-op script"
  fi
else
  echo "  WARNING: luci-app-fchomo not found in any feed"
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
