.proc decrement_cursor
    ldx GridState::cursor_position
    dex
    cpx #2
    bne :+
        dex
        dex
    :
    cpx #9
    bcc end
    jsr decrement_x
    ldx #8
end:
    stx GridState::cursor_position
    inc redraw
    rts
.endproc
