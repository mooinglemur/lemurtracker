
.proc draw ; affects A,X,Y,xf_tmp1,xf_tmp2,xf_tmp3

    ; Header
    VERA_SET_ADDR (((InstState::INSTRUMENTS_LOCATION_Y-1)*256)+((InstState::INSTRUMENTS_LOCATION_X+2)*2)+Vera::VRAM_text),2


    ldx #0
    :
        lda header_text,x
        beq :+
        sta Vera::Reg::Data0
        inx
        bra :-
    :
    ; Top of grid
    VERA_SET_ADDR ((InstState::INSTRUMENTS_LOCATION_Y*256)+((InstState::INSTRUMENTS_LOCATION_X+2)*2)+Vera::VRAM_text),2


    lda #CustomChars::GRID_TOP_LEFT
    sta Vera::Reg::Data0
    ldx #(InstState::INSTRUMENTS_GRID_WIDTH-1)
    :
        lda #CustomChars::GRID_TOP
        sta Vera::Reg::Data0
        dex
        bne :-

    lda #CustomChars::GRID_TOP_RIGHT
    sta Vera::Reg::Data0

    ; start on row INSTRUMENTS_LOCATION+1
    lda #InstState::INSTRUMENTS_LOCATION_Y+1
    sta xf_tmp1
    lda InstState::y_position
    sec
    sbc #4
    sta xf_tmp2
    stz xf_tmp3

rowstart:
    lda #(1 | $10) ; high bank, stride = 1
    sta $9F22

    lda xf_tmp1 ; row number
    clc
    adc #$b0
    sta $9F21

    lda #(InstState::INSTRUMENTS_LOCATION_X*2) ; grid start
    sta $9F20

    lda xf_tmp3
    beq :+
        jmp blankrow
    :

    lda xf_tmp2
    ldy xf_tmp1
    cpy #(InstState::INSTRUMENTS_LOCATION_Y+(InstState::INSTRUMENTS_GRID_ROWS/2)+1)
    bcs :++
        cmp InstState::y_position
        bcc :+
            jmp blankrow
        :
        bra filledrow
    :

    ldy xf_tmp2
    cpy InstState::max_instrument
    bne :+
        inc xf_tmp3
    :
    cmp InstState::y_position
    bcs filledrow

filledrow:
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    cmp InstState::y_position ; comparing .A which is the current row being drawn
    bne :+
        ldy #((XF_BASE_BG_COLOR>>4)|(XF_BASE_FG_COLOR<<4)) ; invert
    :
    jsr xf_byte_to_hex

    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    ldy xf_tmp2
    jsr InstState::set_lookup_addr

    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    lda (InstState::lookup_addr)
    bne :+
        jmp unconfigured_row
    :

    ldx #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)

    ldy #1
    lda (InstState::lookup_addr),y

    ; use a grid tile if possible in first position
    bne :+ ; null
        lda #CustomChars::GRID_LEFT
        bra first_character
    :
    cmp #$20 ; space
    bne :+
        lda #CustomChars::GRID_LEFT
        bra first_character
    :
    cmp #$30 ; numeral 0
    bcc first_character
    cmp #$5B ; one after Z
    bcs first_character
    adc #$50 ; carry is clear, gets the numbers into the right range
    cmp #$8A ; letters or numbers?
    bcc first_character ; numbers, we're in the correct place
    sbc #$07 ; carry is set, we're probably a letter, so shift down to the correct place
    cmp #$8A ; are we really letters though?
    bcs first_character ; ah, we are
    sbc #$48 ; oh no, we're not letters, carry is clear so we're really subtracting $49
             ; go back to where we started
first_character:
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
rest_of_characters:
    ldy #2
    :
        lda (InstState::lookup_addr),y
        beq end_string
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        iny
        cpy #16
        bcc :-
        bra end_name
end_string:
    lda #$20
    :
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        iny
        cpy #16
        bcc :-

end_name:
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)

    lda (InstState::lookup_addr)
    asl
    asl
    tax
    lda InstState::instrument_type,x
    sta Vera::Reg::Data0
    lda InstState::instrument_type_color,x
    sta Vera::Reg::Data0

    lda InstState::instrument_type+1,x
    sta Vera::Reg::Data0
    lda InstState::instrument_type_color+1,x
    sta Vera::Reg::Data0

    lda InstState::instrument_type+2,x
    sta Vera::Reg::Data0
    lda InstState::instrument_type_color+2,x
    sta Vera::Reg::Data0

    lda InstState::instrument_type+3,x
    sta Vera::Reg::Data0
    lda InstState::instrument_type_color+3,x
    sta Vera::Reg::Data0

    bra endofrow
unconfigured_row:
    lda #CustomChars::NOTE_DOT
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    ldx #(InstState::INSTRUMENTS_GRID_WIDTH-1)
    :
        lda #'.'
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        dex
        bne :-
    bra endofrow
blankrow:
    lda #$20
    ldy #%00000001 ; color value for blank row is 0 bg, 1 fg
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    lda #CustomChars::GRID_LEFT
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    ldx #(InstState::INSTRUMENTS_GRID_WIDTH-1)
    :
        lda #' '
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        dex
        bne :-

endofrow:
    lda #CustomChars::GRID_RIGHT
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    lda xf_tmp3
    bne :+
        inc xf_tmp2
    :
    inc xf_tmp1
    lda xf_tmp1
    cmp #(InstState::INSTRUMENTS_LOCATION_Y+InstState::INSTRUMENTS_GRID_ROWS+1)
    bcs :+
        jmp rowstart
    :

;   Bottom of grid
    VERA_SET_ADDR (((InstState::INSTRUMENTS_LOCATION_Y+InstState::INSTRUMENTS_GRID_ROWS+1) * 256)+((InstState::INSTRUMENTS_LOCATION_X+2)*2)+Vera::VRAM_text),2

    lda #CustomChars::GRID_BOTTOM_LEFT
    sta Vera::Reg::Data0
    ldx #(InstState::INSTRUMENTS_GRID_WIDTH-1)
    :
        lda #CustomChars::GRID_BOTTOM
        sta Vera::Reg::Data0
        dex
        bne :-

    lda #CustomChars::GRID_BOTTOM_RIGHT
    sta Vera::Reg::Data0


; now put the cursor where it belongs
    lda #(1 | $20) ; high page, stride = 2
    sta $9F22

    lda #(InstState::INSTRUMENTS_LOCATION_Y+InstState::INSTRUMENTS_GRID_ROWS/2+1)
    clc
    adc #$b0
    sta $9F21

    lda #(InstState::INSTRUMENTS_LOCATION_X+2)
    asl
    inc

    sta $9F20

    lda #(XF_CURSOR_BG_COLOR|XF_BASE_FG_COLOR)
    ldx xf_state
    cpx #XF_STATE_INSTRUMENTS
    bne :+
        lda #(XF_AUDITION_BG_COLOR|XF_BASE_FG_COLOR)
        ldx GridState::entrymode
        beq :+
        lda #(XF_NOTE_ENTRY_BG_COLOR|XF_BASE_FG_COLOR)
    :
    ldx #16
    :
        sta Vera::Reg::Data0
        dex
        bne :-

    rts
.endproc

header_text: .byte "Instruments [F3]",0
