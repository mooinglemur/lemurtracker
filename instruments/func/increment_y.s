increment_y:
    ldy InstState::y_position
    cpy InstState::max_instrument
    bcc :+
        stz InstState::y_position
        bra @end
    :
    inc InstState::y_position
@end:
    inc redraw
    rts
