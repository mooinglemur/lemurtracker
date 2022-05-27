handle_undo_redo_grid_cell:
    ; the operation here is the same whether we're undoing or redoing
    ; we swap the data in the undo buffer with that in grid memory

    lda #XF_STATE_GRID
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

    ; first set the state of the sequencer table to that of the event
    lda tmp_undo_buffer+5 ; set the mix number
    sta SeqState::mix
    lda tmp_undo_buffer+6 ; set row number
    sta SeqState::y_position
    lda tmp_undo_buffer+7 ; set Grid::cursor_position
    sta GridState::cursor_position
    ; we need to trigger the sequencer to populate Grid state
    jsr SeqState::update_grid_patterns
    ; now position the Grid memory pointer (changes bank too)
    ldx tmp_undo_buffer+3
    stx GridState::x_position
    ldy tmp_undo_buffer+4
    sty GridState::y_position
    jsr GridState::set_lookup_addr
    ; now swap the contents
    ldy #0
    :
        lda (GridState::lookup_addr),y
        pha
        lda tmp_undo_buffer+8,y
        sta (GridState::lookup_addr),y
        pla
        sta tmp_undo_buffer+8,y

        iny
        cpy #8
        bcc :-

    ; reset the bank to the undo bank
    jsr set_ram_bank

    ; now copy the event back into the undo space
    ldy #0
    :
        lda tmp_undo_buffer,y
        sta (lookup_addr),y
        iny
        cpy #16
        bcc :-

    ; we're done
    rts

.proc store_grid_cell ; takes in .X = channel column, .Y = row, affects all registers
    lda #1
    sta Undo::tmp_undo_buffer
    lda Undo::checkpoint
    sta Undo::tmp_undo_buffer+1
    stx Undo::tmp_undo_buffer+3
    sty Undo::tmp_undo_buffer+4

    lda #2
    sta Undo::checkpoint

    jsr GridState::set_lookup_addr ; set lookup while x/y are still untouched
    ; determine the actual pattern by looking up the index in the currently displayed patterns
    lda GridState::channel_to_pattern,x
    sta Undo::tmp_undo_buffer+2
    lda SeqState::mix
    sta Undo::tmp_undo_buffer+5
    lda SeqState::y_position
    sta Undo::tmp_undo_buffer+6
    lda GridState::cursor_position
    sta Undo::tmp_undo_buffer+7
    ldy #0
    :
        lda (GridState::lookup_addr),y
        sta Undo::tmp_undo_buffer+8,y
        iny
        cpy #8
        bcc :-

    jsr Undo::set_ram_bank
; we need to invalidate the entire redo stack upon storing a new undo event
; let's do that first
    jsr Undo::invalidate_redo_stack
; advance the pointer to store our new event
    jsr Undo::advance_undo_pointer

; transfer the tmp_undo_buffer
    ldy #0
    :
        lda Undo::tmp_undo_buffer,y
        sta (Undo::lookup_addr),y

        iny
        cpy #16
        bcc :-

; make sure a redo for this event doesn't go past here until there are more events
    jsr Undo::mark_redo_stop

    rts
.endproc
