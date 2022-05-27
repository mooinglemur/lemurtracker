handle_undo_redo_instrument_first_half:
    ; the operation here is the same whether we're undoing or redoing
    ; we swap the data in the undo buffer with that in grid memory
    lda #XF_STATE_INSTRUMENTS
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
    ldy tmp_undo_buffer+2 ; set the mix number
    sty InstState::y_position

    jsr InstState::set_lookup_addr

    ; now swap the contents (read from inst table first)
    ldy #0
    :
        lda (InstState::lookup_addr),y
        pha
        lda tmp_undo_buffer+8,y
        sta (InstState::lookup_addr),y
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

    ; we're done
    rts

handle_undo_redo_instrument_second_half:
    ; the operation here is the same whether we're undoing or redoing
    ; we swap the data in the undo buffer with that in grid memory
    lda #XF_STATE_INSTRUMENTS
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
    ldy tmp_undo_buffer+2 ; set the mix number
    sty InstState::y_position

    jsr InstState::set_lookup_addr

    ; now swap the contents (read from inst table first)
    ldy #8
    :
        lda (InstState::lookup_addr),y
        pha
        lda tmp_undo_buffer,y
        sta (InstState::lookup_addr),y
        pla
        sta tmp_undo_buffer,y
        iny
        cpy #16
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

    ; we're done
    rts

store_instrument_first_half: ; takes in .Y = row, affects all registers
    lda #4
    sta tmp_undo_buffer
    lda checkpoint
    sta tmp_undo_buffer+1
    sty tmp_undo_buffer+2

    lda #2
    sta checkpoint

    jsr InstState::set_lookup_addr ; set lookup while y is still untouched

    ; zero out the rest of the buffer
    ldy #3
    lda #0
    :
        sta tmp_undo_buffer,y
        iny
        cpy #8
        bcc :-

    ; save the instrument (first half)
    ldy #0
    :
        lda (InstState::lookup_addr),y
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


store_instrument_second_half: ; takes in .Y = row, affects all registers
    lda #5
    sta tmp_undo_buffer
    lda checkpoint
    sta tmp_undo_buffer+1
    sty tmp_undo_buffer+2

    lda #2
    sta checkpoint

    jsr InstState::set_lookup_addr ; set lookup while y is still untouched

    ; zero out the rest of the buffer
    ldy #3
    lda #0
    :
        sta tmp_undo_buffer,y
        iny
        cpy #8
        bcc :-

    ; save the instrument (first half)
    ldy #8
    :
        lda (InstState::lookup_addr),y
        sta tmp_undo_buffer,y
        iny
        cpy #16
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
