.proc note_entry
    stz GridState::selection_active
    pha
    ; first put the old value on the undo stack
    ldx GridState::x_position
    ldy GridState::y_position
    jsr Undo::store_grid_cell
    jsr Undo::mark_checkpoint

    ; now actually apply the note
    ldx GridState::x_position
    ldy GridState::y_position

    jsr GridState::set_lookup_addr ; set the grid lookup_addr value to the beginning
                              ; of the note data for the current row/column
                              ; this affects RAM bank as well
    pla
    sta (GridState::lookup_addr) ; zero offset, this is the note column
    pha

    ldy #1
    lda InstState::y_position ; currently selected instrument
    sta (GridState::lookup_addr),y ; #1 offset, this is the instrument number
    tay

    pla
    ldx GridState::x_position

    inc redraw

    ldy GridState::step
    beq end
advance_step:
    phy
    jsr increment_y
    ply
    dey
    bne advance_step
end:
    rts
.endproc
