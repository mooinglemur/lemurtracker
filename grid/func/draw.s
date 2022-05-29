
.proc draw ; affects A,X,Y,zp_tmp1,zp_tmp2,zp_tmp3
    ; Application Title
    VERA_SET_ADDR ($003C+$1B000),2
    ldx #0
    :
        lda title_text,x
        beq :+
        sta Vera::Reg::Data0
        inx
        bra :-
    :

    ; Git version
    VERA_SET_ADDR ($0146+$1B000),2
    ldx #0
    :
        lda githash,x
        beq :+
        sta Vera::Reg::Data0
        inx
        bra :-
    :

    ; Grid Header
    VERA_SET_ADDR ($0106+$1B000),2

    ldx #0
    :
        lda header_text,x
        beq :+
        sta Vera::Reg::Data0
        inx
        bra :-
    :

    ; Top of grid
    VERA_SET_ADDR ($0206+$1B000),2

    ldx #GridState::NUM_CHANNELS
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
    sta zp_tmp1
    lda GridState::y_position
    sta GridState::tmp_y_position
    sec
    sbc #20
    sta zp_tmp2
    stz zp_tmp3

rowstart:
    lda #(1 | $10) ; high bank, stride = 1
    sta $9F22

    lda zp_tmp1 ; row number
    clc
    adc #$b0
    sta $9F21

    lda #2 ; one character over
    sta $9F20

    lda zp_tmp3
    beq :+
        jmp blankrow
    :

    lda zp_tmp2
    ldy zp_tmp1
    cpy #23
    bcs :++
        cmp GridState::tmp_y_position
        bcc :+
            jmp blankrow
        :
        bra filledrow
    :

    ldy zp_tmp2
    iny
    cpy GridState::global_pattern_length
    bcc :+
        inc zp_tmp3
    :
    cmp GridState::tmp_y_position
    bcs filledrow

filledrow:
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    cmp GridState::tmp_y_position ; comparing .A which is the current row being drawn
    bne :+
        ldy #((XF_BASE_BG_COLOR>>4)|(XF_BASE_FG_COLOR<<4)) ; invert
    :
    jsr Util::byte_to_hex

    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    ; fetch note data from hiram. we can clobber registers here
    stz iterator

fetch_notedata_loop:
    ldx iterator
    ldy zp_tmp2 ; the row we're drawing
    jsr GridState::set_lookup_addr

    txa
    asl
    asl
    asl
    clc
    adc iterator
    tax

    ldy #0
    lda (GridState::lookup_addr),y
    ; note
    bne check_for_special_note

    lda #CustomChars::NOTE_DOT
    sta GridState::notechardata,x
    lda #'.'
    sta GridState::notechardata+1,x
    sta GridState::notechardata+2,x
    sta GridState::notechardata+3,x
    sta GridState::notechardata+4,x
    jmp get_volume
check_for_special_note:
    cmp #1
    beq note_cut
    cmp #2
    beq note_release
    bra note_exists
note_cut:
    lda #CustomChars::NOTE_CUT_LEFT
    sta GridState::notechardata,x
    lda #CustomChars::NOTE_CUT_MIDDLE
    sta GridState::notechardata+1,x
    lda #CustomChars::NOTE_CUT_RIGHT
    sta GridState::notechardata+2,x
    lda #'.'
    sta GridState::notechardata+3,x
    sta GridState::notechardata+4,x
    bra get_volume
note_release:
    lda #CustomChars::NOTE_REL_LEFT
    sta GridState::notechardata,x
    lda #CustomChars::NOTE_REL_MIDDLE
    sta GridState::notechardata+1,x
    lda #CustomChars::NOTE_REL_RIGHT
    sta GridState::notechardata+2,x
    lda #'.'
    sta GridState::notechardata+3,x
    sta GridState::notechardata+4,x
    bra get_volume

note_exists:
    ldy #0
    sec

note_and_octave_loop: ; after this loop, A will contain the note and Y will contain the octave
    cmp #24
    bcc found_octave
    iny
    sbc #12
    bra note_and_octave_loop

found_octave:
    phy
    sec
    sbc #12
    tay
    lda GridState::note_val,y
    sta GridState::notechardata,x
    lda GridState::note_sharp,y
    sta GridState::notechardata+1,x
    ply
    lda GridState::note_octave,y
    sta GridState::notechardata+2,x

get_instrument_number:
    ldy #1
    lda (GridState::lookup_addr),y
    phx
    jsr Util::byte_to_hex
    ply
    phx
    phy
    plx
    sta GridState::notechardata+3,x
    pla
    sta GridState::notechardata+4,x

get_volume: ; byte should be 1-16 and displayed value should be shifted down one
    lda #'.'
    sta GridState::notechardata+5,x
    ldy #2
    lda (GridState::lookup_addr),y
    beq :+
        phx
        dec
        jsr Util::byte_to_hex
        txa
        plx
        sta GridState::notechardata+5,x
    :

