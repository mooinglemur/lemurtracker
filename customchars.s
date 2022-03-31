.segment "CODE"

xf_install_custom_chars:
	VERA_SET_ADDR $1F400, 1 ; second half of tileset
	ldx #0
	:
		lda xf_note_chars,x
		sta VERA_data0
		inx
		cpx #(8*12)
		bne :-

	ldx #0
	:
		lda xf_octave_sharp_chars,x
		sta VERA_data0
		inx
		cpx #(8*20)
		bne :-

	ldx #0
	:
		lda xf_graphic_chars,x
		sta VERA_data0
		inx
		cpx #(8*5)
		bne :-

	rts




; Custom characters for notes

xf_graphic_chars:
	; _
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111
	.byte %00000000

	; ,_
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111
	.byte %10000000

	; ,
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %10000000
	.byte %10000000

	; |
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000

	; |.
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10011000
	.byte %10011000
	.byte %10000000

	; |-
	.byte %10000000
	.byte %10000000
	.byte %10000000
	.byte %10111111
	.byte %10111111
	.byte %10000000
	.byte %10000000
	.byte %10000000

	; -
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111110
	.byte %11111110
	.byte %00000000
	.byte %00000000
	.byte %00000000

	; |=
	.byte %10000000
	.byte %10000000
	.byte %10111111
	.byte %10000000
	.byte %10111111
	.byte %10000000
	.byte %10000000
	.byte %10000000

	; =
	.byte %00000000
	.byte %00000000
	.byte %11111110
	.byte %00000000
	.byte %11111110
	.byte %00000000
	.byte %00000000
	.byte %00000000

xf_note_chars:
	; C
	.byte %10011000
	.byte %10100000
	.byte %10100000
	.byte %10100000
	.byte %10100000
	.byte %10100000
	.byte %10011000
	.byte %10000000

	; C#
	.byte %10011001
	.byte %10100011
	.byte %10100001
	.byte %10100011
	.byte %10100001
	.byte %10100000
	.byte %10011000
	.byte %10000000

	; D
	.byte %10110000
	.byte %10101000
	.byte %10101000
	.byte %10101000
	.byte %10101000
	.byte %10101000
	.byte %10110000
	.byte %10000000

	; D#
	.byte %10110001
	.byte %10101011
	.byte %10101001
	.byte %10101011
	.byte %10101001
	.byte %10101000
	.byte %10110000
	.byte %10000000

	; E
	.byte %10111000
	.byte %10100000
	.byte %10100000
	.byte %10110000
	.byte %10100000
	.byte %10100000
	.byte %10111000
	.byte %10000000

	; F
	.byte %10111000
	.byte %10100000
	.byte %10100000
	.byte %10110000
	.byte %10100000
	.byte %10100000
	.byte %10100000
	.byte %10000000

	; F#
	.byte %10111001
	.byte %10100011
	.byte %10100001
	.byte %10110011
	.byte %10100001
	.byte %10100000
	.byte %10100000
	.byte %10000000

	; G
	.byte %10011000
	.byte %10100000
	.byte %10100000
	.byte %10101000
	.byte %10101000
	.byte %10101000
	.byte %10011000
	.byte %10000000

	; G#
	.byte %10011001
	.byte %10100011
	.byte %10100001
	.byte %10101011
	.byte %10101001
	.byte %10101000
	.byte %10011000
	.byte %10000000

	; A
	.byte %10010000
	.byte %10101000
	.byte %10101000
	.byte %10111000
	.byte %10101000
	.byte %10101000
	.byte %10101000
	.byte %10000000

	; A#
	.byte %10010001
	.byte %10101011
	.byte %10101001
	.byte %10111011
	.byte %10101001
	.byte %10101000
	.byte %10101000
	.byte %10000000

	; B
	.byte %10110000
	.byte %10101000
	.byte %10101000
	.byte %10110000
	.byte %10101000
	.byte %10101000
	.byte %10110000
	.byte %10000000

xf_octave_sharp_chars:
	; 0
	.byte %00000100
	.byte %00001010
	.byte %00001010
	.byte %00001010
	.byte %00001010
	.byte %00001010
	.byte %00000100
	.byte %00000000

	; #0
	.byte %01000100
	.byte %11101010
	.byte %01001010
	.byte %11101010
	.byte %01001010
	.byte %00001010
	.byte %00000100
	.byte %00000000

	; 1
	.byte %00000100
	.byte %00001100
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00001110
	.byte %00000000

	; #1
	.byte %01000100
	.byte %11101100
	.byte %01000100
	.byte %11100100
	.byte %01000100
	.byte %00000100
	.byte %00001110
	.byte %00000000

	; 2
	.byte %00000100
	.byte %00001010
	.byte %00000010
	.byte %00000100
	.byte %00000100
	.byte %00001000
	.byte %00001110
	.byte %00000000

	; #2
	.byte %01000100
	.byte %11101010
	.byte %01000010
	.byte %11100100
	.byte %01000100
	.byte %00001000
	.byte %00001110
	.byte %00000000

	; 3
	.byte %00001100
	.byte %00000010
	.byte %00000010
	.byte %00001100
	.byte %00000010
	.byte %00000010
	.byte %00001100
	.byte %00000000

	; #3
	.byte %01001100
	.byte %11100010
	.byte %01000010
	.byte %11101100
	.byte %01000010
	.byte %00000010
	.byte %00001100
	.byte %00000000

	; 4
	.byte %00001010
	.byte %00001010
	.byte %00001010
	.byte %00001110
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000000

	; #4
	.byte %01001010
	.byte %11101010
	.byte %01001010
	.byte %11101110
	.byte %01000010
	.byte %00000010
	.byte %00000010
	.byte %00000000

	; 5
	.byte %00001110
	.byte %00001000
	.byte %00001000
	.byte %00001100
	.byte %00000010
	.byte %00000010
	.byte %00001100
	.byte %00000000

	; #5
	.byte %01001110
	.byte %11101000
	.byte %01001000
	.byte %11101100
	.byte %01000010
	.byte %00000010
	.byte %00001100
	.byte %00000000

	; 6
	.byte %00000110
	.byte %00001000
	.byte %00001000
	.byte %00001100
	.byte %00001010
	.byte %00001010
	.byte %00000100
	.byte %00000000

	; #6
	.byte %01000110
	.byte %11101000
	.byte %01001000
	.byte %11101100
	.byte %01001010
	.byte %00001010
	.byte %00000100
	.byte %00000000

	; 7
	.byte %00001110
	.byte %00000010
	.byte %00000010
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00000000

	; #7
	.byte %01001110
	.byte %11100010
	.byte %01000010
	.byte %11100100
	.byte %01000100
	.byte %00000100
	.byte %00000100
	.byte %00000000

	; 8
	.byte %00000100
	.byte %00001010
	.byte %00001010
	.byte %00000100
	.byte %00001010
	.byte %00001010
	.byte %00000100
	.byte %00000000

	; #8
	.byte %01000100
	.byte %11101010
	.byte %01001010
	.byte %11100100
	.byte %01001010
	.byte %00001010
	.byte %00000100
	.byte %00000000

	; 9
	.byte %00000100
	.byte %00001010
	.byte %00001010
	.byte %00000110
	.byte %00000010
	.byte %00000010
	.byte %00001100
	.byte %00000000

	; #9
	.byte %01000100
	.byte %11101010
	.byte %01001010
	.byte %11100110
	.byte %01000010
	.byte %00000010
	.byte %00001100
	.byte %00000000
