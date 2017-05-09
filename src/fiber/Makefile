###############################################################################
# Sloan Digital Sky Survey (SDSS)
# IDL support code for products: idlmapper, idlspec2d
#
# S. Burles & D. Schlegel
###############################################################################

SHELL = /bin/sh
#
.c.o :
	$(CC) -c $(CCCHK) $(CFLAGS) $(X_CFLAGS) $*.c
#.f.o :
#	$(F77) -c $(CCCHK) $(CFLAGS) $(X_CFLAGS) $*.f
#
INC = ../../include
CFLAGS  = -O2 -fPIC -fno-common -D_REENTRANT -DCHECK_LEAKS -I$(INC)
X_LD_FLAGS = -shared

UNAME = $(shell uname)
ifeq ($(UNAME), Darwin)
	CFLAGS = -arch x86_64 -O2 -fPIC -dynamic -fno-common -D_REENTRANT -DCHECK_LEAKS -I$(INC)
	X_LD_FLAGS = -arch x86_64 -bundle -flat_namespace -undefined suppress -macosx_version_min 10.11
endif

SO_EXT=so

BIN = $(PLATEDESIGN_DIR)/bin
LIB = $(PLATEDESIGN_DIR)/lib

OBJECTS = \
	idl_read_plugprob.o \
	idl_write_plugprob.o \
	plugprob.o 

all : $(LIB)/libfiber.$(SO_EXT) 

$(LIB)/libfiber.$(SO_EXT): $(OBJECTS) 
	$(LD) $(X_LD_FLAGS) -o $(LIB)/libfiber.$(SO_EXT) $(OBJECTS) -lm

#
# Install things in their proper places in $(PLATEDESIGN_DIR)
#
install : 
	-@ cp *.c $(PLATEDESIGN_DIR)/src
	-@ cp *.h $(PLATEDESIGN_DIR)/src
	-@ cp Makefile $(PLATEDESIGN_DIR)/src

clean :
	- /bin/rm -f *~ core *.o so_locations
