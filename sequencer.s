.scope Sequencer

; We don't use x_position here.  We use Grid::x_position instead
;x_position: .res 1 ; which tracker column (channel) are we in
y_position: .res 1 ; which tracker row are we in
max_frame: .res 1 ; the last frame in the sequencer
max_pattern: .res 1; the highest patten number we can fit in ram
mix: .res 1 ; which mix we're displaying
base_bank: .res 1 ; what bank are we going to use for the seq table
iterator: .res 1

NUM_CHANNELS = 8
SEQUENCER_LOCATION_X = 1
SEQUENCER_LOCATION_Y = 44
SEQUENCER_GRID_ROWS = 9

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2 ; storage for offset in banked ram
.popseg


draw: ; affects A,X,Y,xf_tmp1,xf_tmp2,xf_tmp3

    ; Top of grid
    VERA_SET_ADDR ((SEQUENCER_LOCATION_Y * 256)+((SEQUENCER_LOCATION_X+2)*2)+Vera::VRAM_text),2

    ;lda #$A3
    ;sta VERA_data0

    ldx #NUM_CHANNELS
    :
        lda #CustomChars::GRID_TOP_LEFT
        sta Vera::Reg::Data0
        lda #CustomChars::GRID_TOP
        sta Vera::Reg::Data0
        dex
        bne :-

    lda #CustomChars::GRID_TOP_RIGHT
    sta Vera::Reg::Data0


    ; cycle through 4 rows
    ; start on row SEQUENCER_LOCATION+1
    lda #SEQUENCER_LOCATION_Y+1
    sta xf_tmp1
    lda y_position
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

    lda #(SEQUENCER_LOCATION_X*2) ; grid start
    sta $9F20

    lda xf_tmp3
    beq :+
        jmp @blankrow
    :

    lda xf_tmp2
    ldy xf_tmp1
    cpy #(SEQUENCER_LOCATION_Y+(SEQUENCER_GRID_ROWS/2)+1)
    bcs :++
        cmp y_position
        bcc :+
            jmp @blankrow
        :
        bra @filledrow
    :

    ldy xf_tmp2
    cpy max_frame
    bne :+
        inc xf_tmp3
    :
    cmp y_position
    bcs @filledrow

@filledrow:
    jsr xf_byte_to_hex
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    stz iterator


    ldy xf_tmp2 ; the row we're drawing
    jsr set_lookup_addr
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)

; draw row
    ldx #0
    :
        phx

        phy
        phx
        ply
        lda (lookup_addr),y
        ldx xf_tmp2
        cpx y_position
        bne @not_current_row

        ; current drawing == eq current row
        ; set the grid state to reflect the sequencer, it's important
        sta Grid::channel_to_pattern,y
        ply
        pha

        lda xf_state
        cmp #XF_STATE_MIX_EDITOR
        bne @got_color

        lda Grid::entrymode
        bne @entry_mode

        ldy #(XF_AUDITION_BG_COLOR|XF_BASE_FG_COLOR)
        bra @got_color
@entry_mode:
        ldy #(XF_NOTE_ENTRY_BG_COLOR|XF_BASE_FG_COLOR)
@got_color:
        pla
        phy
@not_current_row:
        jsr xf_byte_to_hex_in_grid
        ply
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        stx Vera::Reg::Data0
        sty Vera::Reg::Data0

        plx
        inx
        cpx #NUM_CHANNELS
        bne :-

    bra @endofrow
@blankrow:
    lda #$20
    ldy #%00000001 ; color value for blank row is 0 bg, 1 fg
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    ldx #NUM_CHANNELS
    :
        lda #CustomChars::GRID_LEFT
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        lda #' '
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        dex
        bne :-

@endofrow:

    lda #CustomChars::GRID_RIGHT
    ldy #%00000001 ; color value for blank row is 0 bg, 1 fg
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    lda xf_tmp3
    bne :+
        inc xf_tmp2


    :
    inc xf_tmp1
    lda xf_tmp1
    cmp #(SEQUENCER_LOCATION_Y+SEQUENCER_GRID_ROWS+1)
    bcs :+
        jmp @rowstart
    :

;   Bottom of grid
    VERA_SET_ADDR (((SEQUENCER_LOCATION_Y+SEQUENCER_GRID_ROWS+1) * 256)+((SEQUENCER_LOCATION_X+2)*2)+Vera::VRAM_text),2

    ;lda #$A3
    ;sta VERA_data0

    ldx #NUM_CHANNELS
    :
        lda #CustomChars::GRID_BOTTOM
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        dex
        bne :-
    lda #CustomChars::GRID_BOTTOM_RIGHT
    sta Vera::Reg::Data0



; now put the cursor where it belongs
    lda #(1 | $20) ; high page, stride = 2
    sta $9F22

    lda #(SEQUENCER_LOCATION_Y+SEQUENCER_GRID_ROWS/2+1)
    clc
    adc #$b0
    sta $9F21

    lda Grid::x_position
    asl

    adc #3
    asl
    inc

    sta $9F20


    ldy #(XF_CURSOR_BG_COLOR|XF_BASE_FG_COLOR)

    sty Vera::Reg::Data0
    sty Vera::Reg::Data0


    rts


update_grid_patterns:
    ldy y_position
    jsr set_lookup_addr
    ldy #0
    :
        lda (lookup_addr),y
        sta Grid::channel_to_pattern,y
        iny
        cpy #Grid::NUM_CHANNELS
        bcc :-

    rts


set_lookup_addr: ; input: .Y = row
    lda base_bank
    sta x16::Reg::RAMBank

    stz lookup_addr+1

    tya ; the row we're drawing
    asl
    rol lookup_addr+1
    asl
    rol lookup_addr+1
    asl
    rol lookup_addr+1
    sta lookup_addr

    lda mix
    asl
    asl
    clc
    adc #$A0
    adc lookup_addr+1
    sta lookup_addr+1

    rts
.endscope
