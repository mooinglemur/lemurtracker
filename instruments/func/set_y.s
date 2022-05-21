.proc set_y
    sta InstState::y_position
    inc redraw
    rts
.endproc
