include config.mk
include $(DEPENDENCIES)/config.mk

VERSION = 0.0.0
ARCHIVE ?= pkman-$(SYSTEM_NAME)-$(ARCHITECTURE).$(VERSION).zip
SYMLINK = 0

GENERATED += package.json
GENERATED += pkman$(EXECUTABLE_POSTFIX)
GENERATED += pkman-gui$(EXECUTABLE_POSTFIX)

CONTENTS += README.md
CONTENTS += LICENSE
CONTENTS += package.json
CONTENTS += packagemanager
CONTENTS += packagemanager-cli
CONTENTS += packagemanager-gui
CONTENTS += $(GENERATED)
CONTENTS += $(DEPENDENCIES)/*

all: $(ARCHIVE)

$(ARCHIVE): package
	cd package && zip --compression-method deflate -9 -r ../$@ *

export VERSION
export SYSTEM_NAME
export ARCHITECTURE
export EXECUTABLE_POSTFIX
package.json:
	./gen-package.json.sh

package: $(CONTENTS)
	rm -rf $@
	mkdir $@
ifeq ($(SYMLINK),0)
	cp -r $^ $@/
else
	for file in $^ ; do \
	    ln -s "$$(readlink -nf "$$file")" $@/ ; \
	done
endif

%.exe: %.exe.lua
	lua5.1 build-tools/wxluafreeze.lua $(DEPENDENCIES)/wxLuaFreeze$(EXECUTABLE_POSTFIX) $< $@

clean:
	rm -rf $(GENERATED) package $(ARCHIVE)

.PHONY: all clean
