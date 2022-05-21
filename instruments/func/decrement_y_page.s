decrement_y_page:
    lda InstState::y_position
    sec
    sbc #4
    bcs :+
        lda #0
    :
    sta InstState::y_position
    inc redraw
    rts
