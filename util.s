
xf_byte_to_hex: ; converts a number to two ASCII/PETSCII hex digits: input A = number to convert, output A = most sig nybble, X = least sig nybble, affects A,X
	pha

	and #$0f
	tax
	pla
	lsr
	lsr
	lsr
	lsr
	pha
	txa
	jsr @hexify
	tax
	pla
@hexify:
	cmp #10
	bcc @nothex
	adc #$66
@nothex:
	eor #%00110000
	rts
