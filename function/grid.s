.scope Grid

backspace:
    lda ::Grid::cursor_position
    beq @note_column
    cmp #4
    beq @move_left
    cmp #7
    bcs @move_left
    bra @end
@move_left:
    jmp decrement_cursor
@note_column:
    jmp delete_cell_above
@end:
    rts

decrement_cursor:
    ldx ::Grid::cursor_position
    dex
    cpx #2
    bne :+
        dex
        dex
    :
    cpx #9
    bcc @end
    jsr decrement_x
    ldx #8
@end:
    stx ::Grid::cursor_position
    inc redraw
    rts

decrement_octave:
    ldy ::Grid::octave
    bne :+
        bra @end
    :
    dec ::Grid::octave
@end:
    inc redraw
    rts

decrement_step:
    ldy ::Grid::step
    bne :+
        bra @end
    :
    dec ::Grid::step
@end:
    inc redraw
    rts


decrement_x:
    jsr selection_start
decrement_x_without_starting_selection:
    ldy ::Grid::x_position
    bne :+
        ldy #(::Grid::NUM_CHANNELS - 1)
        sty ::Grid::x_position
        bra @end
    :
    dec ::Grid::x_position
@end:
    jsr selection_continue
    inc redraw
    rts


decrement_y:
    jsr selection_start
    ldy ::Grid::y_position
    bne :+
        ldy ::Grid::global_pattern_length
        dey
        sty ::Grid::y_position
        jsr decrement_sequencer_y
        bra @end
    :
    dec ::Grid::y_position
@end:
    jsr selection_continue
    inc redraw
    rts

decrement_y_page:
    jsr selection_start
    lda ::Grid::y_position
    sec
    sbc #16
    bcs :+
        lda #0
    :
    sta ::Grid::y_position
    jsr selection_continue
    inc redraw
    rts

decrement_y_steps:
    ldy ::Grid::step
    bne @advance_step
    iny
@advance_step:
    phy
    jsr decrement_y
    ply
    dey
    bne @advance_step
@end:
    rts


delete_cell_above:
    ; if we're at the top of the grid, we do nothing
    ldy ::Grid::y_position
    beq @end
    dey
    sty tmp1
    ; we need to shift everything up in this column from cursor position down
    ; to the end of the pattern
@loop:
    ldy tmp1
    ldx ::Grid::x_position
    jsr ::Grid::set_lookup_addr

    iny
    cpy ::Grid::global_pattern_length
    dey
    bcs @empty_cell
@copy_cell:
    lda x16::Reg::RAMBank
    pha
    jsr Undo::store_grid_cell
    pla
    sta x16::Reg::RAMBank

    ldy #0
    :
        phy

        tya
        clc
        adc #(8*::Grid::NUM_CHANNELS)
        tay
        lda (::Grid::lookup_addr),y
        ply
        sta (::Grid::lookup_addr),y

        iny
        cpy #8
        bcc :-

    inc tmp1
    bra @loop
@empty_cell:
    lda x16::Reg::RAMBank
    pha

    jsr Undo::store_grid_cell
    jsr Undo::mark_checkpoint

    pla
    sta x16::Reg::RAMBank


    lda #0
    ldy #0
    :
        sta (::Grid::lookup_addr),y
        iny
        cpy #8
        bcc :-
@finalize:
    jsr decrement_y
@end:
    rts

delete_selection:
    ; tmp1 = x, tmp2 = y
    lda ::Grid::selection_active
    beq @end

    ldx ::Grid::selection_left_x
    stx tmp1
    ldy ::Grid::selection_top_y
    sty tmp2
@loop:
    ldx tmp1
    ldy tmp2
    jsr Undo::store_grid_cell
    ldx tmp1
    ldy tmp2
    jsr ::Grid::set_lookup_addr
    lda #0
    ldy #0
    :
        sta (::Grid::lookup_addr),y
        iny
        cpy #8
        bcc :-
    ; advance x
    inc tmp1
    lda tmp1
    cmp ::Grid::selection_right_x
    beq @loop
    bcc @loop

    ; reset x and advance y
    lda ::Grid::selection_left_x
    sta tmp1

    inc tmp2
    lda tmp2
    cmp ::Grid::selection_bottom_y
    beq @loop
    bcc @loop

    jsr Undo::mark_checkpoint
    inc redraw
@end:
    rts

get_first_unused_patterns:
    jsr Sequencer::set_ram_bank
    stz Sequencer::lookup_addr
    lda #$A0
    sta Sequencer::lookup_addr+1

    ; zero out tmp8b
    lda #0
    ldy #0
    :
        sta tmp8b,y
        iny
        cpy #8
        bcc :-
