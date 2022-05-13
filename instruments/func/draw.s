
draw: ; affects A,X,Y,xf_tmp1,xf_tmp2,xf_tmp3

    ; Top of grid
    VERA_SET_ADDR ((InstState::INSTRUMENTS_LOCATION_Y * 256)+((InstState::INSTRUMENTS_LOCATION_X+2)*2)+Vera::VRAM_text),2

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

@rowstart:
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
        jmp @blankrow
    :

    lda xf_tmp2
    ldy xf_tmp1
    cpy #(InstState::INSTRUMENTS_LOCATION_Y+(InstState::INSTRUMENTS_GRID_ROWS/2)+1)
    bcs :++
        cmp InstState::y_position
        bcc :+
            jmp @blankrow
        :
        bra @filledrow
    :

    ldy xf_tmp2
    cpy InstState::max_instrument
    bne :+
        inc xf_tmp3
    :
    cmp InstState::y_position
    bcs @filledrow

@filledrow:
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
    beq @unconfigured_row

    ldx #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)

    ldy #1
    lda (InstState::lookup_addr),y
    clc
    adc #$49
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    iny
    :
        lda (InstState::lookup_addr),y
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        iny
        cpy #16
        bne :-

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

    bra @endofrow
@unconfigured_row:
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
    bra @endofrow
@blankrow:
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

@endofrow:
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
        jmp @rowstart
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
    ina

    sta $9F20

    lda #(XF_CURSOR_BG_COLOR|XF_BASE_FG_COLOR)
    ldx #16
    :
        sta Vera::Reg::Data0
        dex
        bne :-

    rts
