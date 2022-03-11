
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


	
xf_draw_tracker_grid: ; affects A,X,Y,xf_tmp1,xf_tmp2,xf_tmp3

	; Top of grid
	VERA_SET_ADDR $0206,2

	;lda #$A3
	;sta VERA_data0
	
	ldx #8
	:
		lda #$A1
		sta VERA_data0
		lda #$A0
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		dex
		bne :-
	lda #$A2
	sta VERA_data0

	
	; cycle through 40 rows
	; start on row 3
	lda #3
	sta xf_tmp1
	lda tracker_y_position
	sec
	sbc #20
	sta xf_tmp2
	stz xf_tmp3

@rowstart:
	lda #(0 | $10) ; low page, stride = 1
	sta $9F22

	lda xf_tmp1 ; row number
	sta $9F21

	lda #2 ; one character over
	sta $9F20

	lda xf_tmp3
	beq :+
		jmp @blankrow
	:

	lda xf_tmp2
	ldy xf_tmp1
	cpy #23
	bcs :++
		cmp tracker_y_position
		bcc :+
			jmp @blankrow
		:
		bra @filledrow
	:

	ldy xf_tmp2
	cpy tracker_global_frame_length
	bne :+
		inc xf_tmp3
	:
	cmp tracker_y_position
	bcs @filledrow

@filledrow:
	jsr xf_byte_to_hex
	ldy #(XF_BASE_BG_COLOR | XF_BASE_FG_COLOR)
	sta VERA_data0
	sty VERA_data0
	stx VERA_data0
	sty VERA_data0

	; color current row
	lda xf_tmp2
	cmp tracker_y_position
	bne :+
		ldy #(XF_AUDITION_BG_COLOR | XF_BASE_FG_COLOR)
		bra @got_color
	:
	; color every 16 rows
	lda xf_tmp2
	and #%11110000
	cmp xf_tmp2
	bne :+
		ldy #(XF_HILIGHT_BG_COLOR_2 | XF_BASE_FG_COLOR)
		bra @got_color
	:
	; color every 4 rows
	lda xf_tmp2
	and #%11111100
	cmp xf_tmp2
	bne :+
		ldy #(XF_HILIGHT_BG_COLOR_1 | XF_BASE_FG_COLOR)
		bra @got_color
	:


@got_color:
	ldx #8
	:
		lda #$A4
		sta VERA_data0
		sty VERA_data0
		lda #'.'
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		dex
		bne :-
	lda #$A3
	sta VERA_data0
	ldy #(XF_BASE_BG_COLOR | XF_BASE_FG_COLOR)
	sty VERA_data0

	bra @endofrow
@blankrow:
	lda #$20
	ldy #%00000001 ; color value for blank row is 0 bg, 1 fg
	sta VERA_data0
	sty VERA_data0
	sta VERA_data0
	sty VERA_data0

	ldx #8
	:
		lda #$A3
		sta VERA_data0
		sty VERA_data0
		lda #' '
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		sta VERA_data0
		sty VERA_data0
		dex
		bne :-
	lda #$A3
	sta VERA_data0
	ldy #(XF_BASE_BG_COLOR | XF_BASE_FG_COLOR)
	sty VERA_data0

@endofrow:
	lda xf_tmp3
	bne :+
		inc xf_tmp2
		

	:
	inc xf_tmp1
	lda xf_tmp1
	cmp #43
	bcs :+
		jmp @rowstart
	:

; now put the cursor where it belongs
	lda #(0 | $20) ; low page, stride = 2
	sta $9F22

	lda #23 ; row number
	sta $9F21

	lda tracker_x_position
	asl
	asl
	asl
	
	clc
	adc tracker_cursor_position
	adc #3
	asl
	ina

	sta $9F20
	
	lda #(XF_CURSOR_BG_COLOR | XF_BASE_FG_COLOR)
	sta VERA_data0

	ldy tracker_cursor_position
	bne :+
		sta VERA_data0
	:



;	lda #$81
;	sta VERA_data0
;	lda #$91
;	sta VERA_data0



;@colorcursorline:
;	lda #(0 | $20) ; low page, stride = 2
;	sta $9F22
;
;	lda #23; row number
;	sta $9F21
;
;	lda #7 ; address color memory inside grid
;	sta $9F20
;	
;	ldx #70
;	lda #%00100001
;	:
;		sta VERA_data0
;		dex
;		bne :-
;
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
