.proc decrement_step
    ldy GridState::step
    bne :+
        bra end
    :
    dec GridState::step
end:
    inc redraw
    rts
.endproc
