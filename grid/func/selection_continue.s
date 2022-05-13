.proc selection_continue
    lda xf_state
    cmp #XF_STATE_GRID
    beq :+
        jmp @end
    :

    lda KeyboardState::modkeys
    and #(KeyboardState::MOD_LSHIFT|KeyboardState::MOD_RSHIFT)
    bne :+
        jmp @noshift
    :
    ; bail out if we aren't continuing a selection
    lda GridState::selection_active
    and #1
    bne :+
        jmp @noshift
    :
@check_y_extended:
    lda GridState::selection_bottom_y
    cmp GridState::selection_top_y
    bne @y_extended
    ; y is not extended yet
    cmp GridState::y_position
    beq @check_x_extended ; y is unextended, but we're not extendeding it

    ; now we're going to determine our y extend direction here because
    ; y is about to be extended this frame
    bcc @extend_down ; selection top (and bottom) is less than new y pos,
                     ; so we extend down.
                     ; y increasing means selection is extending downward
@extend_up:
    smb2 GridState::selection_active
    bra @y_extended
@extend_down:
    rmb2 GridState::selection_active
@y_extended:
    bbr2 GridState::selection_active,@new_bottom
@new_top:
    lda GridState::y_position
    sta GridState::selection_top_y
    bra @check_x_extended
@new_bottom:
    lda GridState::y_position
    sta GridState::selection_bottom_y

@check_x_extended:
    lda GridState::selection_right_x
    cmp GridState::selection_left_x
    bne @x_extended
    ; x is not extended yet
    cmp GridState::x_position
    beq @check_y_inverted ; x is unextended, but we're not extendeding it

    ; now we're going to determine our x extend direction here because
    ; x is about to be extended this frame
    bcc @extend_right ; selection left (and right) is less than new x pos,
                     ; so we extend right.
                     ; x increasing means selection is extending rightward

@extend_left:
    smb3 GridState::selection_active
    bra @x_extended
@extend_right:
    rmb3 GridState::selection_active
@x_extended:
    bbr3 GridState::selection_active,@new_right
@new_left:
    lda GridState::x_position
    sta GridState::selection_left_x
    bra @check_y_inverted
@new_right:
    lda GridState::x_position
    sta GridState::selection_right_x

@check_y_inverted:
    lda GridState::selection_bottom_y
    cmp GridState::selection_top_y
    bcs @y_not_inverted
    ; y top and bottom switched places here
    pha
    lda GridState::selection_top_y
    sta GridState::selection_bottom_y
    pla
    sta GridState::selection_top_y
    lda GridState::selection_active
    eor #%00000100 ; flip the y estend direction bit
    sta GridState::selection_active
@y_not_inverted:

@check_x_inverted:
    lda GridState::selection_right_x
    cmp GridState::selection_left_x
    bcs @x_not_inverted
    ; x left and right switched places here
    pha
    lda GridState::selection_left_x
    sta GridState::selection_right_x
    pla
    sta GridState::selection_left_x
    lda GridState::selection_active
    eor #%00001000 ; flip the x estend direction bit
    sta GridState::selection_active
@x_not_inverted:

    bra @end
@noshift:
    lda GridState::selection_active
    and #3
    cmp #1
    bne @end
    lda #2
    sta GridState::selection_active
@end:
    rts

.endproc
