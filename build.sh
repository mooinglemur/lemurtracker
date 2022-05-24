if [[ -e .git ]]; then
	echo 'githash: .asciiz "'$(git rev-parse --short HEAD)'"' > githash.s
else
	echo 'githash: .asciiz ""' > githash.s
fi
ca65 lemurtracker.s -g -o lemurtracker.o
ld65 -o lemurtracker.prg -C lemurtracker.cfg lemurtracker.o -m lemurtracker.map.txt -Ln lemurtracker.labels.txt --dbgfile lemurtracker.prg.dbg
