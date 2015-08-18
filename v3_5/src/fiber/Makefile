###############################################################################
# Sloan Digital Sky Survey (SDSS)
# IDL support code for products: idlmapper, idlspec2d
#
# S. Burles & D. Schlegel
###############################################################################

SHELL = /bin/sh
#
.c.o : fiber.h
	$(CC) -c $(CCCHK) $(CFLAGS) $(X_CFLAGS) $*.c

INC = ../../include
CFLAGS  = $(SDSS_CFLAGS) -DCHECK_LEAKS -I$(INC)

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
