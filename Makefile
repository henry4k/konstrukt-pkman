include config.mk

#VERSION = $(shell sed -n -e 's/.*"version": "\(.*\)".*/\1/p' meta.json)
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

package.zip: package
	zip -r $@ $<

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

.PHONY: clean
