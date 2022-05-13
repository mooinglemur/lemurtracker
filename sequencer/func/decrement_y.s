decrement_y:
    jsr selection_start
    ldy SeqState::y_position
    bne :+
        ldy SeqState::max_row
        sty SeqState::y_position
        bra @end
    :
    dec SeqState::y_position
@end:
    jsr selection_continue
    inc redraw
    rts
