CFLAGS_GENERIC = -Wall -g -Wno-deprecated 
CFLAGS_OSX = -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=26 -D__APPLE__=1 -I/usr/local/include/fuse -I/usr/local/include/osxfuse -losxfuse
CFLAGS_LINUX = -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=26 -lfuse

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
CFLAGS := $(CFLAGS_GENERIC) $(CFLAGS_LINUX)
endif

ifeq ($(UNAME), Darwin)
CFLAGS := $(CFLAGS_GENERIC) $(CFLAGS_OSX)
endif

packfs: packfs.cc Makefile
	g++ $(CFLAGS) -o $@ $<

clean:
	rm -f packfs *.o
