.scope Clipboard

base_bank: .res 1

content_type: .res 1
x_width: .res 1
y_height: .res 1

;00 - content_type
;       00 - effectively empty clipboard
;       01 - pattern
;       02 - sequencer


; temp space
tmp_paste_buffer: .res 8
.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2
tmp1: .res 1
.popseg

sel_x_iterator: .res 1
sel_y_iterator: .res 1
clip_x_iterator: .res 1
clip_y_iterator: .res 1

set_ram_bank:
    lda base_bank
    sta x16::Reg::RAMBank
    rts


set_lookup_addr:
    stz lookup_addr
    stz lookup_addr+1

    jsr set_ram_bank

    sty lookup_addr

    ; multiply by 64 (8 channels, 8 bytes per entry)
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    ; column/channel, multiply by 8
    txa
    asl
    asl
    asl
    clc
    adc lookup_addr
    sta lookup_addr
    lda lookup_addr+1
    adc #$A0 ; high ram start page
    sta lookup_addr+1

    rts


copy_grid_cells:

    ; if there's no selection, force select the currently active cell
    lda GridState::selection_active
    bne @selection_found
    lda #2
    sta GridState::selection_active
    lda GridState::x_position
    sta GridState::selection_left_x
    sta GridState::selection_right_x
    lda GridState::y_position
    sta GridState::selection_top_y
    sta GridState::selection_bottom_y
    inc redraw
@selection_found:
    lda GridState::selection_left_x
    sta sel_x_iterator
    lda GridState::selection_top_y
    sta sel_y_iterator
    stz clip_x_iterator
    stz clip_y_iterator
@loop:
    ; copy the current cell to the buffer
    ldx sel_x_iterator
    ldy sel_y_iterator
    jsr GridState::set_lookup_addr

    ldy #0
    :
        lda (GridState::lookup_addr),y
        sta tmp_paste_buffer,y
        iny
        cpy #8
        bcc :-

    ldx clip_x_iterator
    ldy clip_y_iterator
    jsr set_lookup_addr

    ldy #0
    :
        lda tmp_paste_buffer,y
        sta (lookup_addr),y

        iny
        cpy #8
        bcc :-

    ; increment x
    inc clip_x_iterator
    inc sel_x_iterator
    lda sel_x_iterator
    cmp GridState::selection_right_x
    beq @loop
    bcc @loop

    lda clip_x_iterator
    sta x_width

    ; reset x and increment y at the right edge of the selection
    stz clip_x_iterator
    lda GridState::selection_left_x
    sta sel_x_iterator

    inc clip_y_iterator
    inc sel_y_iterator

    ; check y bounds
    lda sel_y_iterator
    cmp GridState::selection_bottom_y
    beq @loop
    bcc @loop

    ; we've completed the copy operation
    ; or cop-eration for short
    lda clip_y_iterator
    sta y_height
    lda #1
    sta content_type

    rts

copy_sequencer_rows:

    ; if there's no selection, force select the currently row
    lda SeqState::selection_active
    bne @selection_found
    lda #2
    sta SeqState::selection_active
    lda SeqState::y_position
    sta SeqState::selection_top_y
    sta SeqState::selection_bottom_y
    inc redraw
@selection_found:
    lda SeqState::selection_top_y
    sta sel_y_iterator
    stz clip_y_iterator
@loop:
    ; copy the current cell to the buffer
    ldy sel_y_iterator
    jsr SeqState::set_lookup_addr

    ldy #0
@columnloop:
    lda (SeqState::lookup_addr),y
    cmp #$FF
    bne :+
        lda (SeqState::mix0_lookup_addr),y
    :
    sta tmp_paste_buffer,y
    iny
    cpy #GridState::NUM_CHANNELS
    bcc @columnloop

    ldx #0
    ldy clip_y_iterator
    jsr set_lookup_addr

    ldy #0
    :
        lda tmp_paste_buffer,y
        sta (lookup_addr),y

        iny
        cpy #8
        bcc :-

    lda #GridState::NUM_CHANNELS
    sta x_width

    ; increment y
    inc clip_y_iterator
    inc sel_y_iterator

    ; check y bounds
    lda sel_y_iterator
    cmp SeqState::selection_bottom_y
    beq @loop
    bcc @loop

    ; we've completed the copy operation
    ; or cop-eration for short
    lda clip_y_iterator
    sta y_height
    lda #2
    sta content_type

    rts


paste_cells:  ; .A bitfield
              ; 0 merge paste,
              ; 1 paste notes
              ; 2 paste instruments
              ; 3 paste volumes
              ; 4 paste effects
    sta tmp1

    lda content_type
    cmp #1
    beq :+
        jmp @end
    :


    stz clip_x_iterator
    stz clip_y_iterator
    lda GridState::x_position
    sta sel_x_iterator
    sta GridState::selection_left_x
    lda GridState::y_position
    sta sel_y_iterator
    sta GridState::selection_top_y
    lda #2
    sta GridState::selection_active

