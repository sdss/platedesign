# makefile for cs2
# compileler definitions
# COMP_DUALS to compute prices
# PRINT_ANS to print flow (and prices if COMP_DUAL defined)
# DOUBLE_EX makes excesses into doubles
#           it is better to use long long ints instead of double
#           if your compiler supports these

# change these to suit your system
#CCOMP = gcc
CCOMP = cc
#CFLAGS = -g -Wall
#CFLAGS = -O4 -i486 -DNDEBUG
#CFLAGS = -O4
CFLAGS = -O -m32

INSTALL_DIR   = $(TILING_INSTALL_DIR)$(CTILE_INSTALL_DIR)
INSTALL_FILES = *.c *.h makefile COPYRIGHT README sample.input version cs2

all: cs2

install :
	@if [ "$(INSTALL_DIR)" = "" ]; then \
	echo You have not specified a destination directory >&2; \
	exit 1; \
	fi     
	@ rm -rf $(INSTALL_DIR)/cs2
	@ mkdir $(INSTALL_DIR)/cs2
	@if [ "$(INSTALL_FILES)" != "" ]; then \
		cp $(INSTALL_FILES) $(INSTALL_DIR)/cs2; \
	fi

cs2: cs2.c parser_cs2.c types_cs2.h timer.c
#	$(CCOMP) $(CFLAGS) -o cs2 cs2.c -lm
	$(CCOMP) $(CFLAGS) -DPRINT_ANS -o cs2 cs2.c -lm

clean:
	rm -f cs2
