.proc increment_y_steps_strict
    ldy GridState::step
    bne increment_y_steps
    rts
.endproc