get_effect:
    ldy #3
    lda (GridState::lookup_addr),y
    bne :+
        lda #'.'
        sta GridState::notechardata+6,x
        sta GridState::notechardata+7,x
        sta GridState::notechardata+8,x
        bra end_column
    :
    sta GridState::notechardata+6,x

get_effect_arg:
    ldy #4
    lda (GridState::lookup_addr),y
    phx
    jsr Util::byte_to_hex
    ply
    phx
    phy
    plx
    sta GridState::notechardata+7,x
    pla
    sta GridState::notechardata+8,x

end_column:
    inc iterator
    lda iterator
    cmp #GridState::NUM_CHANNELS
    bcs :+
        jmp fetch_notedata_loop
    :

    ldy #XF_BASE_BG_COLOR

    ; color current row
    lda zp_tmp2
    cmp GridState::tmp_y_position
    bne not_current_row
        lda xf_state
        cmp #XF_STATE_GRID
        bne not_current_row ; If we're not editing the pattern, don't hilight the current row
        ldy #XF_AUDITION_BG_COLOR
        lda GridState::entrymode
        beq :+
            ldy #XF_NOTE_ENTRY_BG_COLOR
        :

        bra got_color

not_current_row:

long_hilight:
    ; color every 16 (or whatever) rows
    lda zp_tmp2
    sec

long_hilight_loop:
    beq do_long_hilight
    sbc GridState::long_hilight_interval
    bcc short_hilight
    bra long_hilight_loop

do_long_hilight:
    ldy #XF_HILIGHT_BG_COLOR_2
    bra got_color

short_hilight:
    ; color every 4 (or whatever) rows
    lda zp_tmp2
    sec

short_hilight_loop:
    beq do_short_hilight
    sbc GridState::short_hilight_interval
    bcc no_hilight
    bra short_hilight_loop

do_short_hilight:
    ldy #XF_HILIGHT_BG_COLOR_1
    bra got_color

no_hilight:
got_color:
    sty tmp1 ; store background color here temp
    sty tmp2 ; store it here too, but switch this one to the selection color if appropriate
    ldx #0
    stz tmp3 ; channel column
cell_loop_outer:
    ldy #0
    lda GridState::selection_active
    beq cell_loop_inner
    lda xf_state
    cmp #XF_STATE_GRID
    bne cell_loop_inner

    lda zp_tmp2 ; current row

    cmp GridState::selection_top_y
    bcc selection_off

    cmp GridState::selection_bottom_y
    beq :+
        bcs selection_off
    :

    lda tmp3
    cmp GridState::selection_left_x
    bcc selection_off

    cmp GridState::selection_right_x
    beq :+
        bcs selection_off
    :

    lda #(XF_SELECTION_BG_COLOR)
    sta tmp2
    bra cell_loop_inner

selection_off:
    lda tmp1
    sta tmp2

cell_loop_inner:
    lda GridState::notechardata,x
    sta Vera::Reg::Data0

    phy
    ldy tmp3
    lda GridState::channel_is_muted,y
    ply
    cmp #0
    bne muted

    phy
    ldy tmp3
    lda GridState::channel_is_inherited,y
    ply
    cmp #0
    bne inherited

    lda GridState::column_fg_color,y
    bra after_inherit_check

muted:
    lda GridState::column_fg_color_muted,y
    bra after_mute_check

inherited:
    lda GridState::column_fg_color_mix,y

after_inherit_check:
    ora tmp2
after_mute_check:
    sta Vera::Reg::Data0
    inx
    iny
    cpy #9
    bcc cell_loop_inner

    inc tmp3
    cpx #GridState::NUM_CHANNELS*9
    bcc cell_loop_outer

    ; restore color into the y register
    ldy tmp1

    lda #CustomChars::GRID_RIGHT
    sta Vera::Reg::Data0
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    sty Vera::Reg::Data0

    bra endofrow

blankrow:
    lda #$20
    ldy #%00000001 ; color value for blank row is 0 bg, 1 fg
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    ldx #GridState::NUM_CHANNELS
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

endofrow:
    lda zp_tmp3
    bne :+
        inc zp_tmp2


    :
    inc zp_tmp1
    lda zp_tmp1
    cmp #43
    bcs :+
        jmp rowstart
    :
; bottom of grid


    VERA_SET_ADDR ($2B06+$1B000),2
    ldx #GridState::NUM_CHANNELS
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
    cmp #XF_STATE_GRID
    bne end_cursor


; now put the cursor where it belongs
    lda #(1 | $20) ; high page, stride = 2
    sta $9F22

    lda #23 ; row number
    clc
    adc #$b0
    sta $9F21

    lda GridState::x_position
    asl
    asl
    asl
    clc
    adc GridState::x_position

    clc
    adc GridState::cursor_position
    adc #3
    asl
    inc

    sta $9F20

    lda #(XF_CURSOR_BG_COLOR | XF_BASE_FG_COLOR)
    sta Vera::Reg::Data0

    ldy GridState::cursor_position
    bne :+
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
    :
end_cursor:
    rts
.endproc

title_text: .asciiz "LemurTracker v0.0"
header_text: .asciiz "Pattern [F1]"
