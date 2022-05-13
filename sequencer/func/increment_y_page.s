increment_y_page:
    lda selection_start
    lda SeqState::y_position
    clc
    adc #4
    bcs @clamp

    cmp SeqState::max_row
    bcc @end
@clamp:
    lda SeqState::max_row
@end:
    sta SeqState::y_position
    jsr selection_continue
    inc redraw
    rts
