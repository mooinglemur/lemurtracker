; function.s - handler for changing the state of the tracker
; predominantly originating through keystrokes, but also mouse actions
; and perhaps other inputs in the future

.scope Function

note_entry_dispatch_value: .byte $ff

decrement_grid_cursor:
    ldx Grid::cursor_position
    dex
    cpx #2
    bne :+
        dex
        dex
    :
    cpx #9
    bcc @end
    dec Grid::x_position
    ldy Grid::x_position
    cpy #Grid::NUM_CHANNELS
    bcc :+
        ldy #(Grid::NUM_CHANNELS-1)
        sty Grid::x_position
    :
    ldx #8
@end:
    stx Grid::cursor_position
    inc redraw
    rts

decrement_grid_octave:
    ldy Grid::octave
    bne :+
        bra @exit
    :
    dec Grid::octave
@exit:
    inc redraw
    rts

decrement_grid_step:
    ldy Grid::step
    bne :+
        bra @exit
    :
    dec Grid::step
@exit:
    inc redraw
    rts




decrement_grid_x:
    ldy Grid::x_position
    bne :+
        ldy #(Grid::NUM_CHANNELS - 1)
        sty Grid::x_position
        bra @exit
    :
    dec Grid::x_position
@exit:
    inc redraw
    rts

decrement_grid_y:
    ldy Grid::y_position
    bne :+
        ldy Grid::global_frame_length
        sty Grid::y_position
        jsr decrement_sequencer_y
        bra @exit
    :
    dec Grid::y_position
@exit:
    inc redraw
    rts


decrement_sequencer_y:
    ldy Sequencer::y_position
    bne :+
        ldy Sequencer::max_frame
        sty Sequencer::y_position
        bra @exit
    :
    dec Sequencer::y_position
@exit:
    inc redraw
    rts


dispatch_note_entry: ; make note entry happen outside of IRQ
    ; .A = notecode, we need convert to note value (MIDI number)
    cmp #$ff ; note delete
    beq @note_delete
    cmp #$fe ; note cut
    beq @note_cut
    cmp #$fd ; note release
    beq @note_release

    dec
    sta note_entry_dispatch_value
    ; note stored is 0 for C0, we need to add the octave+1 so that 12 is C0
    clc
    lda #0
    ldy Grid::octave
    iny
@octave_loop:
    adc #12
    dey
    bne @octave_loop
    adc note_entry_dispatch_value
    bra @end
@note_delete:
    lda #0
    bra @end
@note_cut:
    lda #1
    bra @end
@note_release:
    lda #2
@end:
    cmp #$80 ; clamp to 0-127 here
    bcc :+
        lda #0
    :
    sta note_entry_dispatch_value
    rts


increment_grid_cursor:
    ldx Grid::cursor_position
    inx
    cpx #1
    bne :+
        inx
        inx
    :
    cpx #9
    bcc :+
    ldx #0
    inc Grid::x_position
    ldy Grid::x_position
    cpy #Grid::NUM_CHANNELS
    bcc :+
        stz Grid::x_position
    :
    stx Grid::cursor_position

    inc redraw
    rts

increment_grid_x:
    ldy Grid::x_position
    cpy #(Grid::NUM_CHANNELS - 1)
    bcc :+
        stz Grid::x_position
        bra @exit
    :
    inc Grid::x_position
@exit:
    inc redraw
    rts

increment_grid_octave:
    ldy Grid::octave
    cpy #Grid::MAX_OCTAVE
    bcc :+
        bra @exit
    :
    inc Grid::octave
@exit:
    inc redraw
    rts

increment_grid_step:
    ldy Grid::step
    cpy #Grid::MAX_STEP
    bcc :+
        bra @exit
    :
    inc Grid::step
@exit:
    inc redraw
    rts



increment_grid_y:
    ldy Grid::y_position
    cpy Grid::global_frame_length
    bcc :+
        stz Grid::y_position
        jsr increment_sequencer_y
        bra @exit
    :
    inc Grid::y_position
@exit:
    inc redraw
    rts

increment_sequencer_y:
    ldy Sequencer::y_position
    cpy Sequencer::max_frame
    bcc :+
        stz Sequencer::y_position
        bra @exit
    :
    inc Sequencer::y_position
@exit:
    inc redraw
    rts

mass_decrement_grid_y:
    lda Grid::y_position
    sec
    sbc #16
    bcs :+
        lda #0
    :
    sta Grid::y_position
    inc redraw
    rts

mass_decrement_sequencer_y:
    lda Sequencer::y_position
    sec
    sbc #4
    bcs :+
        lda #0
    :
    sta Sequencer::y_position
    inc redraw
    rts

mass_increment_grid_y:
    lda Grid::y_position
    clc
    adc #16
    bcs @clamp

    cmp Grid::global_frame_length
    bcc @end

@clamp:
    lda Grid::global_frame_length
@end:
    sta Grid::y_position
    inc redraw
    rts

mass_increment_sequencer_y:
    lda Sequencer::y_position
    clc
    adc #4
    bcs @clamp

    cmp Sequencer::max_frame
    bcc @end

@clamp:
    lda Sequencer::max_frame
@end:
    sta Sequencer::y_position
    inc redraw
    rts


note_entry:
    ldx Grid::x_position
    ldy Grid::y_position
    jsr Grid::set_lookup_addr ; set the grid lookup_addr value to the beginning
                              ; of the note data for the current row/column
                              ; this affects RAM bank as well
    lda note_entry_dispatch_value
    sta (Grid::lookup_addr) ; zero offset, this is the note column
    pha

    ldy #1
    lda Instruments::y_position ; currently selected instrument
    sta (Grid::lookup_addr),y ; #1 offset, this is the instrument number
    tay
    lda #$ff
    sta note_entry_dispatch_value

    pla
    ldx Grid::x_position
    jsr play_note ; .A = note, .X = column, .Y = instrument

    inc redraw

    ldy Grid::step
    beq @end
@advance_step:
    phy
    jsr increment_grid_y
    ply
    dey
    bne @advance_step
@end:
    rts


play_note: ;.A = note, .X = column, .Y = instrument
    rts


set_grid_y:
    sta Grid::y_position
    inc redraw
    rts

set_sequencer_y:
    sta Sequencer::y_position
    inc redraw
    rts



.endscope
