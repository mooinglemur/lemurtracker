increment_y_page:
    lda InstState::y_position
    clc
    adc #4
    bcs @clamp

    cmp InstState::max_instrument
    bcc @end

@clamp:
    lda InstState::max_instrument
@end:
    sta InstState::y_position
    inc redraw
    rts
