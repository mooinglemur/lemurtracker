.proc increment_step
    ldy GridState::step
    cpy #GridState::MAX_STEP
    bcc :+
        bra end
    :
    inc GridState::step
end:
    inc redraw
    rts
.endproc
