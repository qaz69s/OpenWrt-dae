# SPDX-License-Identifier: MIT
#
# Tiger — TUIC Protocol Server (Itsusinn/tuic fork)
# 从 GitHub Releases 按目标架构下载预编译静态二进制

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/package.mk

PKG_NAME    := tiger
PKG_VERSION := 1.8.1
PKG_RELEASE := 1

PKG_LICENSE    := GPL-3.0-only
PKG_MAINTAINER := Pi <pi@example.com>

# ── 架构映射：OpenWrt ARCH → release binary suffix ──────────────────
ifeq ($(ARCH),x86_64)
  TIGER_TARGET := x86_64-linux-musl
else ifeq ($(ARCH),aarch64)
  TIGER_TARGET := aarch64-linux-musl
else ifeq ($(ARCH),arm)
  ifneq ($(CONFIG_arm_v7),)
    TIGER_TARGET := armv7-linux-muslhf
  else ifneq ($(CONFIG_HAS_FPU),)
    TIGER_TARGET := armv7-linux-muslhf
  else
    TIGER_TARGET := armv7-linux-musl
  endif
else ifeq ($(ARCH),i386)
  TIGER_TARGET := i686-linux-musl
else ifeq ($(ARCH),mipsel)
  # tuic 不支持 mipsel，编译期报错
  TIGER_TARGET :=
else ifeq ($(ARCH),mips)
  TIGER_TARGET :=
else
  TIGER_TARGET :=
endif

TIGER_BINARY  := tuic-server-$(TIGER_TARGET)
TIGER_DL_URL  := https://github.com/Itsusinn/tuic/releases/download/v$(PKG_VERSION)/$(TIGER_BINARY)

define Package/tiger
  SECTION   := net
  CATEGORY  := Network
  TITLE     := Tiger (TUIC Server)
  URL       := https://github.com/Itsusinn/tuic
  DEPENDS   :=
endef

define Package/tiger/description
  TUIC 协议服务端（基于 Itsusinn/tuic v1.8.1 分支），
  支持自签证书、ACME 自动证书、ACL 规则、RESTful API。
endef

define Package/tiger/conffiles
/etc/config/tiger
/etc/tuic/config.toml
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	# 检查架构是否支持
	[ -n "$(TIGER_TARGET)" ] || { \
		echo "Tiger: 不支持的架构 $(ARCH)，支持：x86_64 aarch64 armv7 i686" >&2; \
		exit 1; \
	}
	# 下载二进制（已缓存则跳过）
	if [ ! -f "$(DL_DIR)/$(TIGER_BINARY)" ]; then \
		echo "Tiger: 下载 $(TIGER_DL_URL)"; \
		curl -fsSL --retry 3 \
			-o "$(DL_DIR)/$(TIGER_BINARY).tmp" \
			"$(TIGER_DL_URL)" \
		&& mv "$(DL_DIR)/$(TIGER_BINARY).tmp" "$(DL_DIR)/$(TIGER_BINARY)"; \
	fi
	# 复制二进制到 Build 目录
	cp "$(DL_DIR)/$(TIGER_BINARY)" "$(PKG_BUILD_DIR)/tuic-server"
	chmod +x "$(PKG_BUILD_DIR)/tuic-server"
endef

define Build/Compile
endef

define Package/tiger/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tuic-server $(1)/usr/bin/tuic-server

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/tiger.init $(1)/etc/init.d/tiger

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/tiger.config $(1)/etc/config/tiger

	$(INSTALL_DIR) $(1)/etc/tuic
	$(INSTALL_CONF) $(CURDIR)/files/tiger-ctrl.sh $(1)/etc/tuic/tiger-ctrl.sh

	$(INSTALL_DIR) $(1)/usr/libexec
	$(INSTALL_BIN) $(CURDIR)/files/tiger-ctrl.sh $(1)/usr/libexec/tiger-ctrl.sh
endef

define Package/tiger/postinst
#!/bin/sh
[ -z "${IPKG_INSTROOT}" ] && chmod +x /usr/libexec/rpcd/luci.tiger /usr/libexec/tiger-ctrl.sh
exit 0
endef

define Package/tiger/prerm
#!/bin/sh
[ -z "$${IPKG_INSTROOT}" ] && {
	[ -x /etc/init.d/tiger ] && {
		/etc/init.d/tiger stop    2>/dev/null || true
		/etc/init.d/tiger disable 2>/dev/null || true
	}
}
exit 0
endef

$(eval $(call BuildPackage,tiger))
