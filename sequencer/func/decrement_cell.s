decrement_cell:
    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_row
    jsr Undo::mark_checkpoint

    ldy SeqState::y_position
    jsr SeqState::set_lookup_addr


    ldy GridState::x_position
    lda (SeqState::lookup_addr),y
    beq @end
    cmp #$FF
    bne :+
        lda (SeqState::mix0_lookup_addr),y
        beq @end
    :

    dec
    sta (SeqState::lookup_addr),y
@end:
    inc redraw
    rts
