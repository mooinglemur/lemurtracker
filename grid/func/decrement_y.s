.proc decrement_y
    jsr selection_start
    ldy GridState::y_position
    bne :+
        ldy GridState::global_pattern_length
        dey
        sty GridState::y_position
        bra decrement_seq_y
    :
    dec GridState::y_position
    bra end
decrement_seq_y:
    ldy SeqState::y_position
    bne :+
        ldy SeqState::max_row
        sty SeqState::y_position
        bra end
    :
    dec SeqState::y_position
end:
    jsr selection_continue
    inc redraw
    rts
.endproc
