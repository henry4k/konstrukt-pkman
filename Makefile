include config.mk

#VERSION = $(shell sed -n -e 's/.*"version": "\(.*\)".*/\1/p' meta.json)
PACKAGE_BASENAME = package
SYMLINK = 0

GENERATED += pkman$(EXECUTABLE_POSTFIX)
GENERATED += pkman-gui$(EXECUTABLE_POSTFIX)

CONTENTS += README.md
CONTENTS += LICENSE
CONTENTS += meta.json
CONTENTS += packagemanager
CONTENTS += packagemanager-cli
CONTENTS += packagemanager-gui
CONTENTS += $(GENERATED)
CONTENTS += $(DEPENDENCIES)/*

$(PACKAGE_BASENAME).zip: $(PACKAGE_BASENAME)
	zip -r $@ $<

$(PACKAGE_BASENAME): $(CONTENTS)
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
	rm -rf $(PACKAGE_BASENAME) $(GENERATED)

.PHONY: clean
