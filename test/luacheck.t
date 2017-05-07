#!/bin/sh
luacheck --config .luacheckrc --formatter TAP packagemanager \
                                              packagemanager-cli \
                                              packagemanager-gui
