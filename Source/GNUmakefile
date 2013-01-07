include $(GNUSTEP_MAKEFILES)/common.make

#
# Main framework
#
FRAMEWORK_NAME = TrayIconKit

# Include configuration

#-include ../config.make

#
# Public headers (will be installed)
#
TrayIconKit_HEADER_FILES_DIR = ../Headers
TrayIconKit_HEADER_FILES = \
		  TrayIconKit.h \
		  TrayIconController.h
#
# Class files
#
TrayIconKit_OBJC_FILES = \
        TrayIconController.m

TrayIconKit_OBJCFLAGS += $(WARN_FLAGS) 

ADDITIONAL_GUI_LIBS = -lX11
TrayIconKit_LIBRARIES_DEPEND_UPON += $(ADDITIONAL_GUI_LIBS)

-include ../GNUmakefile.preamble

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
include $(GNUSTEP_MAKEFILES)/library.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include GNUmakefile.postamble
