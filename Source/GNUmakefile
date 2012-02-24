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

-include ../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble
