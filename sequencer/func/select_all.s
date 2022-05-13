select_all:
    lda #2
    sta SeqState::selection_active
    lda SeqState::max_row
    sta SeqState::selection_bottom_y
    stz SeqState::selection_top_y
    inc redraw
    rts
