CFLAGS_MACFUSE = -D__FreeBSD__=10 -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=26 -I/usr/local/include/fuse
CFLAGS_EXTRA = -Wall -g -Wno-deprecated
ARCHS = -arch i386
LIBS = -lfuse

# -Wall -g -Wno-deprecated -DFUSE_USE_VERSION=26  `pkg-config fuse --cflags --libs`  -Wno-deprecated

packfs: packfs.cc
	./g++ $(CFLAGS_MACFUSE) $(CFLAGS_EXTRA) $(ARCHS) $(LIBS) -o $@ $<

clean:
	rm -f packfs *.o
