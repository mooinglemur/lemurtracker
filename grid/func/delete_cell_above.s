.proc delete_cell_above
    ; if we're at the top of the grid, we do nothing
    ldy GridState::y_position
    beq @end
    dey
    sty tmp1
    ; we need to shift everything up in this column from cursor position down
    ; to the end of the pattern
@loop:
    ldy tmp1
    ldx GridState::x_position
    jsr GridState::set_lookup_addr

    iny
    cpy GridState::global_pattern_length
    dey
    bcs @empty_cell
@copy_cell:
    lda x16::Reg::RAMBank
    pha
    jsr Undo::store_grid_cell
    pla
    sta x16::Reg::RAMBank

    ldy #0
    :
        phy

        tya
        clc
        adc #(8*GridState::NUM_CHANNELS)
        tay
        lda (GridState::lookup_addr),y
        ply
        sta (GridState::lookup_addr),y

        iny
        cpy #8
        bcc :-

    inc tmp1
    bra @loop
@empty_cell:
    lda x16::Reg::RAMBank
    pha

    jsr Undo::store_grid_cell
    jsr Undo::mark_checkpoint

    pla
    sta x16::Reg::RAMBank


    lda #0
    ldy #0
    :
        sta (GridState::lookup_addr),y
        iny
        cpy #8
        bcc :-
@finalize:
    jsr decrement_y
@end:
    rts
.endproc
