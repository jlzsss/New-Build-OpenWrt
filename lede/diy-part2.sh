#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# rm -rf feeds/packages2/lang/python
rm -rf feeds/packages/net/transmission
rm -rf feeds/packages/net/transmission-web-control

rm -rf feeds/small/geoview
rm -rf feeds/kenzok8/geoview
rm -rf feeds/packages/lang/golang
git clone --depth 1 https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# Fix vim-fuller build failure: remove cp of vim runtime files that may not exist
# The Makefile uses $(VIMVER) variable, not literal "vim82"
sed -i '/\$(CP) \$(PKG_INSTALL_DIR).*vim\$(VIMVER)/d' feeds/packages/utils/vim/Makefile 2>/dev/null || true

# Fix miniupnpd download failure: keep only official feeds/packages/net/miniupnpd-nftables and miniupnp
# Remove all third-party miniupnpd/miniupnp packages to avoid conflicts
rm -rf feeds/kenzok8/miniupnpd*
rm -rf feeds/kenzok8/miniupnp*
rm -rf feeds/small/miniupnpd*
rm -rf feeds/small/miniupnp*
git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/uwsgi && cd .. && rm -rf feeds/packages/net/uwsgi && mv temp-lede/net/uwsgi feeds/packages/net && rm -rf temp-lede
git clone --depth 1 --filter=blob:none --sparse https://github.com/openwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set lang/lua/lua5.4 && cd .. && rm -rf feeds/packages/lang/lua/lua5.4 && mv temp-lede/lang/lua/lua5.4 feeds/packages/lang/lua/ && rm -rf temp-lede

# Fix dockerd 29.x build failure: copy_binaries() in hack/make/binary-daemon
# tries to cp executables (containerd, docker-init, rootlesskit, etc.) that
# don't exist in the GitHub runner's PATH, causing:
#   cp: cannot stat '': No such file or directory
# Root cause: runner has /usr/local/bin/runc so the guard check passes, but
# other executables are missing → command -v returns empty → cp fails.
# Fix: patch the source to skip files not found in PATH.
DOCKERD_MK="feeds/packages/utils/dockerd/Makefile"
if [ -f "${DOCKERD_MK}" ]; then
  # Create OpenWrt package patch directory (patches applied after source extraction)
  mkdir -p feeds/packages/utils/dockerd/patches
  cat > feeds/packages/utils/dockerd/patches/001-fix-copy-binaries.patch << 'PATCH_EOF'
--- a/hack/make/binary-daemon
+++ b/hack/make/binary-daemon
@@ -16,7 +16,8 @@
 	for file in containerd containerd-shim-runc-v2 ctr runc docker-init rootlesskit dockerd-rootless.sh dockerd-rootless-setuptool.sh; do
-		cp -f "$(command -v "$file")" "$dir/"
+		_cmd="$(command -v "$file" 2>/dev/null)"
+		[ -n "${_cmd}" ] && cp -f "${_cmd}" "$dir/" || true
 	done
 	# vpnkit might not be available for the target platform, see vpnkit stage in
 	# the Dockerfile for more information.
PATCH_EOF
  # Fix docker-proxy install path: 29.x builds it to bundles/binary/ not bundles/binary-daemon/
  sed -i 's|bundles/binary-daemon/docker-proxy|bundles/binary/docker-proxy|g' "${DOCKERD_MK}" 2>/dev/null || true
fi
# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set libs/libb64 && cd .. && rm -rf feeds/packages/libs/libb64 && mv temp-lede/libs/libb64 feeds/packages/libs && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/transmission && cd .. && rm -rf feeds/packages/net/transmission && mv temp-lede/net/transmission feeds/packages/net && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/transmission-web-control && cd .. && rm -rf feeds/packages/net/transmission-web-control && mv temp-lede/net/transmission-web-control feeds/packages/net && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/coolsnowwolf/packages.git temp-lede && cd temp-lede && git sparse-checkout set lang/rust && cd .. && rm -rf feeds/packages/lang/rust && mv temp-lede/lang/rust feeds/packages/lang && rm -rf temp-lede
