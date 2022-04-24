.scope Grid

NUM_CHANNELS = 8
MAX_OCTAVE = 8
MAX_STEP = 15

; vars that keep state
x_position: .res 1 ; which tracker column (channel) are we in
y_position: .res 1 ; which tracker row are we in
cursor_position: .res 1 ; within the column (channel) where is the cursor?
global_pattern_length: .res 1 ; set on file create/file load
base_bank: .res 1 ; where does tracker data start
channel_to_pattern: .res NUM_CHANNELS ; which pattern is referenced in each channel
notechardata: .res 9*NUM_CHANNELS ; temp storage for characters based on pattern data
iterator: .res 1
entrymode: .res 1
short_hilight_interval: .res 1
long_hilight_interval: .res 1

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
selection_left_x: .res 1
selection_bottom_y: .res 1
selection_right_x: .res 1

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2 ; storage for offset in banked ram
.popseg

; vars that affect entry
octave: .res 1
step: .res 1

; temp vars
tmp1: .res 1
tmp2: .res 1
tmp3: .res 1




draw: ; affects A,X,Y,xf_tmp1,xf_tmp2,xf_tmp3


    ; Top of grid
    VERA_SET_ADDR ($0206+$1B000),2

    ;lda #$A3
    ;sta VERA_data0

    ldx #NUM_CHANNELS
    :
        lda #CustomChars::GRID_TOP_LEFT
        sta Vera::Reg::Data0
        lda #CustomChars::GRID_TOP
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        dex
        bne :-
    lda #CustomChars::GRID_TOP_RIGHT
    sta Vera::Reg::Data0


    ; cycle through 40 rows
    ; start on row 3
    lda #3
    sta xf_tmp1
    lda y_position
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
        cmp y_position
        bcc :+
            jmp @blankrow
        :
        bra @filledrow
    :

    ldy xf_tmp2
    iny
    cpy global_pattern_length
    bcc :+
        inc xf_tmp3
    :
    cmp y_position
    bcs @filledrow

@filledrow:
    jsr xf_byte_to_hex
    ldy #(XF_BASE_BG_COLOR | XF_BASE_FG_COLOR)
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    ; fetch note data from hiram. we can clobber registers here
    stz iterator

@fetch_notedata_loop:
    ldx iterator
    ldy xf_tmp2 ; the row we're drawing
    jsr set_lookup_addr

    txa
    asl
    asl
    asl
    clc
    adc iterator
    tax

    ldy #0
    lda (lookup_addr),y
    ; note
    bne @check_for_special_note

    lda #CustomChars::NOTE_DOT
    sta notechardata,x
    lda #'.'
    sta notechardata+1,x
    sta notechardata+2,x
    sta notechardata+3,x
    sta notechardata+4,x
    jmp @get_volume
@check_for_special_note:
    cmp #1
    beq @note_cut
    cmp #2
    beq @note_release
    bra @note_exists
@note_cut:
    lda #CustomChars::NOTE_CUT_LEFT
    sta notechardata,x
    lda #CustomChars::NOTE_CUT_MIDDLE
    sta notechardata+1,x
    lda #CustomChars::NOTE_CUT_RIGHT
    sta notechardata+2,x
    lda #'.'
    sta notechardata+3,x
    sta notechardata+4,x
    bra @get_volume
@note_release:
    lda #CustomChars::NOTE_REL_LEFT
    sta notechardata,x
    lda #CustomChars::NOTE_REL_MIDDLE
    sta notechardata+1,x
    lda #CustomChars::NOTE_REL_RIGHT
    sta notechardata+2,x
    lda #'.'
    sta notechardata+3,x
    sta notechardata+4,x
    bra @get_volume

@note_exists:
    ldy #0
    sec
@note_and_octave_loop: ; after this loop, A will contain the note and Y will contain the octave
    cmp #24
    bcc @found_octave
    iny
    sbc #12
    bra @note_and_octave_loop
@found_octave:
    phy
    sec
    sbc #12
    tay
    lda note_val,y
    sta notechardata,x
    lda note_sharp,y
    sta notechardata+1,x
    ply
    lda note_octave,y
    sta notechardata+2,x

@get_instrument_number:

    ldy #1
    lda (lookup_addr),y
    phx
    jsr xf_byte_to_hex
    ply
    phx
    phy
    plx
    sta notechardata+3,x
    pla
    sta notechardata+4,x
@get_volume: ; byte should be 1-16 and displayed value should be shifted down one
    lda #'.'
    sta notechardata+5,x
    ldy #2
    lda (lookup_addr),y
    beq :+
        phx
        dec
        jsr xf_byte_to_hex
        txa
        plx
        sta notechardata+5,x
    :
@get_effect:
    ldy #3
    lda (lookup_addr),y
    bne :+
        lda #'.'
        sta notechardata+6,x
        sta notechardata+7,x
        sta notechardata+8,x
        bra @end_column
    :
    sta notechardata+6,x
@get_effect_arg:
    ldy #4
    lda (lookup_addr),y
    phx
    jsr xf_byte_to_hex
    ply
    phx
    phy
    plx
    sta notechardata+7,x
    pla
    sta notechardata+8,x


@end_column:
    inc iterator
    lda iterator
    cmp #NUM_CHANNELS
    bcs :+
        jmp @fetch_notedata_loop
    :

    ldy #XF_BASE_BG_COLOR

    ; color current row
    lda xf_tmp2
    cmp y_position
    bne @not_current_row
        lda xf_state
        cmp #XF_STATE_PATTERN_EDITOR
        bne @not_current_row ; If we're not editing the pattern, don't hilight the current row
        ldy #XF_AUDITION_BG_COLOR
        lda entrymode
        beq :+
            ldy #XF_NOTE_ENTRY_BG_COLOR
        :

        bra @got_color
