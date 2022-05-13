ca65 xfabriek.s -g -o xfabriek.o
ld65 -o xfabriek.prg -C xfabriek.cfg xfabriek.o -m xfabriek.map.txt -Ln xfabriek.labels.txt --dbgfile xfabriek.prg.dbg
