.proc set_y
    pha
    jsr selection_start
    pla
    sta GridState::y_position
    jsr selection_continue
    inc redraw
    rts
.endproc
