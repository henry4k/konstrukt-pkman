include config.mk

NAME    = $(shell sed -n -e 's/.*"name": "\(.*\)".*/\1/p'    package.json)
VERSION = $(shell sed -n -e 's/.*"version": "\(.*\)".*/\1/p' package.json)
ARCHIVE ?= $(NAME).$(VERSION).zip
SYMLINK = 0

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
	rm -rf build $(GENERATED)

.PHONY: all clean