@mainloop:
    ldy #0
@rowloop:
    lda (Sequencer::lookup_addr),y
    cmp #$ff
    beq @next
    cmp tmp8b,y
    bcc @next
    cmp Sequencer::max_pattern
    bcc :+
        lda Sequencer::max_pattern
        dec
    :
    sta tmp8b,y
@next:
    iny
    cpy #8
    bcc @rowloop
    lda Sequencer::lookup_addr
    clc
    adc #8
    sta Sequencer::lookup_addr
    lda Sequencer::lookup_addr+1
    adc #0
    cmp #$C0
    bcs @end
    sta Sequencer::lookup_addr+1
    bra @mainloop
@end:
    rts

entry:
    sta tmp1

    stz ::Grid::selection_active

    ldx ::Grid::x_position
    ldy ::Grid::y_position
    jsr ::Grid::set_lookup_addr

    lda ::Grid::cursor_position
    cmp #3
    beq @insth
    cmp #4
    beq @instl
    cmp #5
    bne :+
        jmp @vol
    :
    cmp #6
    bne :+
        jmp @eff
    :
    cmp #7
    bne :+
        jmp @effh
    :
    jmp @effl
@end:
    inc redraw
    rts
@savecell:
    pha
    ldx ::Grid::x_position
    ldy ::Grid::y_position
    jsr Undo::store_grid_cell
    jsr Undo::mark_checkpoint

    ldx ::Grid::x_position
    ldy ::Grid::y_position
    jsr ::Grid::set_lookup_addr

    pla
    rts
@insth: ; changing the instrument high nybble
    lda (::Grid::lookup_addr)
    beq @end
    lda tmp1
    jsr @key_to_hexh
    cmp #$ff
    beq @end
    jsr @savecell
    sta tmp2
    ldy #1
    lda (::Grid::lookup_addr),y
    and #$0f
    ora tmp2
    cmp #$ff ; max instrument is fe
    bne :+
        dec
    :
    sta (::Grid::lookup_addr),y
    sta Instruments::y_position
    jsr increment_cursor
    bra @end
@instl: ; changing the instrument low nybble
    lda (::Grid::lookup_addr)
    beq @end
    lda tmp1
    jsr @key_to_hex
    cmp #$ff
    beq @end
    jsr @savecell
    sta tmp2
    ldy #1
    lda (::Grid::lookup_addr),y
    and #$f0
    ora tmp2
    cmp #$ff ; max instrument is fe
    bne :+
        dec
    :
    sta (::Grid::lookup_addr),y
    sta Instruments::y_position
    jsr increment_y_steps_strict
    jsr decrement_cursor
    bra @end
@vol: ; changing the volume
    lda tmp1
    jsr @key_to_vol
    cmp #$ff
    bne :+
        jmp @end
    :
    jsr @savecell
    ldy #2
    sta (::Grid::lookup_addr),y
    jsr increment_y_steps_strict
    jmp @end
@eff: ; changing the effect opcode
    lda tmp1
    jsr @key_to_eff
    cmp #$ff
    bne :+
        jmp @end
    :
    jsr @savecell
    ldy #3
    sta (::Grid::lookup_addr),y
    cmp #0
    bne :+
        iny
        sta (::Grid::lookup_addr),y
        iny
        sta (::Grid::lookup_addr),y
        jsr increment_y_steps_strict
        jmp @end
    :
    jsr increment_cursor
    jmp @end
@effh: ; changing the effect high nybble
    ldy #3 ; don't allow entry unless an effect opcode exists
    lda (::Grid::lookup_addr),y
    bne :+
        jmp @end
    :

    lda tmp1
    cmp #$89
    bne :+
        jsr decrement_cursor
        lda #$89
        jmp @eff
    :
    jsr @key_to_hexh
    cmp #$ff
    bne :+
        jmp @end
    :
    jsr @savecell
    sta tmp2
    ldy #4
    lda (::Grid::lookup_addr),y
    and #$0f
    ora tmp2
    sta (::Grid::lookup_addr),y
    jsr increment_cursor
    jmp @end
@effl: ; changing the effect low nybble
    ldy #3 ; don't allow entry unless an effect opcode exists
    lda (::Grid::lookup_addr),y
    bne :+
        jmp @end
    :


    lda tmp1
    cmp #$89
    bne :+
        jsr decrement_cursor
        jsr decrement_cursor
        lda #$89
        jmp @eff
    :
    jsr @key_to_hex
    cmp #$ff
    bne :+
        jmp @end
    :
    jsr @savecell
    sta tmp2
    ldy #4
    lda (::Grid::lookup_addr),y
    and #$f0
    ora tmp2
    sta (::Grid::lookup_addr),y
    jsr increment_y_steps_strict
    jsr decrement_cursor
    jsr decrement_cursor
    jmp @end
