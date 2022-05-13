.proc selection_start
    lda xf_state
    cmp #XF_STATE_GRID
    bne end

    lda KeyboardState::modkeys
    and #(KeyboardState::MOD_LSHIFT|KeyboardState::MOD_RSHIFT)
    beq end

    lda GridState::selection_active
    bne :+
        lda GridState::x_position
        sta GridState::selection_left_x
        sta GridState::selection_right_x
        lda GridState::y_position
        sta GridState::selection_top_y
        sta GridState::selection_bottom_y
        lda #1
        sta GridState::selection_active
        bra end
    :
    and #3
    cmp #2
    bne :+
        stz GridState::selection_active
        jmp selection_start ; starting a new selection
    :
end:
    rts
.endproc
