
; Xfabriek - started 2022-02-18
; by MooingLemur

; Music tracker for the Commander X16

; Let's start with something simple

; This is for the 65C02.  This assembler directive enables
; the use of 65C02-specific mnemonics.
; (PHX/PLX, PHY/PLY, BRA, ...)
.PC02


; Add the PRG header
.segment "HEADER"
.word $0801

.segment "CODE"
; Add a BASIC startline
.word entry-2
.byte $00,$00,$9e
.byte "2061"
.byte $00,$00,$00

; Entry point at $080d
entry:
	jmp main

.include "cx16-concerto/concerto_synth/x16.asm"
.include "macros.inc"
.include "customchars.s"
concerto_use_timbres_from_file = 1
.define CONCERTO_TIMBRES_PATH "cx16-concerto/FACTORY.COB"
.include "cx16-concerto/concerto_synth/concerto_synth.asm"
.include "irq.s"
.include "tracker_grid.s"

XF_BASE_BG_COLOR = $00 ; black
XF_AUDITION_BG_COLOR = $60 ; blue
XF_NOTE_ENTRY_BG_COLOR = $20 ; red
XF_CURSOR_BG_COLOR = $F0 ; light grey
XF_HILIGHT_BG_COLOR_1 = $B0 ; dark grey
XF_HILIGHT_BG_COLOR_2 = $C0 ; grey

XF_BASE_FG_COLOR = $01 ; white
XF_NOTE_FG_COLOR = $05 ; green
XF_INST_FG_COLOR = $03 ; cyan

.segment "BSS"
tracker_x_position: .res 1 ; which tracker column (voice) are we in
tracker_y_position: .res 1 ; which tracker row are we in
tracker_cursor_position: .res 1 ; within the column (voice) where is the cursor?
tracker_frame_x_offset: .res 1 ; in the frame editor, what voice (column) are we in
tracker_frame_y_offset: .res 1 ; in the frame editor, what row are we in?
tracker_frame_mix: .res 1 ; in the frame editor, what mix's patterns are we showing?
tracker_songno: .res 1 ; what song are we showing?
tracker_global_frame_length: .res 1 ; frame length for frames that don't end early.

XF_PATTERN_PAGE = 16
XF_BASE_PAGE = 1
.segment "ZEROPAGE"
xf_tmp1: .res 1
xf_tmp2: .res 1
xf_tmp3: .res 1

.segment "CODE"


main:
	jsr xf_set_charset
	jsr xf_clear_screen
	jsr xf_install_custom_chars
	lda #$3F
	sta tracker_global_frame_length

	jsr xf_irq::setup
	jsr concerto_synth::initialize


@mainloop:
	jsr xf_draw_tracker_grid
	wai

	VERA_SET_ADDR $0000,2
	jsr GETIN
	pha

	beq :+
	jsr xf_byte_to_hex
	sta VERA_data0
	stx VERA_data0
	:

	VERA_SET_ADDR $0010,2
	lda tracker_cursor_position
	jsr xf_byte_to_hex
	sta VERA_data0
	stx VERA_data0

	lda tracker_x_position
	jsr xf_byte_to_hex
	sta VERA_data0
	stx VERA_data0

	pla
	cmp #$11 ; down
	bne :++
		ldy tracker_y_position
		cpy tracker_global_frame_length
		bcc :+
			stz tracker_y_position
			bra :++
		:
		inc tracker_y_position
	:
	cmp #$91 ; up
	bne :++
		ldy tracker_y_position
		bne :+
			ldy tracker_global_frame_length
			sty tracker_y_position
			bra :++

		:
		dec tracker_y_position
	:
	cmp #$9D ; left
	bne @endleft
		ldx tracker_cursor_position
		dex
		cpx #1
		bne :+
			dex
		:
		cpx #8
		bcc :+
			ldx #7
			dec tracker_x_position
			ldy tracker_x_position
			cpy #8
			bcc :+
			stx tracker_x_position
		:
		stx tracker_cursor_position

	@endleft:
	cmp #$1D ; right
	bne @endright
		ldx tracker_cursor_position
		inx
		cpx #1
		bne :+
			inx
		:
		cpx #8
		bcc :+
			ldx #0
			inc tracker_x_position
			ldy tracker_x_position
			cpy #8
			bcc :+
			stz tracker_x_position
		:
		stx tracker_cursor_position

	@endright:
	cmp #$51 ; Q
	bne :+
		ldy #1
		sty concerto_synth::note_channel
		ldy tracker_y_position
		sty concerto_synth::note_timbre
		ldy #50
		sty concerto_synth::note_pitch
		lda #63

		jsr concerto_synth::play_note
	:
	jmp @mainloop
@exit:
;	DO THIS WHEN WE'RE EXITING FOR REAL
	jsr xf_irq::teardown
	jsr xf_reset_charset
	rts

xf_set_charset:
	lda #3
	jmp SCREEN_SET_CHARSET ; jmp replaces jsr followed by rts

xf_reset_charset:
	lda #2
	jmp SCREEN_SET_CHARSET ; jmp replaces jsr followed by rts

xf_clear_screen:
	VERA_SET_ADDR $0000,1
	ldy #64 ; rows
	ldx #128 ; columns
	:
		lda #32 ; empty tile
		sta VERA_data0
		lda #%00000001 ; (BBBB|FFFF) background and foreground colors
		sta VERA_data0
		dex
		bne :-
		dey
		bne :-

	rts




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
