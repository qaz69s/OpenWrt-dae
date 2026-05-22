# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2024 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

LUCI_TITLE:=LuCI app for dae
LUCI_DEPENDS:=+dae +dae-geoip +dae-geosite

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-dae/install
 $(call Package/luci-app-dae/install,$(1))
 $(INSTALL_DIR) $(1)/usr/libexec/rpcd
  $(INSTALL_BIN) $(CURDIR)/root/usr/libexec/rpcd/luci.dae $(1)/usr/libexec/rpcd/luci.dae
endef
# call BuildPackage - OpenWrt buildroot signature

