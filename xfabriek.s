
; Xfabriek - started 2022-02-18
; by MooingLemur
; License: GPLv2 or, at your option, any later version

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
.include "cx16-concerto/concerto_synth/concerto_synth.asm"

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
	jsr xf_draw_tracker_grid

;	DO THIS WHEN WE'RE EXITING FOR REAL
;	jsr xf_reset_charset
	rts

xf_set_charset:
	lda #3
	jmp SCREEN_SET_CHARSET ; jmp replaces jsr followed by ret

xf_reset_charset:
	lda #2
	jmp SCREEN_SET_CHARSET ; jmp replaces jsr followed by ret

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


	
xf_draw_tracker_grid: ; affects A,X,Y,xf_tmp1,xf_tmp2

	; Top of grid
	VERA_SET_ADDR $0206,2

	;lda #$A3
	;sta VERA_data0
	
	ldx #10
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
		dex
		bne :-
	lda #$A2
	sta VERA_data0

	
	; cycle through 40 rows
	; start on row 3
	lda #3
	sta xf_tmp1
	lda tracker_y_position
	sta xf_tmp2

@rowstart:
	lda #(0 | $20) ; low page, stride = 2
	sta $9F22

	lda xf_tmp1 ; row number
	sta $9F21

	lda #2 ; one character over
	sta $9F20
	
	lda xf_tmp2
	jsr xf_byte_to_hex
	sta VERA_data0
	stx VERA_data0

	ldx #10
	:
		lda #$A4
		sta VERA_data0
		lda #'.'
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		sta VERA_data0
		dex
		bne :-
	lda #$A3
	sta VERA_data0


	inc xf_tmp2
	inc xf_tmp1
	lda xf_tmp1
	cmp #43
	bcc @rowstart


;	lda #$81
;	sta VERA_data0
;	lda #$91
;	sta VERA_data0

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
