TARGET := iphone:clang:latest:18.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FolderPickerHook
FolderPickerFix_FILES = Tweak.x
FolderPickerFix_FRAMEWORKS = UIKit UniformTypeIdentifiers
FolderPickerFix_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