@key_to_hexh:
    cmp #$30
    bcc @returnff
    cmp #$3A
    bcc @kthhnum
    cmp #$41
    bcc @returnff
    cmp #$47
    bcs @returnff
    sec
    sbc #$07
@kthhnum:
    sec
    sbc #$30
    asl
    asl
    asl
    asl
    rts
@returnff:
    lda #$ff
    rts
@key_to_hex:
    cmp #$30
    bcc @returnff
    cmp #$3A
    bcc @kthnum
    cmp #$41
    bcc @returnff
    cmp #$47
    bcs @returnff
    sec
    sbc #$07
@kthnum:
    sec
    sbc #$30
    rts
@return0:
    lda #0
    rts
@key_to_vol: ; returns n+1 or 0 for delete
    cmp #$89
    beq @return0
    cmp #$30
    bcc @returnff
    cmp #$3A
    bcc @ktvnum
    cmp #$41
    bcc @returnff
    cmp #$47
    bcs @returnff
    sec
    sbc #$07
@ktvnum:
    sec
    sbc #$2F
    rts
@key_to_eff:
    cmp #$89
    beq @return0
    cmp #$30
    beq @return0 ; 0 = empty effect
    bcc @returnff
    cmp #$3A
    bcc @return
    cmp #$41
    bcc @returnff
    cmp #$5B
    bcs @returnff
@return:
    rts

increment_cursor:
    ldx ::Grid::cursor_position
    inx
    cpx #1
    bne :+
        inx
        inx
    :
    cpx #9
    bcc :+
        jsr increment_x
        ldx #0
    :
    stx ::Grid::cursor_position
    inc redraw
    rts


increment_step:
    ldy ::Grid::step
    cpy #::Grid::MAX_STEP
    bcc :+
        bra @end
    :
    inc ::Grid::step
@end:
    inc redraw
    rts


increment_x:
    jsr selection_start
    ldy ::Grid::x_position
    cpy #(::Grid::NUM_CHANNELS - 1)
    bcc :+
        stz ::Grid::x_position
        bra @end
    :
    inc ::Grid::x_position
@end:
    jsr selection_continue
    inc redraw
    rts

increment_octave:
    ldy ::Grid::octave
    cpy #::Grid::MAX_OCTAVE
    bcc :+
        bra @end
    :
    inc ::Grid::octave
@end:
    inc redraw
    rts



increment_y:
    jsr selection_start
    inc ::Grid::y_position
    ldy ::Grid::y_position
    cpy ::Grid::global_pattern_length
    bcc :+
        stz ::Grid::y_position
        jsr increment_sequencer_y
        bra @end
    :
@end:
    jsr selection_continue
    inc redraw
    rts

increment_y_page:
    jsr selection_start
    lda ::Grid::y_position
    clc
    adc #16
    bcs @clamp

    cmp ::Grid::global_pattern_length
    bcc @end

@clamp:
    lda ::Grid::global_pattern_length
    dec
@end:
    sta ::Grid::y_position
    jsr selection_continue
    inc redraw
    rts


increment_y_steps:
    ldy ::Grid::step
    bne @advance_step
    iny
@advance_step:
    phy
    jsr increment_y
    ply
    dey
    bne @advance_step
@end:
    rts

increment_y_steps_strict:
    ldy ::Grid::step
    bne increment_y_steps
    rts

note_entry:
    pha
    ; first put the old value on the undo stack
    ldx ::Grid::x_position
    ldy ::Grid::y_position
    jsr Undo::store_grid_cell
    jsr Undo::mark_checkpoint

    ; now actually apply the note
    ldx ::Grid::x_position
    ldy ::Grid::y_position

    jsr ::Grid::set_lookup_addr ; set the grid lookup_addr value to the beginning
                              ; of the note data for the current row/column
                              ; this affects RAM bank as well
    pla
    sta (::Grid::lookup_addr) ; zero offset, this is the note column
    pha

    ldy #1
    lda Instruments::y_position ; currently selected instrument
    sta (::Grid::lookup_addr),y ; #1 offset, this is the instrument number
    tay

    pla
    ldx ::Grid::x_position
    jsr play_note ; .A = note, .X = column, .Y = instrument

    inc redraw

    ldy ::Grid::step
    beq @end
@advance_step:
    phy
    jsr increment_y
    ply
    dey
    bne @advance_step
@end:
    rts

