###############################################################################
# Sloan Digital Sky Survey (SDSS)
# IDL support code for products: platedesign
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

# Note that either mangle1.4/src or mangle1.2 must be built before idlmangle!
SUBDIRS = cs2 fiber skycalc fanuc

all :
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; $(MAKE) $(MFLAGS) all ); \
	done

clean :
	- /bin/rm -f *~ core
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; $(MAKE) $(MFLAGS) clean ); \
	done
