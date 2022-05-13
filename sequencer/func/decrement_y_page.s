decrement_y_page:
    jsr selection_start
    lda SeqState::y_position
    sec
    sbc #4
    bcs :+
        lda #0
    :
    sta SeqState::y_position
    jsr selection_continue
    inc redraw
    rts
