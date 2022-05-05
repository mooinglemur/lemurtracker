.scope Sequencer

; We don't use x_position here.  We use Grid::x_position instead
;x_position: .res 1 ; which tracker column (channel) are we in
y_position: .res 1 ; which tracker row are we in
max_row: .res 1 ; the last row shown in the sequencer
max_pattern: .res 1; the highest patten number we can fit in ram
mix: .res 1 ; which mix we're displaying
base_bank: .res 1 ; what bank are we going to use for the seq table
iterator: .res 1

NUM_CHANNELS = 8
SEQUENCER_LOCATION_X = 1
SEQUENCER_LOCATION_Y = 45
SEQUENCER_GRID_ROWS = 9

MIX_LIMIT = 8
ROW_LIMIT = 128 ; hard limit, row count

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2 ; storage for offset in banked ram
mix0_lookup_addr: .res 2 ; storage for offset into banked ram but for mix 0
.popseg

; selection_active = 0 for no selection
; bitfield
;     0 - selecting
;     1 - selection done
;     2 - 0 = selecting downward, 1 = selecting upward
;     3 - 0 = selecting rightward, 1 = selecting leftward

.pushseg
.segment "ZEROPAGE"
selection_active: .res 1
.popseg
selection_top_y: .res 1
selection_bottom_y: .res 1

tmpcolor: .res 1

init:
    ; clear sequencer bank memory
    ; set row 0 of mix 0 to all $00
    ; and all other rows of all mixes to $FF
    stz mix
    ldy #0
    jsr set_lookup_addr
    lda #0
@mainloop:
    ldy #0
@rowloop:
    sta (lookup_addr),y
    iny
    cpy #8
    bcc @rowloop
    lda lookup_addr
    clc
    adc #8
    sta lookup_addr
    lda lookup_addr+1
    adc #0
    cmp #$C0
    bcs @end
    sta lookup_addr+1
    lda #$FF
    bra @mainloop
@end:
    rts


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
    cpy max_row
    bne :+
        inc xf_tmp3
    :
    cmp y_position
    bcs @filledrow

@filledrow:
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    cmp y_position ; comparing .A which is the current row being drawn
    bne :+
        ldy #((XF_BASE_BG_COLOR>>4)|(XF_BASE_FG_COLOR<<4)) ; invert
    :
    jsr xf_byte_to_hex


    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    stz iterator


    ldy xf_tmp2 ; the row we're drawing
    jsr set_lookup_addr

; draw row
    ldx #0
@rowloop:
    phx ; save iterator

    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR) ; default color

    lda xf_state
    cmp #XF_STATE_SEQUENCER
    bne @after_selection

    lda xf_tmp2 ; the row we're drawing

    cmp y_position
    bne @continue_row

    lda Grid::entrymode
    bne @entry_mode


    ldy #(XF_AUDITION_BG_COLOR|XF_BASE_FG_COLOR)
    bra @continue_row
@entry_mode:
    ldy #(XF_NOTE_ENTRY_BG_COLOR|XF_BASE_FG_COLOR)
@continue_row:


    lda selection_active
    beq @after_selection

    lda xf_tmp2

    cmp selection_top_y
    bcc @after_selection

    cmp selection_bottom_y
    beq :+
        bcs @after_selection
    :

    ldy #(XF_SELECTION_BG_COLOR|XF_BASE_FG_COLOR)
@after_selection:
    sty tmpcolor ; save color
    phx ; transfer iterator...
    ply ; to y register
    lda (lookup_addr),y ; so that I can do indirect indexed
    cmp #$FF
    bne @after_inherit_check
    lda tmpcolor
    and #$F0
    ora #XF_DIM_FG_COLOR
    sta tmpcolor
    lda (mix0_lookup_addr),y
@after_inherit_check:
    jsr xf_byte_to_hex_in_grid
    ldy tmpcolor ; restore color
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    plx ; restore iterator
    inx
    cpx #NUM_CHANNELS
    bne @rowloop

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

    ; we fall into update_grid_patterns
update_grid_patterns:
    ldy y_position
    jsr set_lookup_addr
    ldy #0
@loop:
    ldx #0
    lda (lookup_addr),y
    cmp #$FF
    bcc :+
        lda (mix0_lookup_addr),y
        ldx #1
    :
    sta Grid::channel_to_pattern,y
    txa
    sta Grid::channel_is_inherited,y
    iny
    cpy #Grid::NUM_CHANNELS
    bcc @loop

    rts


set_ram_bank:
    lda base_bank
    sta x16::Reg::RAMBank
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
    sta mix0_lookup_addr

    lda mix
    asl
    asl
    clc
    adc #$A0
    adc lookup_addr+1
    sta lookup_addr+1
    and #$A3
    sta mix0_lookup_addr+1

    rts
.endscope
