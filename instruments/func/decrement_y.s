decrement_y:
    ldy InstState::y_position
    bne :+
        ldy InstState::max_instrument
        sty InstState::y_position
        bra @end
    :
    dec InstState::y_position
@end:
    inc redraw
    rts
