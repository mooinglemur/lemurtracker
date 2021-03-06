.proc draw ; affects A,X,Y,zp_tmp1,zp_tmp2,zp_tmp3

    ; Label + Mix header
    VERA_SET_ADDR (((SeqState::SEQUENCER_LOCATION_Y-1)*256)+((SeqState::SEQUENCER_LOCATION_X+2)*2)+Vera::VRAM_text),2

    ldx #0
    :
        lda header_text,x
        beq :+
        sta Vera::Reg::Data0
        inx
        bra :-
    :

    lda SeqState::mix
    jsr Util::byte_to_hex
    stx Vera::Reg::Data0


    ; Top of grid
    VERA_SET_ADDR ((SeqState::SEQUENCER_LOCATION_Y*256)+((SeqState::SEQUENCER_LOCATION_X+2)*2)+Vera::VRAM_text),2

    ldx #SeqState::NUM_CHANNELS
    :
        lda #CustomChars::GRID_TOP_LEFT
        sta Vera::Reg::Data0
        lda #CustomChars::GRID_TOP
        sta Vera::Reg::Data0
        dex
        bne :-

    lda #CustomChars::GRID_TOP_RIGHT
    sta Vera::Reg::Data0

    ; start on row SEQUENCER_LOCATION+1
    lda #SeqState::SEQUENCER_LOCATION_Y+1
    sta zp_tmp1
    lda SeqState::y_position
    sec
    sbc #4
    sta zp_tmp2
    stz zp_tmp3

@rowstart:
    lda #(1 | $10) ; high bank, stride = 1
    sta $9F22

    lda zp_tmp1 ; row number
    clc
    adc #$b0
    sta $9F21

    lda #(SeqState::SEQUENCER_LOCATION_X*2) ; grid start
    sta $9F20

    lda zp_tmp3
    beq :+
        jmp @blankrow
    :

    lda zp_tmp2
    ldy zp_tmp1
    cpy #(SeqState::SEQUENCER_LOCATION_Y+(SeqState::SEQUENCER_GRID_ROWS/2)+1)
    bcs :++
        cmp SeqState::y_position
        bcc :+
            jmp @blankrow
        :
        bra @filledrow
    :

    ldy zp_tmp2
    cpy SeqState::max_row
    bne :+
        inc zp_tmp3
    :
    cmp SeqState::y_position
    bcs @filledrow

@filledrow:
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    cmp SeqState::y_position ; comparing .A which is the current row being drawn
    bne :+
        ldy #((XF_BASE_BG_COLOR>>4)|(XF_BASE_FG_COLOR<<4)) ; invert
    :
    jsr Util::byte_to_hex


    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    stz SeqState::iterator


    ldy zp_tmp2 ; the row we're drawing
    jsr SeqState::set_lookup_addr

; draw row
    ldx #0
@rowloop:
    phx ; save iterator

    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR) ; default color

    lda xf_state
    cmp #XF_STATE_SEQUENCER
    bne @after_selection

    lda zp_tmp2 ; the row we're drawing

    cmp SeqState::y_position
    bne @continue_row

    lda GridState::entrymode
    bne @entry_mode


    ldy #(XF_AUDITION_BG_COLOR|XF_BASE_FG_COLOR)
    bra @continue_row
@entry_mode:
    ldy #(XF_NOTE_ENTRY_BG_COLOR|XF_BASE_FG_COLOR)
@continue_row:


    lda SeqState::selection_active
    beq @after_selection

    lda zp_tmp2

    cmp SeqState::selection_top_y
    bcc @after_selection

    cmp SeqState::selection_bottom_y
    beq :+
        bcs @after_selection
    :

    ldy #(XF_SELECTION_BG_COLOR|XF_BASE_FG_COLOR)
@after_selection:
    sty SeqState::tmpcolor ; save color
    phx ; transfer iterator...
    ply ; to y register
    lda (SeqState::lookup_addr),y ; so that I can do indirect indexed
    cmp #$FF
    bne @after_inherit_check
    lda SeqState::tmpcolor
    and #$F0
    ora #XF_DIM_FG_COLOR
    sta SeqState::tmpcolor
    lda (SeqState::mix0_lookup_addr),y
@after_inherit_check:
    jsr Util::byte_to_hex_in_grid
    ldy SeqState::tmpcolor ; restore color
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    plx ; restore iterator
    inx
    cpx #SeqState::NUM_CHANNELS
    bne @rowloop

    bra @endofrow
@blankrow:
    lda #$20
    ldy #%00000001 ; color value for blank row is 0 bg, 1 fg
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    ldx #SeqState::NUM_CHANNELS
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

    lda zp_tmp3
    bne :+
        inc zp_tmp2


    :
    inc zp_tmp1
    lda zp_tmp1
    cmp #(SeqState::SEQUENCER_LOCATION_Y+SeqState::SEQUENCER_GRID_ROWS+1)
    bcs :+
        jmp @rowstart
    :

;   Bottom of grid
    VERA_SET_ADDR (((SeqState::SEQUENCER_LOCATION_Y+SeqState::SEQUENCER_GRID_ROWS+1) * 256)+((SeqState::SEQUENCER_LOCATION_X+2)*2)+Vera::VRAM_text),2

    ldx #SeqState::NUM_CHANNELS
    :
        lda #CustomChars::GRID_BOTTOM
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        dex
        bne :-
    lda #CustomChars::GRID_BOTTOM_RIGHT
    sta Vera::Reg::Data0

    lda xf_state
    cmp #XF_STATE_GRID
    beq @cursor
    cmp #XF_STATE_SEQUENCER
    beq @cursor
    bra @after_cursor

@cursor:
; now put the cursor where it belongs
    lda #(1 | $20) ; high page, stride = 2
    sta $9F22

    lda #(SeqState::SEQUENCER_LOCATION_Y+SeqState::SEQUENCER_GRID_ROWS/2+1)
    clc
    adc #$b0
    sta $9F21

    lda GridState::x_position
    asl

    adc #3
    asl
    inc

    sta $9F20


    ldy #(XF_CURSOR_BG_COLOR|XF_BASE_FG_COLOR)

    sty Vera::Reg::Data0
    sty Vera::Reg::Data0
@after_cursor:
    ; we fall into update_grid_patterns
    jmp SeqState::update_grid_patterns
.endproc

header_text: .byte "Seq [F2]   Mix ",0
