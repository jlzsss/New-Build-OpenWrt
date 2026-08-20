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
git clone --depth 1 --filter=blob:none --sparse https://github.com/openwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set utils/dockerd utils/containerd utils/runc utils/tini && cd .. && rm -rf feeds/packages/utils/dockerd feeds/packages/utils/containerd feeds/packages/utils/runc feeds/packages/utils/tini && mv temp-lede/utils/dockerd temp-lede/utils/containerd temp-lede/utils/runc temp-lede/utils/tini feeds/packages/utils/ && rm -rf temp-lede

# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set libs/libb64 && cd .. && rm -rf feeds/packages/libs/libb64 && mv temp-lede/libs/libb64 feeds/packages/libs && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/transmission && cd .. && rm -rf feeds/packages/net/transmission && mv temp-lede/net/transmission feeds/packages/net && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/immortalwrt/packages.git temp-lede && cd temp-lede && git sparse-checkout set net/transmission-web-control && cd .. && rm -rf feeds/packages/net/transmission-web-control && mv temp-lede/net/transmission-web-control feeds/packages/net && rm -rf temp-lede
# git clone --depth 1 --filter=blob:none --sparse https://github.com/coolsnowwolf/packages.git temp-lede && cd temp-lede && git sparse-checkout set lang/rust && cd .. && rm -rf feeds/packages/lang/rust && mv temp-lede/lang/rust feeds/packages/lang && rm -rf temp-lede
