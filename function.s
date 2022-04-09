; function.s - handler for changing the state of the tracker
; predominantly originating through keystrokes, but also mouse actions
; and perhaps other inputs in the future

.scope Function

play_note:
    rts

decrement_grid_cursor:
    ldx Grid::cursor_position
    dex
    cpx #1
    bne :+
        dex
    :
    cpx #8
    bcc :+
    ldx #7
    dec Grid::x_position
    ldy Grid::x_position
    cpy #8
    bcc :+
        stx Grid::x_position
    :
    stx Grid::cursor_position
@end:
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
    rts

decrement_grid_y:
    ldy Grid::y_position
    bne :+
        ldy Grid::global_frame_length
        sty Grid::y_position
        bra @exit
    :
    dec Grid::y_position
@exit:
    rts




increment_grid_cursor:
    ldx Grid::cursor_position
    inx
    cpx #1
    bne :+
        inx
    :
    cpx #8
    bcc :+
    ldx #0
    inc Grid::x_position
    ldy Grid::x_position
    cpy #8
    bcc :+
        stz Grid::x_position
    :
    stx Grid::cursor_position

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
    rts


increment_grid_y:
    ldy Grid::y_position
    cpy Grid::global_frame_length
    bcc :+
        stz Grid::y_position
        bra @exit
    :
    inc Grid::y_position
@exit:
    rts


mass_decrement_grid_y:
    lda Grid::y_position
    sec
    sbc #8
    bcs :+
        lda #0
    :
    sta Grid::y_position
    rts

mass_increment_grid_y:
    lda Grid::y_position
    clc
    adc #8
    bcs @clamp

    cmp Grid::global_frame_length
    bcc @end

@clamp:
    lda Grid::global_frame_length
@end:
    sta Grid::y_position
    rts


set_grid_y:
    sta Grid::y_position
    rts




.endscope
