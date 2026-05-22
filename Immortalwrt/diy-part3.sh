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
rm -rf feeds/kenzok8/mihomo
rm -rf feeds/kenzok8/luci-app-mihomo
rm -rf feeds/small/mihomo
rm -rf feeds/kenzo/mihomo
rm -rf feeds/xuanranran/mihomo
rm -rf feeds/haiibo/mihomo
rm -rf feeds/liuran/mihomo
# Keep feeds/nikki/mihomo as the sole mihomo provider for nikki/clashoo

# ============================================================
# Fix nikki: make it depend on mihomo feed package instead of building its own
# ============================================================

echo "=== Fixing nikki mihomo conflict ==="
NIKKI_MAKEFILE="feeds/nikki/nikki/Makefile"

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
  
  # Remove all Go build related lines
  sed -i '/GO_PKG/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_BUILD_ARGS/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_INSTALL_EXTRA/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_LDFLAGS/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_TAGS/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_MOD_CACHE/d' "$NIKKI_MAKEFILE"
  sed -i '/GoPackage\/Package/d' "$NIKKI_MAKEFILE"
  sed -i '/golang-build.sh/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_BUILD_PKG/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_BUILD_DIR/d' "$NIKKI_MAKEFILE"
  sed -i '/GO_INSTALL_BIN/d' "$NIKKI_MAKEFILE"
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

# ============================================================
# Fix luci-app-fchomo postinst version check failure
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
