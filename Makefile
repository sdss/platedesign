###############################################################################
# Sloan Digital Sky Survey (SDSS)
# IDL support code for products: platedesign
# Mike Blanton & Paul Harding
###############################################################################

SHELL = /bin/sh
#
.c.o :
	$(CC) -c $(CCCHK) $(CFLAGS) $*.c
#
CFLAGS  = 

SUBDIRS = src 

all :
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; $(MAKE) $(MFLAGS) all ); \
	done

#
# Install things in their proper places in $(PLATEDESIGN_DIR)
#
install :
	@echo "You should be sure to have updated before doing this."
	@echo ""
	@if [ "$(PLATEDESIGN_DIR)" = "" ]; then \
		echo You have not specified a destination directory >&2; \
		exit 1; \
	fi 
	@if [ -e $(PLATEDESIGN_DIR) ]; then \
		echo The destination directory already exists >&2; \
		exit 1; \
	fi 
	@echo ""
	@echo "You will be installing in \$$PLATEDESIGN_DIR=$$PLATEDESIGN_DIR"
	@echo "I'll give you 5 seconds to think about it"
	@sleep 5
	@echo ""
	@ rm -rf $(PLATEDESIGN_DIR)
	@ mkdir $(PLATEDESIGN_DIR)
	@ cp -rpf * $(PLATEDESIGN_DIR)

clean :
	- /bin/rm -f *~ core
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; $(MAKE) $(MFLAGS) clean ); \
	done
