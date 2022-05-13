decrement_x:
    jsr selection_start
decrement_x_without_starting_selection:
    ldy GridState::x_position
    bne :+
        ldy #(GridState::NUM_CHANNELS - 1)
        sty GridState::x_position
        bra @end
    :
    dec GridState::x_position
@end:
    jsr selection_continue
    inc redraw
    rts
