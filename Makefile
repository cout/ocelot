# TODO: use rbconfig
CPPFLAGS = -I/usr/lib/ruby/1.8/i486-linux
CFLAGS = -g -ggdb -Wall
LDFLAGS = -pthread
LDLIBS = -lruby1.8 -lm -lrt -ldl -lcrypt

all: test

test.c: ocelot.rb
	ruby ocelot.rb > test.c

test: test.c
	$(CC) $(CFLAGS) test.c -o test $(CPPFLAGS) $(LDFLAGS) $(LDLIBS)

.PHONY: test

