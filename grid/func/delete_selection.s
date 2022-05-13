delete_selection:
    ; tmp1 = x, tmp2 = y
    lda GridState::selection_active
    beq @end

    ldx GridState::selection_left_x
    stx tmp1
    ldy GridState::selection_top_y
    sty tmp2
@loop:
    ldx tmp1
    ldy tmp2
    jsr Undo::store_grid_cell
    ldx tmp1
    ldy tmp2
    jsr GridState::set_lookup_addr
    lda #0
    ldy #0
    :
        sta (GridState::lookup_addr),y
        iny
        cpy #8
        bcc :-
    ; advance x
    inc tmp1
    lda tmp1
    cmp GridState::selection_right_x
    beq @loop
    bcc @loop

    ; reset x and advance y
    lda GridState::selection_left_x
    sta tmp1

    inc tmp2
    lda tmp2
    cmp GridState::selection_bottom_y
    beq @loop
    bcc @loop

    jsr Undo::mark_checkpoint
    inc redraw
@end:
    rts
