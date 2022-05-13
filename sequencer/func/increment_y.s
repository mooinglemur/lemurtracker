increment_y:
    jsr selection_start
    ldy SeqState::y_position
    cpy SeqState::max_row
    bcc :+
        stz SeqState::y_position
        bra @end
    :
    inc SeqState::y_position
@end:
    jsr selection_continue
    inc redraw
    rts
