decrement_y_page:
    jsr selection_start
    lda GridState::y_position
    sec
    sbc #16
    bcs :+
        lda #0
    :
    sta GridState::y_position
    jsr selection_continue
    inc redraw
    rts

decrement_y_steps:
    ldy GridState::step
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