@not_current_row:

@long_hilight:
    ; color every 16 (or whatever) rows
    lda xf_tmp2
    sec
@long_hilight_loop:
    beq @do_long_hilight
    sbc long_hilight_interval
    bcc @short_hilight
    bra @long_hilight_loop
@do_long_hilight:
    ldy #XF_HILIGHT_BG_COLOR_2
    bra @got_color
@short_hilight:
    ; color every 4 (or whatever) rows
    lda xf_tmp2
    sec
@short_hilight_loop:
    beq @do_short_hilight
    sbc short_hilight_interval
    bcc @no_hilight
    bra @short_hilight_loop
@do_short_hilight:
    ldy #XF_HILIGHT_BG_COLOR_1
    bra @got_color
@no_hilight:
@got_color:

    sty tmp1 ; store background color here temp
    sty tmp2 ; store it here too, but switch this one to the selection color if appropriate
    ldx #0
    stz tmp3 ; channel column
@cell_loop_outer:
    ldy #0
    lda selection_active
    beq @cell_loop_inner
    lda xf_state
    cmp #XF_STATE_PATTERN_EDITOR
    bne @cell_loop_inner

    lda xf_tmp2 ; current row

    cmp selection_top_y
    bcc @selection_off

    cmp selection_bottom_y
    beq :+
        bcs @selection_off
    :

    lda tmp3
    cmp selection_left_x
    bcc @selection_off

    cmp selection_right_x
    beq :+
        bcs @selection_off
    :

    lda #(XF_SELECTION_BG_COLOR)
    sta tmp2
    bra @cell_loop_inner

@selection_off:
    lda tmp1
    sta tmp2
@cell_loop_inner:
    lda notechardata,x
    sta Vera::Reg::Data0
    lda column_fg_color,y
    ora tmp2
    sta Vera::Reg::Data0
    inx
    iny
    cpy #9
    bcc @cell_loop_inner

    inc tmp3
    cpx #NUM_CHANNELS*9
    bcc @cell_loop_outer

    ; restore color into the y register
    ldy tmp1

    lda #CustomChars::GRID_RIGHT
    sta Vera::Reg::Data0
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    sty Vera::Reg::Data0

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
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        dex
        bne :-
    lda #CustomChars::GRID_RIGHT
    sta Vera::Reg::Data0
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    sty Vera::Reg::Data0

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
; bottom of grid


    VERA_SET_ADDR ($2B06+$1B000),2
    ldx #NUM_CHANNELS
    :
        lda #CustomChars::GRID_BOTTOM_LEFT
        sta Vera::Reg::Data0
        lda #CustomChars::GRID_BOTTOM
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        dex
        bne :-
    lda #CustomChars::GRID_BOTTOM_RIGHT
    sta Vera::Reg::Data0



    lda xf_state
    cmp #XF_STATE_PATTERN_EDITOR
    bne @end_cursor


; now put the cursor where it belongs
    lda #(1 | $20) ; high page, stride = 2
    sta $9F22

    lda #23 ; row number
    clc
    adc #$b0
    sta $9F21

    lda x_position
    asl
    asl
    asl
    clc
    adc x_position

    clc
    adc cursor_position
    adc #3
    asl
    inc

    sta $9F20

    lda #(XF_CURSOR_BG_COLOR | XF_BASE_FG_COLOR)
    sta Vera::Reg::Data0

    ldy cursor_position
    bne :+
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
    :

@end_cursor:
    rts

set_lookup_addr: ; takes in .X, .Y for tracker position, affects .A, lookup_addr
    stz lookup_addr
    stz lookup_addr+1
    ; for global_pattern_length > 64 we're doing one bank per multitrack pattern
    ; otherwise we do two patterns per bank
    lda global_pattern_length
    cmp #$41
    bcs @big_patterns
@small_patterns:
    lda channel_to_pattern,x ; which pattern are we loading
    lsr
    ror lookup_addr
    lsr lookup_addr
    bra @add_base_bank
@big_patterns:
    lda channel_to_pattern,x ; which pattern are we loading
@add_base_bank:
    clc
    adc base_bank
    sta x16::Reg::RAMBank
    tya
    clc
    adc lookup_addr
    sta lookup_addr

    ; multiply by 64 (8 channels, 8 bytes per entry)
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    ; column/channel, multiply by 8
    txa
    asl
    asl
    asl
    clc
    adc lookup_addr
    sta lookup_addr
    lda lookup_addr+1
    adc #$A0 ; high ram start page
    sta lookup_addr+1

    rts


note_val:    .byte CustomChars::NOTE_C,CustomChars::NOTE_C,CustomChars::NOTE_D
             .byte CustomChars::NOTE_D,CustomChars::NOTE_E,CustomChars::NOTE_F
             .byte CustomChars::NOTE_F,CustomChars::NOTE_G,CustomChars::NOTE_G
             .byte CustomChars::NOTE_A,CustomChars::NOTE_A,CustomChars::NOTE_B
note_sharp:  .byte "-#-#--#-#-#-"
note_octave: .byte "0123456789"


column_fg_color: .byte XF_BASE_FG_COLOR,XF_BASE_FG_COLOR,XF_BASE_FG_COLOR
                 .byte XF_INST_FG_COLOR,XF_INST_FG_COLOR,XF_VOL_FG_COLOR
                 .byte XF_EFFECT_FG_COLOR,XF_EFFECT_FG_COLOR,XF_EFFECT_FG_COLOR
.endscope
