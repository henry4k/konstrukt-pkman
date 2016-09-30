include config.mk

VERSION = $(shell sed -n -e 's/.*"version": "\(.*\)".*/\1/p' meta.json)
PACKAGE_BASENAME = packagemanager.$(VERSION)

CONTENTS += README.md
CONTENTS += LICENSE
CONTENTS += meta.json
CONTENTS += $(shell find packagemanager)
CONTENTS += $(shell find packagemanager-cli)
CONTENTS += $(shell find packagemanager-gui)
CONTENTS += pkman$(EXECUTABLE_POSTFIX)
CONTENTS += pkman-gui$(EXECUTABLE_POSTFIX)

$(PACKAGE_BASENAME).zip: $(PACKAGE_BASENAME)
	zip -r $@ $<

$(PACKAGE_BASENAME): $(CONTENTS)
	mkdir -p $@
	cp -r README.md \
	      LICENSE \
	      meta.json \
	      packagemanager \
	      packagemanager-cli \
	      packagemanager-gui \
	      pkman$(EXECUTABLE_POSTFIX) \
	      pkman-gui$(EXECUTABLE_POSTFIX) \
	      $(DEPENDENCIES)/* \
	      $@/

%.exe: %.exe.lua
	lua5.1 build-tools/wxluafreeze.lua $(DEPENDENCIES)/wxLuaFreeze$(EXECUTABLE_POSTFIX) $< $@

clean:
	rm -rf $(PACKAGE_BASENAME) $(PACKAGE_BASENAME).zip *.exe

.PHONY: clean
