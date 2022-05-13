.proc increment_octave
    ldy GridState::octave
    cpy #GridState::MAX_OCTAVE
    bcc :+
        bra end
    :
    inc GridState::octave
end:
    inc redraw
    rts
.endproc
