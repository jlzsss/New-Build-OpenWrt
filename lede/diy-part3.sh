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
# Fix Go packages that force CGO_ENABLED=0 (v2dat and feed clones of it).
# The golang feed always passes "-linkmode external" in GO_PKG_DEFAULT_LDFLAGS,
# and Go rejects that combination with:
#   "-linkmode requires external (cgo) linking, but cgo is not enabled"
# Deleting the per-package override makes them inherit CGO_ENABLED=1 from the
# feed, the same way every other Go package here is built.
#
# DO NOT patch golang-package.mk: GO_PKG_TARGET_VARS is a multi-line list that
# is expanded into a shell command line, so rewriting the CGO_ENABLED line there
# (especially with ':=') injects make syntax into bash and breaks *every* Go
# package with "CGO_ENABLED: command not found".
# ============================================================
echo "=== Removing CGO_ENABLED=0 overrides from feed Go packages ==="
for cgoff in $(grep -rl 'filter-out CGO_ENABLED=%' feeds --include=Makefile 2>/dev/null); do
  if grep -q 'GO_PKG_DEFAULT_LDFLAGS' "$cgoff"; then
    echo "  -> skipped, already uses the internal linker: $cgoff"
    continue
  fi
  sed -i '/filter-out CGO_ENABLED=%/d' "$cgoff"
  echo "  -> dropped CGO_ENABLED=0 override: $cgoff"
done
echo "=== Go cgo fix done ==="

# ============================================================
# Fix luci-app-netspeedtest: python3-pkg-resources 已从上游移除
# sirpdboy/netspeedtest 的 LUCI_DEPENDS 里写了 +python3-pkg-resources，
# 但该包在 coolsnowwolf/packages 和 openwrt/packages 当前分支里都不存在
# （setuptools>=82 移除了 pkg_resources，feed 里只有 python3-setuptools）。
# 所以必须精确替换为真实存在的 +python3-setuptools，且只改 netspeedtest，
# 禁止全局 s/python3-pkg-resources/python3/g（会误伤其它包且产生重复依赖）。
# ============================================================
echo "=== Fixing netspeedtest python3-pkg-resources dependency ==="
for ns_makefile in $(find package feeds -path "*netspeedtest*/Makefile" 2>/dev/null); do
  if grep -q "python3-pkg-resources" "$ns_makefile" 2>/dev/null; then
    echo "  Found: $ns_makefile"
    sed -i 's/+python3-pkg-resources/+python3-setuptools/g' "$ns_makefile"
    echo "  -> Replaced +python3-pkg-resources with +python3-setuptools"
  fi
done
echo "=== netspeedtest fix done ==="

# ============================================================
# Fix luci-app-ssr-plus: 保留 bind-dig，禁止替换成 bind
# kenzok8/small、kenzok8/jell 的 luci-app-ssr-plus 依赖 +bind-dig，
# 它是 feeds/packages/net/bind 真实提供的子包
# （bind-libs/bind-server/bind-client/bind-tools/bind-dig/...）。
# 而裸 `bind` 包根本不存在，之前全局 s/bind-dig/bind/g 不仅修不好，
# 还会把 bind 自身 Makefile 里的 define Package/bind-dig 破坏掉，
# 把提供者都删掉。这里只做校验，不做任何替换。
# 缺失的 ipk 靠下面 .config 选中 CONFIG_PACKAGE_bind-dig 来编译。
# ============================================================
echo "=== Checking ssr-plus bind-dig dependency (keep as-is) ==="
grep -rl "bind-dig" feeds package --include=Makefile 2>/dev/null | head -20 | while read -r f; do echo "  keep bind-dig in: $f"; done
echo "=== ssr-plus check done ==="

# ============================================================
# 确保依赖在 .config 中被选中，然后 make defconfig 使其生效
# netspeedtest 需要: python3-setuptools（替代已移除的 pkg-resources）
# ssr-plus 需要: bind-dig + bind-libs（+liburcu 已有）
# 注意: 裸 `bind` 包不存在，禁止选中 CONFIG_PACKAGE_bind；
# python3-light 真实存在，禁止全局 s/+python3-light/+python3/g。
# diy-part3 运行在 ./scripts/feeds install -a 之后，改完 Makefile/.config
# 必须 make defconfig，否则 tmp/.packageinfo 还是旧的，install 必 fail。
# ============================================================
echo "=== Ensuring dependencies are selected in .config ==="
if [ -f .config ]; then
  # 清掉之前误加的无效项（裸 bind 包不存在）
  sed -i '/^CONFIG_PACKAGE_bind=y$/d' .config
  sed -i '/^CONFIG_OVERRIDE_PKGS=/d' .config
  # 删除旧行避免重复（同时匹配 "=y" 和 "is not set" 行）
  for sym in bind-dig bind-libs python3-setuptools python3 python3-light liburcu; do
    sed -i "/CONFIG_PACKAGE_${sym}[ =]/d" .config
  done
  printf 'CONFIG_PACKAGE_bind-dig=y\n' >> .config
  printf 'CONFIG_PACKAGE_bind-libs=y\n' >> .config
  printf 'CONFIG_PACKAGE_liburcu=y\n' >> .config
  printf 'CONFIG_PACKAGE_python3=y\n' >> .config
  printf 'CONFIG_PACKAGE_python3-light=y\n' >> .config
  printf 'CONFIG_PACKAGE_python3-setuptools=y\n' >> .config
  echo "  -> selected bind-dig, bind-libs, liburcu, python3, python3-light, python3-setuptools"
  # 刷新 defconfig，让新增选中项展开到依赖关系中
  make defconfig
  echo "  -> make defconfig done"
else
  echo "  WARNING: .config not found"
fi
echo "=== .config fix done ==="

# ============================================================
# Verify required packages are selected in .config
# ============================================================
echo "=== Verifying .config packages ==="
if [ -f .config ]; then
  grep -q "CONFIG_PACKAGE_python3-setuptools=y" .config && echo "  -> python3-setuptools selected" || echo "  -> WARNING: python3-setuptools not selected"
  grep -q "CONFIG_PACKAGE_bind-dig=y" .config && echo "  -> bind-dig selected" || echo "  -> WARNING: bind-dig not selected"
  grep -q "CONFIG_PACKAGE_bind-libs=y" .config && echo "  -> bind-libs selected" || echo "  -> WARNING: bind-libs not selected"
  grep -q "CONFIG_PACKAGE_python3-light=y" .config && echo "  -> python3-light selected" || echo "  -> WARNING: python3-light not selected"
else
  echo "  WARNING: .config not found"
fi
echo "=== verification done ==="
