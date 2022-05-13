selection_start:
    lda xf_state
    cmp #XF_STATE_SEQUENCER
    bne @end

    lda KeyboardState::modkeys
    and #(KeyboardState::MOD_LSHIFT|KeyboardState::MOD_RSHIFT)
    beq @end

    lda SeqState::selection_active
    bne :+
        lda SeqState::y_position
        sta SeqState::selection_top_y
        sta SeqState::selection_bottom_y
        lda #1
        sta SeqState::selection_active
        bra @end
    :
    and #3
    cmp #2
    bne :+
        stz SeqState::selection_active
        jmp selection_start ; starting a new selection
    :
@end:
    rts
