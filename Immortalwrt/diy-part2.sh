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
git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/uwsgi && cd .. && rm -rf feeds/packages/net/uwsgi && mv temp-lede/net/uwsgi feeds/packages/net && rm -rf temp-lede
git clone --depth 1 --filter=blob:none --sparse https://github.com/coolsnowwolf/packages.git temp-lede && cd temp-lede && git sparse-checkout set lang/rust && cd .. && rm -rf feeds/packages/lang/rust && mv temp-lede/lang/rust feeds/packages/lang && rm -rf temp-lede
git clone --depth 1 --filter=blob:none --sparse https://github.com/openwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set lang/lua/lua5.4 && cd .. && rm -rf feeds/packages/lang/lua/lua5.4 && mv temp-lede/lang/lua/lua5.4 feeds/packages/lang/lua/ && rm -rf temp-lede

# Fix dockerd build failure: copy_binaries() in hack/make/binary-daemon
# tries to cp executables (containerd, docker-init, rootlesskit, etc.) that
# don't exist in the GitHub runner's PATH, causing:
#   cp: cannot stat '': No such file or directory
# Solution: Add PostConfigure hook to patch binary-daemon script after unpacking
DOCKERD_PKG="feeds/packages/utils/dockerd"
if [ -f "${DOCKERD_PKG}/Makefile" ]; then
  # Create a temporary file with the PostConfigure definition
  cat > /tmp/dockerd_postconfigure.txt << 'EOF'

define Build/PostConfigure
	sed -i "/copy_binaries/s/^/#/" $(PKG_BUILD_DIR)/hack/make/binary-daemon
endef

EOF
  
  # Insert the PostConfigure definition before Build/Compile
  sed -i '/^define Build\/Compile/{
    r /tmp/dockerd_postconfigure.txt
  }' "${DOCKERD_PKG}/Makefile"
  
  rm -f /tmp/dockerd_postconfigure.txt

  # Also fix docker-proxy install path if needed
  sed -i 's|bundles/binary-daemon/docker-proxy|bundles/binary/docker-proxy|g' "${DOCKERD_PKG}/Makefile" 2>/dev/null || true
fi
