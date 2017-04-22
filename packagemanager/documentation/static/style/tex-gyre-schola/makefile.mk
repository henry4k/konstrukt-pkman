HERE = style/tex-gyre-schola

GENERATED += $(HERE)/regular.woff
GENERATED += $(HERE)/bold.woff
GENERATED += $(HERE)/italic.woff
GENERATED += $(HERE)/bolditalic.woff

%.woff: %.otf $(HERE)/valid-chars.txt
	pyftsubset $< --output-file=$@ --text-file=$(HERE)/valid-chars.txt
