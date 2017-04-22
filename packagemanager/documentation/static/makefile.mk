HERE = packagemanager/documentation/static

include $(HERE)/style/tex-gyre-schola/makefile.mk

$(HERE)/style.css: $(HERE)/style/main.scss
	sass --style expanded $^ $@