select_all:
    lda #2
    sta ::Grid::selection_active
    lda ::Grid::global_pattern_length
    dec
    sta ::Grid::selection_bottom_y
    lda #(::Grid::NUM_CHANNELS-1)
    sta ::Grid::selection_right_x
    stz ::Grid::selection_left_x
    stz ::Grid::selection_top_y
    inc redraw
    rts

select_none:
    stz ::Grid::selection_active
    inc redraw
    rts

selection_start:
    lda xf_state
    cmp #XF_STATE_GRID
    bne @end

    lda GKeyboard::modkeys
    and #(GKeyboard::MOD_LSHIFT|GKeyboard::MOD_RSHIFT)
    beq @end

    lda ::Grid::selection_active
    bne :+
        lda ::Grid::x_position
        sta ::Grid::selection_left_x
        sta ::Grid::selection_right_x
        lda ::Grid::y_position
        sta ::Grid::selection_top_y
        sta ::Grid::selection_bottom_y
        lda #1
        sta ::Grid::selection_active
        bra @end
    :
    and #3
    cmp #2
    bne :+
        stz ::Grid::selection_active
        jmp selection_start ; starting a new selection
    :
@end:
    rts




selection_continue:
    lda xf_state
    cmp #XF_STATE_GRID
    beq :+
        jmp @end
    :

    lda GKeyboard::modkeys
    and #(GKeyboard::MOD_LSHIFT|GKeyboard::MOD_RSHIFT)
    bne :+
        jmp @noshift
    :
    ; bail out if we aren't continuing a selection
    lda ::Grid::selection_active
    and #1
    bne :+
        jmp @noshift
    :

@check_y_extended:
    lda ::Grid::selection_bottom_y
    cmp ::Grid::selection_top_y
    bne @y_extended
    ; y is not extended yet
    cmp ::Grid::y_position
    beq @check_x_extended ; y is unextended, but we're not extendeding it

    ; now we're going to determine our y extend direction here because
    ; y is about to be extended this frame
    bcc @extend_down ; selection top (and bottom) is less than new y pos,
                     ; so we extend down.
                     ; y increasing means selection is extending downward
@extend_up:
    smb2 ::Grid::selection_active
    bra @y_extended
@extend_down:
    rmb2 ::Grid::selection_active
@y_extended:
    bbr2 ::Grid::selection_active,@new_bottom
@new_top:
    lda ::Grid::y_position
    sta ::Grid::selection_top_y
    bra @check_x_extended
@new_bottom:
    lda ::Grid::y_position
    sta ::Grid::selection_bottom_y

@check_x_extended:
    lda ::Grid::selection_right_x
    cmp ::Grid::selection_left_x
    bne @x_extended
    ; x is not extended yet
    cmp ::Grid::x_position
    beq @check_y_inverted ; x is unextended, but we're not extendeding it

    ; now we're going to determine our x extend direction here because
    ; x is about to be extended this frame
    bcc @extend_right ; selection left (and right) is less than new x pos,
                     ; so we extend right.
                     ; x increasing means selection is extending rightward

@extend_left:
    smb3 ::Grid::selection_active
    bra @x_extended
@extend_right:
    rmb3 ::Grid::selection_active
@x_extended:
    bbr3 ::Grid::selection_active,@new_right
@new_left:
    lda ::Grid::x_position
    sta ::Grid::selection_left_x
    bra @check_y_inverted
@new_right:
    lda ::Grid::x_position
    sta ::Grid::selection_right_x

@check_y_inverted:
    lda ::Grid::selection_bottom_y
    cmp ::Grid::selection_top_y
    bcs @y_not_inverted
    ; y top and bottom switched places here
    pha
    lda ::Grid::selection_top_y
    sta ::Grid::selection_bottom_y
    pla
    sta ::Grid::selection_top_y
    lda ::Grid::selection_active
    eor #%00000100 ; flip the y estend direction bit
    sta ::Grid::selection_active
@y_not_inverted:

@check_x_inverted:
    lda ::Grid::selection_right_x
    cmp ::Grid::selection_left_x
    bcs @x_not_inverted
    ; x left and right switched places here
    pha
    lda ::Grid::selection_left_x
    sta ::Grid::selection_right_x
    pla
    sta ::Grid::selection_left_x
    lda ::Grid::selection_active
    eor #%00001000 ; flip the x estend direction bit
    sta ::Grid::selection_active
@x_not_inverted:

    bra @end
@noshift:
    lda ::Grid::selection_active
    and #3
    cmp #1
    bne @end
    lda #2
    sta ::Grid::selection_active
@end:
    rts


set_y:
    pha
    jsr selection_start
    pla
    sta ::Grid::y_position
    jsr selection_continue
    inc redraw
    rts

.endscope