@loop:
    ldx clip_x_iterator
    ldy clip_y_iterator
    jsr set_lookup_addr
    ldy #0
    :
        lda (lookup_addr),y
        sta tmp_paste_buffer,y
        iny
        cpy #8
        bcc :-

    ldx sel_x_iterator
    ldy sel_y_iterator
    jsr Undo::store_grid_cell

    ldx sel_x_iterator
    stx GridState::selection_right_x
    ldy sel_y_iterator
    sty GridState::selection_bottom_y
    jsr GridState::set_lookup_addr

@notes:
    ; check whether we're pasting notes
    bbr1 tmp1,@after_notes
    bbr0 tmp1,@do_notes ; if merge paste, and note is zero, skip
    lda tmp_paste_buffer+0
    beq @after_notes
@do_notes:
    lda tmp_paste_buffer+0
    sta (GridState::lookup_addr) ; 0th index
@after_notes:
    ; check if pasting instruments
    bbr2 tmp1,@after_inst
    ; merge paste is meaningless for this column
@do_inst:
    lda tmp_paste_buffer+1
    ldy #1
    sta (GridState::lookup_addr),y
@after_inst:
    ; check if pasting volume
    bbr3 tmp1,@after_vol

    bbr0 tmp1,@do_vol ; if merge paste, and vol is zero, skip
    lda tmp_paste_buffer+2
    beq @after_vol
@do_vol:
    lda tmp_paste_buffer+2
    ldy #2
    sta (GridState::lookup_addr),y
@after_vol:
    ; check if pasting effects
    bbr4 tmp1,@after_eff

    bbr0 tmp1,@do_eff ; if merge paste, and vol is zero, skip
    lda tmp_paste_buffer+3
    beq @after_eff
@do_eff:

    lda tmp_paste_buffer+3
    ldy #3
    sta (GridState::lookup_addr),y
    lda tmp_paste_buffer+4
    iny
    sta (GridState::lookup_addr),y
@after_eff:

    ; done pasting this cell
    inc sel_x_iterator
    inc clip_x_iterator
    lda clip_x_iterator

    cmp x_width
    bcs :+
        lda sel_x_iterator
        cmp #GridState::NUM_CHANNELS
        bcs :+
        jmp @loop
    :

    ; reset x and increment y at the right edge of the selection
    stz clip_x_iterator
    lda GridState::x_position
    sta sel_x_iterator

    inc sel_y_iterator
    inc clip_y_iterator

    ; check y bounds
    lda clip_y_iterator
    cmp y_height
    bcs :+
        lda sel_y_iterator
        cmp GridState::global_pattern_length
        bcs :+
        jmp @loop
    :

    ; we've completed the paste operation
    ; just to make redo put the cursor in the right place, let's resave the
    ; current grid position
    ldx GridState::x_position
    ldy GridState::y_position
    jsr Undo::store_grid_cell
    jsr Undo::mark_checkpoint
@end:
    inc redraw

    rts


paste_sequencer_rows:

    lda content_type
    cmp #2
    beq :+
        jmp @end
    :

    stz clip_y_iterator
    lda SeqState::y_position
    sta sel_y_iterator
    sta SeqState::selection_top_y
    lda #2
    sta SeqState::selection_active

@loop:
    ldx #0
    ldy clip_y_iterator
    jsr set_lookup_addr

    ; read from clipboard
    ldy #0
    :
        lda (lookup_addr),y
        sta tmp_paste_buffer,y
        iny
        cpy #8
        bcc :-

    ; store undo
    ldx GridState::x_position
    ldy sel_y_iterator
    jsr Undo::store_sequencer_row

    ; copy to sequencer
    ldy sel_y_iterator
    sty SeqState::selection_bottom_y
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda tmp_paste_buffer,y
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-


    ; done pasting this row
    inc sel_y_iterator
    inc clip_y_iterator

    ; check y bounds
    lda clip_y_iterator
    cmp y_height
    bcs :+
        lda sel_y_iterator
        cmp #SeqState::ROW_LIMIT ; max row count, n-1 is last row #
        bcs :+
        jmp @loop
    :

    ; extend Sequencer::max_row if our paste extended past the old end
    dec sel_y_iterator
    lda sel_y_iterator
    cmp SeqState::max_row
    bcc :+
        pha
        jsr Undo::store_sequencer_max_row
        pla
        sta SeqState::max_row

    :

    ; we've completed the paste operation
    ; just to make redo put the cursor in the right place, let's resave the
    ; current sequencer position
    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_row
    jsr Undo::mark_checkpoint
@end:
    inc redraw

    rts


.endscope
