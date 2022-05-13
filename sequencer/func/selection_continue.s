selection_continue:
    lda xf_state
    cmp #XF_STATE_SEQUENCER
    beq :+
        jmp @end
    :

    lda KeyboardState::modkeys
    and #(KeyboardState::MOD_LSHIFT|KeyboardState::MOD_RSHIFT)
    bne :+
        jmp @noshift
    :
    ; bail out if we aren't continuing a selection
    lda SeqState::selection_active
    and #1
    bne :+
        jmp @noshift
    :

@check_y_extended:
    lda SeqState::selection_bottom_y
    cmp SeqState::selection_top_y
    bne @y_extended
    ; y is not extended yet
    cmp SeqState::y_position
    beq @check_y_inverted ; y is unextended, but we're not extendeding it

    ; now we're going to determine our y extend direction here because
    ; y is about to be extended this frame
    bcc @extend_down ; selection top (and bottom) is less than new y pos,
                     ; so we extend down.
                     ; y increasing means selection is extending downward
@extend_up:
    smb2 SeqState::selection_active
    bra @y_extended
@extend_down:
    rmb2 SeqState::selection_active
@y_extended:
    bbr2 SeqState::selection_active,@new_bottom
@new_top:
    lda SeqState::y_position
    sta SeqState::selection_top_y
    bra @check_y_inverted
@new_bottom:
    lda SeqState::y_position
    sta SeqState::selection_bottom_y

@check_y_inverted:
    lda SeqState::selection_bottom_y
    cmp SeqState::selection_top_y
    bcs @y_not_inverted
    ; y top and bottom switched places here
    pha
    lda SeqState::selection_top_y
    sta SeqState::selection_bottom_y
    pla
    sta SeqState::selection_top_y
    lda SeqState::selection_active
    eor #%00000100 ; flip the y estend direction bit
    sta SeqState::selection_active
@y_not_inverted:


    bra @end
@noshift:
    lda SeqState::selection_active
    and #3
    cmp #1
    bne @end
    lda #2
    sta SeqState::selection_active
@end:
    rts
