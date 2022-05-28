undo:

    ; apply one undo group
    lda undo_size
    bne @can_undo
    lda undo_size+1
    bne @can_undo
    rts ; immediately return if we can't undo

@can_undo:
    ; clear selections for now
    stz GridState::selection_active
    stz SeqState::selection_active


    ; pointer should be at the most recent undo event
    ; reset the bank to the undo bank
    jsr set_ram_bank

    ldy #0
    lda (lookup_addr),y
    cmp #$01 ; pattern cell
    beq @undo_grid_cell
    cmp #$02 ; sequencer row
    beq @undo_sequencer_row
    cmp #$03 ; sequencer max_row
    beq @undo_sequencer_max_row
    cmp #$04 ; instrument
    beq @undo_instrument
    bra @check_end_of_undo_group
@undo_grid_cell:
    jsr handle_undo_redo_grid_cell
    bra @check_end_of_undo_group
@undo_sequencer_row:
    jsr handle_undo_redo_sequencer_row
    bra @check_end_of_undo_group
@undo_sequencer_max_row:
    jsr handle_undo_redo_sequencer_max_row
    bra @check_end_of_undo_group
@undo_instrument:
    jsr handle_undo_redo_instrument
    bra @check_end_of_undo_group
@check_end_of_undo_group:
    jsr set_ram_bank
    ldy #1
    lda (lookup_addr),y
    cmp #2
    beq @continue
    ; we just finished an undo group, back it up once more and stop
    jsr reverse_undo_pointer

    ; now decrement undo_size and increment redo_size
    lda undo_size
    sec
    sbc #1
    sta undo_size
    lda undo_size+1
    sbc #0
    sta undo_size+1

    lda redo_size
    clc
    adc #1
    sta redo_size
    lda redo_size+1
    adc #0
    sta redo_size+1

    lda #1
    sta checkpoint
    bra @end
@continue:
    jsr reverse_undo_pointer
    bra @can_undo
@end:
    inc redraw
    rts
