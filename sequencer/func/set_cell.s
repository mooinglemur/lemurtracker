set_cell:
    sta tmp1 ; store updated value
    ldx SeqState::mix
    bne :+
        cmp #$FF ; if we were going to set the value to $FF, we must not be in mix 0
        beq @end
    :

    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_row
    jsr SeqState::set_ram_bank
    ldy GridState::x_position

    lda tmp1
    sta (SeqState::lookup_addr),y
    jsr Undo::mark_checkpoint
@end:
    inc redraw
    rts
