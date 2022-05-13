.proc select_all
    lda #2
    sta GridState::selection_active
    lda GridState::global_pattern_length
    dec
    sta GridState::selection_bottom_y
    lda #(GridState::NUM_CHANNELS-1)
    sta GridState::selection_right_x
    stz GridState::selection_left_x
    stz GridState::selection_top_y
    inc redraw
    rts
.endproc
