include $(GNUSTEP_MAKEFILES)/common.make
-include ../GNUmakefile.preamble

DOCUMENT_NAME = TrayIconKit

TrayIconKit_DOC_INSTALL_DIR = Developer/TrayIconKit/ProgrammingManual

DOCUMENT_TEXT_NAME = INSTALL README ANNOUNCE

INSTALL_DOC_INSTALL_DIR = Developer/TrayIconKit/ReleaseNotes/$(VERSION)

ANNOUNCE_DOC_INSTALL_DIR = Developer/TrayIconKit/ReleaseNotes/$(VERSION)

README_DOC_INSTALL_DIR = Developer/TrayIconKit/ReleaseNotes/$(VERSION)

REF_DOC_INSTALL_DIR = $(GNUSTEP_DOC)/Developer

TrayIconKit_AGSDOC_FLAGS = \
	-MakeFrames YES \
	-DocumentationDirectory Reference \
	-HeaderDirectory ../Headers/ \
	-Declared TrayIconKit \
	-ConstantsTemplate TypesAndConstants \
	-FunctionsTemplate Functions \
	-MacrosTemplate Functions \
	-TypedefsTemplate TypesAndConstants \
	-VariablesTemplate TypesAndConstants
TrayIconKit_AGSDOC_FILES = \
	TrayIconKit.gsdoc \
	../Headers/TrayIconController.h

include $(GNUSTEP_MAKEFILES)/documentation.make
-include GNUmakefile.postamble
