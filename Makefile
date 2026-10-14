ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = AimeHCETrace
AimeHCETrace_FILES = Tweak.m
AimeHCETrace_CFLAGS = -fobjc-arc -Wall -Wextra -Werror
AimeHCETrace_FRAMEWORKS = Foundation
include $(THEOS_MAKE_PATH)/tweak.mk
