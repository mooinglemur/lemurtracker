redo:
    ; apply one redo group
    lda redo_size
    bne @can_redo
    lda redo_size+1
    bne @can_redo
    rts ; immediately return if we can't redo

@can_redo:
    ; clear selections for now
    stz GridState::selection_active
    stz SeqState::selection_active

    ; pointer should be behind the first redoable event
    ; reset the bank to the undo bank, and advance
    jsr advance_undo_pointer

    ldy #0
    lda (lookup_addr),y
    cmp #$01 ; grid cell
    beq @redo_grid_cell
    cmp #$02 ; sequencer row
    beq @redo_sequencer_row
    cmp #$03 ; sequencer max_row
    beq @redo_sequencer_max_row
    cmp #$04 ; instrument first half
    beq @redo_instrument_first_half
    cmp #$05
    beq @redo_instrument_second_half
    bra @check_end_of_redo_group
@redo_grid_cell:
    jsr handle_undo_redo_grid_cell
    bra @check_end_of_redo_group
@redo_sequencer_row:
    jsr handle_undo_redo_sequencer_row
    bra @check_end_of_redo_group
@redo_sequencer_max_row:
    jsr handle_undo_redo_sequencer_max_row
    bra @check_end_of_redo_group
@redo_instrument_first_half:
    jsr handle_undo_redo_instrument_first_half
    bra @check_end_of_redo_group
@redo_instrument_second_half:
    jsr handle_undo_redo_instrument_second_half
    bra @check_end_of_redo_group
@check_end_of_redo_group:
    jsr advance_undo_pointer
    ldy #1
    lda (lookup_addr),y
    cmp #2
    beq @continue
    ; we just finished a redo group, back it up once more and stop
    jsr reverse_undo_pointer

    ; now decrement redo_size and increment undo_size
    lda redo_size
    sec
    sbc #1
    sta redo_size
    lda redo_size+1
    sbc #0
    sta redo_size+1

    lda undo_size
    clc
    adc #1
    sta undo_size
    lda undo_size+1
    adc #0
    sta undo_size+1

    lda #1
    sta checkpoint
    bra @end
@continue:
    ; after checking the end of the redo group, we still need to back up
    jsr reverse_undo_pointer
    bra @can_redo
@end:
    inc redraw
    rts
