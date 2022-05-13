.proc increment_y
    jsr selection_start
    inc GridState::y_position
    ldy GridState::y_position
    cpy GridState::global_pattern_length
    bcc :+
        stz GridState::y_position
        bra increment_seq_y
    :
    bra end
increment_seq_y:
    ldy SeqState::y_position
    cpy SeqState::max_row
    bcc :+
        stz SeqState::y_position
        bra end
    :
    inc SeqState::y_position
end:
    jsr selection_continue
    inc redraw
    rts

.endproc
