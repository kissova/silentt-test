export THEOS = $(HOME)/theos
ARCHS = arm64
SUBSTRATE = 0
SDK_VERSION := $(shell xcrun --sdk iphoneos --show-sdk-version 2>/dev/null)
ifeq ($(SDK_VERSION),)
TARGET := iphone:clang:latest:16.5
else
TARGET := iphone:clang:$(SDK_VERSION):16.5
endif
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_FORMAT = deb
THEOS_PLATFORM_DPKG_DEB = dpkg-deb
_THEOS_PACKAGE_FORMAT_LOADED = 1

export LC_ALL = C
_THEOS_INTERNAL_CFLAGS += -Qunused-arguments

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = silenticum

OBFUSCATOR_PATH = /home/chi/Hikari-LLVM19/build/bin
ifneq ($(wildcard $(OBFUSCATOR_PATH)/clang),)
TARGET_CC = $(OBFUSCATOR_PATH)/clang
TARGET_CXX = $(OBFUSCATOR_PATH)/clang++
TARGET_LD = $(OBFUSCATOR_PATH)/clang++

_THEOS_TARGET_CFLAGS += -mllvm --enable-fco
_THEOS_TARGET_CFLAGS += -mllvm --enable-vfe
_THEOS_TARGET_CFLAGS += -mllvm --enable-adb
_THEOS_TARGET_CFLAGS += -mllvm --enable-splitobf
_THEOS_TARGET_CFLAGS += -mllvm -enable-strcry
endif

_THEOS_TARGET_CFLAGS += -Wno-nontrivial-memcall -Wno-error

silenticum_FRAMEWORKS = UIKit Foundation Metal MetalKit

silenticum_CFLAGS = -Wno-error=unknown-warning-option -fobjc-arc -Wno-deprecated-declarations -Wno-int-to-pointer-cast -Wno-array-bounds -Wno-return-stack-address -Wno-unused-private-field -Wno-c++17-extensions -Wno-nontrivial-memcall -Wno-modules-import-nested-redundant -Wno-unused-variable

silenticum_LDFLAGS = -lz

silenticum_FILES = PUBG/core/MenuLoad/DrawView.mm \
                PUBG/core/MenuLoad/Menu.mm \
                PUBG/core/imgui/imgui_impl_metal.mm \
                PUBG/core/imgui/imgui.cpp \
                PUBG/core/imgui/imgui_draw.cpp \
                PUBG/core/imgui/imgui_widgets.cpp \
                PUBG/core/imgui/imgui_tables.cpp \
                gui/mywings/gui.cpp \
                gui/blur/blur.cpp \
                $(wildcard SDK/*.cpp)

_THEOS_TARGET_STRIP = /bin/true
_THEOS_TARGET_CODESIGN = /bin/true

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/package.mk
