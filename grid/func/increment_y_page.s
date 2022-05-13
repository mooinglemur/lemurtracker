increment_y_page:
    jsr selection_start
    lda GridState::y_position
    clc
    adc #16
    bcs @clamp

    cmp GridState::global_pattern_length
    bcc @end

@clamp:
    lda GridState::global_pattern_length
    dec
@end:
    sta GridState::y_position
    jsr selection_continue
    inc redraw
    rts
