increment_max_row: ; increment max row, and populate with first unused pattern
    lda SeqState::max_row
    inc
    cmp #SeqState::ROW_LIMIT
    bcs @end

    jsr Sequencer::Func::get_first_unused_patterns

    ldx GridState::x_position
    ldy SeqState::max_row
    jsr Undo::store_sequencer_max_row
    inc SeqState::max_row
    ldy SeqState::max_row
    sty SeqState::y_position
    lda SeqState::mix
    pha
    stz SeqState::mix
    jsr Undo::store_sequencer_row
    ldy SeqState::max_row
    jsr SeqState::set_lookup_addr
    ldy #0
    :
        lda tmp8b,y
        cmp SeqState::max_pattern
        bcs :+
            inc
        :
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :--
    pla
    sta SeqState::mix
    jsr Undo::mark_checkpoint
@end:
    inc redraw
    rts
