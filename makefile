TARGET := iphone:clang:latest:15.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FolderPickerHook

FolderPickerHook_FILES = Tweak.x
FolderPickerHook_CFLAGS = -fobjc-arc
FolderPickerHook_FRAMEWORKS = UIKit UniformTypeIdentifiers

include $(THEOS_MAKE_PATH)/tweak.mk
