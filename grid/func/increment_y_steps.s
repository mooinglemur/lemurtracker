increment_y_steps:
    ldy GridState::step
    bne @advance_step
    iny
@advance_step:
    phy
    jsr increment_y
    ply
    dey
    bne @advance_step
@end:
    rts
