set_y:
    pha
    jsr selection_start
    pla
    sta SeqState::y_position
    jsr selection_continue
    inc redraw
    rts
