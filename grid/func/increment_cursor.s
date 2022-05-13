.proc increment_cursor
    ldx GridState::cursor_position
    inx
    cpx #1
    bne :+
        inx
        inx
    :
    cpx #9
    bcc :+
        jsr increment_x
        ldx #0
    :
    stx GridState::cursor_position
    inc redraw
    rts
.endproc
