GENERATED += $(patsubst %.svg,%16.png,$(wildcard *.svg))
GENERATED += $(patsubst %.svg,%24.png,$(wildcard *.svg))
GENERATED += $(patsubst %.svg,%32.png,$(wildcard *.svg))
GENERATED += $(patsubst %.svg,%48.png,$(wildcard *.svg))

all: $(GENERATED)

%16.png: WIDTH = 16
%16.png: %.svg
	inkscape "--file=$<" "--export-png=$@" --export-width=$(WIDTH)

%24.png: WIDTH = 24
%24.png: %.svg
	inkscape "--file=$<" "--export-png=$@" --export-width=$(WIDTH)

%32.png: WIDTH = 32
%32.png: %.svg
	inkscape "--file=$<" "--export-png=$@" --export-width=$(WIDTH)

%48.png: WIDTH = 48
%48.png: %.svg
	inkscape "--file=$<" "--export-png=$@" --export-width=$(WIDTH)

clean:
	rm $(GENERATED)

.PHONY: all clean
