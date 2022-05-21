.proc new_pattern
    jsr Sequencer::Func::get_first_unused_patterns
    ldx GridState::x_position
    lda tmp8b,x
    cmp SeqState::max_pattern
    beq @end
    inc
    pha

    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_row

    ldy SeqState::y_position
    jsr SeqState::set_lookup_addr

    pla
    ldy GridState::x_position
    sta (SeqState::lookup_addr),y
    jsr Undo::mark_checkpoint
@end:
    inc redraw
    rts
.endproc
