handle_undo_redo_sequencer_row:
    ; the operation here is the same whether we're undoing or redoing
    ; we swap the data in the undo buffer with that in grid memory
    lda #XF_STATE_SEQUENCER
    sta xf_state

    jsr set_ram_bank

    ; first, copy the undo event into temp
    ldy #0
    :
        lda (lookup_addr),y
        sta tmp_undo_buffer,y
        iny
        cpy #16
        bcc :-

    ; set the state of the sequencer table to that of the event
    lda tmp_undo_buffer+2 ; set the mix number
    sta SeqState::mix
    ldx tmp_undo_buffer+3
    stx GridState::x_position
    ldy tmp_undo_buffer+4 ; set row number
    sty SeqState::y_position

    jsr SeqState::set_lookup_addr


    ; now swap the contents (read from seq table first)
    ldy #0
    :
        lda (SeqState::lookup_addr),y
        pha
        lda tmp_undo_buffer+8,y
        sta (SeqState::lookup_addr),y
        pla
        sta tmp_undo_buffer+8,y
        iny
        cpy #8
        bcc :-

    ; reset the bank to the undo bank
    jsr set_ram_bank

    ; now copy the event back into the undo space
    ldy #8
    :
        lda tmp_undo_buffer,y
        sta (lookup_addr),y
        iny
        cpy #16
        bcc :-

    jsr SeqState::update_grid_patterns

    ; we're done
    rts

store_sequencer_row: ; takes in .X = channel column (for position restore), .Y = row, affects all registers
    lda #2
    sta tmp_undo_buffer
    lda checkpoint
    sta tmp_undo_buffer+1
    lda SeqState::mix
    sta tmp_undo_buffer+2
    stx tmp_undo_buffer+3
    sty tmp_undo_buffer+4


    lda #2
    sta checkpoint

    jsr SeqState::set_lookup_addr ; set lookup while y is still untouched

    ; zero out the rest of the buffer
    ldy #5
    lda #0
    :
        sta tmp_undo_buffer,y
        iny
        cpy #8
        bcc :-

    ; save the row
    ldy #0
    :
        lda (SeqState::lookup_addr),y
        sta tmp_undo_buffer+8,y
        iny
        cpy #8
        bcc :-


    jsr set_ram_bank
; we need to invalidate the entire redo stack upon storing a new undo event
; let's do that first
    jsr invalidate_redo_stack
; advance the pointer to store our new event
    jsr advance_undo_pointer

; transfer the tmp_undo_buffer
    ldy #0
    :
        lda tmp_undo_buffer,y
        sta (lookup_addr),y

        iny
        cpy #16
        bcc :-

; make sure a redo for this event doesn't go past here until there are more events
    jsr mark_redo_stop

    rts
