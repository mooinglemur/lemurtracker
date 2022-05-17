.proc increment_y_steps_noselect
    ldy GridState::step
    beq end
advance_step:
    phy
    jsr increment_y_without_starting_selection
    ply
    dey
    bne advance_step
end:
    rts
.endproc
