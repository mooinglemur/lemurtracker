xf_draw_tracker_grid: ; affects A,X,Y,xf_tmp1,xf_tmp2,xf_tmp3

	; Top of grid
	VERA_SET_ADDR ($0206+$1B000),2

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
	lda #(1 | $10) ; high bank, stride = 1
	sta $9F22

	lda xf_tmp1 ; row number
  clc
  adc #$b0
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
	ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
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
	ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
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
	lda #(1 | $20) ; high page, stride = 2
	sta $9F22

	lda #23 ; row number
  clc
  adc #$b0
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
