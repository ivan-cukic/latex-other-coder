#
# Makefile
# Ivan Čukić, 2017-06-17 11:48
#

all: dist/othercoder_impl.lua

dist/othercoder_impl.lua: src/othercoder_impl.moon
	moonc -o dist/othercoder_impl.lua src/othercoder_impl.moon

