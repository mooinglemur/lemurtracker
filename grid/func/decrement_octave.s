.proc decrement_octave
    ldy GridState::octave
    bne :+
        bra end
    :
    dec GridState::octave
end:
    inc redraw
    rts
.endproc
