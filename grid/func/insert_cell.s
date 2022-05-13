insert_cell:

    ldy GridState::global_pattern_length
    dey
    dey
    sty tmp1
    ; to get us back to the row where we did the insert, we have to
    ; store an undo event here first
    ldy GridState::y_position
    ldx GridState::x_position
    jsr Undo::store_grid_cell

    ; we need to shift everything down in this column starting from the end
    ; of the pattern and going toward the current position
@copy_cell:
    ldx GridState::x_position
    ldy tmp1
    iny
    jsr Undo::store_grid_cell

    ldx GridState::x_position
    ldy tmp1
    jsr GridState::set_lookup_addr


    ldy #0
    :
        phy
        lda (GridState::lookup_addr),y
        pha

        tya
        clc
        adc #(8*GridState::NUM_CHANNELS)
        tay

        pla
        sta (GridState::lookup_addr),y

        ply
        iny
        cpy #8
        bcc :-

    ldy tmp1
    cpy GridState::y_position
    beq @empty_cell

    dec tmp1
    bra @copy_cell

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
    inc redraw
@end:
    rts
