delete_row: ; uses tmp1,tmp2,tmp3,tmp4
    ; if we only have one row, do nothing
    ldy SeqState::max_row
    bne :+
        jmp @end
    :

    lda SeqState::mix
    pha ; preserve currently selected mix

    ldx GridState::x_position
    ldy SeqState::y_position ; start y position
    iny
    sty tmp3 ; end y position (this is the row we copy up)
    lda SeqState::selection_active ; is selection active? if so, we delete the selection instead
    beq @after_selection

    ldy SeqState::selection_top_y
    sty SeqState::y_position ; start y position
    ldy SeqState::selection_bottom_y
    iny
    sty tmp3 ; end y position
    stz SeqState::selection_active ; deselect

@after_selection:
    lda tmp3
    sta tmp4 ; need to keep a copy of tmp3 for the mix loop
    ldy SeqState::y_position
    jsr Undo::store_sequencer_max_row ; makes sure undo returns us to the correct mix and position
    lda tmp3
    sec
    sbc SeqState::y_position
    sta tmp2
    lda SeqState::max_row
    sec
    sbc tmp2
    sta tmp2; save new max_row
    bpl :+
        inc tmp2
    :
    ; we need to shift everything up in this column from cursor position down
    ; to the end of the sequencer, (in all mixes!)
    lda #0
    sta SeqState::mix
@mixloop:
    ldy SeqState::y_position
    sty tmp1 ; reset tmp1 to remaining top row of deletion
    ldy tmp4
    sty tmp3
@loop:
    ldy tmp3
    cpy SeqState::max_row
    beq @copy_row
    bcs @empty_row
@copy_row:
    ldy tmp1
    ldx GridState::x_position
    jsr Undo::store_sequencer_row
    jsr SeqState::set_ram_bank

    ldy tmp3
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda (SeqState::lookup_addr),y
        sta tmp8b,y
        iny
        cpy #8
        bcc :-

    ldy tmp1
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda tmp8b,y
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-

    inc tmp1
    inc tmp3
    bra @loop

@empty_row:
    ldy tmp1
    jsr SeqState::set_lookup_addr
    jsr Undo::store_sequencer_row
    jsr SeqState::set_ram_bank

    lda #$FF
    ldy #0
    :
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-
    ldy tmp1
    cpy tmp4 ; max selection+1
    bcs @check_mix
    cpy #127 ; special case if all rows are in use, done with last row
    beq @check_mix

    inc tmp1
    inc tmp3
    bra @loop
@check_mix: ; Chex mix
    inc SeqState::mix
    lda SeqState::mix
    cmp #SeqState::MIX_LIMIT
    bcs :+
        jmp @mixloop
    :
@finalize:
    pla ; restore active mix
    sta SeqState::mix
    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_max_row ; makes sure redo returns us to the correct mix too
    jsr Undo::mark_checkpoint
    lda tmp2
    sta SeqState::max_row
    ldy SeqState::y_position
    beq :+
        cpy SeqState::max_row
        bcc :+
        dec SeqState::y_position
    :
    inc redraw
@check_mix0_row0: ; if we zeroed out (nulled out) all rows, we need to set them to 0
    lda SeqState::mix
    pha
    stz SeqState::mix
    ldy #0
    jsr SeqState::set_lookup_addr
    pla
    sta SeqState::mix
    ldy #8
    :
        dey
        bmi @end
        lda (SeqState::lookup_addr),y
        cmp #$FF
        bne :-
        lda #0
        sta (SeqState::lookup_addr),y
        bra :-
@end:
    rts
