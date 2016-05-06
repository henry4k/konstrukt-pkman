VERSION = $(shell sed -n -e 's/.*"version": "\(.*\)".*/\1/p' meta.json)
FILENAME = packagemanager.$(VERSION).zip

CONTENTS += README.md
CONTENTS += LICENSE
CONTENTS += meta.json
CONTENTS += pkman
CONTENTS += $(shell find packagemanager)
CONTENTS += $(shell find packagemanager-cli)

$(FILENAME): Makefile $(CONTENTS)
	zip $@ $(CONTENTS)
