all: $(PLATEDESIGN_DIR)/bin/skycalc

$(PLATEDESIGN_DIR)/bin/skycalc: skycalc.c
	$(CC) -o skycalc skycalc.c -lm
	mv -f skycalc $(PLATEDESIGN_DIR)/bin/skycalc

clean:
	rm -f skycalc
