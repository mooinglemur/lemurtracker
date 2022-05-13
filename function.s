; function.s - handler for changing the state of the tracker
; predominantly originating through keystrokes, but also mouse actions
; and perhaps other inputs in the future


.scope Function

OP_UNDO = 1
OP_REDO = 2
OP_BACKSPACE = 3
OP_INSERT = 4
OP_COPY = 5
OP_DELETE = 6
OP_PASTE = 7
OP_NOTE = 8
OP_CUT = 9
OP_DEC_SEQ_CELL = 10
OP_INC_SEQ_CELL = 11
OP_GRID_ENTRY = 12
OP_INC_SEQ_MAX_ROW = 13
OP_DELETE_SEQ = 14
OP_SET_SEQ_CELL = 15
OP_INSERT_SEQ = 16

op_dispatch_flag: .byte $00
op_dispatch_operand: .res 1

tmp1: .res 1
tmp2: .res 1
tmp3: .res 1
tmp4: .res 1
tmp8b: .res 8


.include "function/grid.s"


copy:
    lda xf_state
    cmp #XF_STATE_GRID
    bne :+
        jmp Clipboard::copy_grid_cells
    :
    cmp #XF_STATE_SEQUENCER
    bne :+
        jmp Clipboard::copy_sequencer_rows
    :

    rts


decrement_mix:
    lda SeqState::mix
    beq :+
        dec
    :
    sta SeqState::mix
    inc redraw
    rts


decrement_sequencer_cell:
    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_row
    jsr Undo::mark_checkpoint

    ldy SeqState::y_position
    jsr SeqState::set_lookup_addr


    ldy GridState::x_position
    lda (SeqState::lookup_addr),y
    beq @end
    cmp #$FF
    bne :+
        lda (SeqState::mix0_lookup_addr),y
        beq @end
    :

    dec
    sta (SeqState::lookup_addr),y
@end:
    inc redraw
    rts








delete_sequencer_row: ; uses tmp1,tmp2,tmp3,tmp4
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



dispatch_backspace:
    lda #OP_BACKSPACE
    sta op_dispatch_flag
    rts

dispatch_copy:
    lda #OP_COPY
    sta op_dispatch_flag
    rts

dispatch_cut:
    lda #OP_CUT
    sta op_dispatch_flag
    rts

dispatch_decrement_sequencer_cell:
    lda GridState::entrymode
    beq @end
    lda #OP_DEC_SEQ_CELL
    sta op_dispatch_flag
@end:
    rts


dispatch_delete_selection:
    lda #OP_DELETE
    sta op_dispatch_flag
    rts

dispatch_delete_sequencer_row:
    lda #OP_DELETE_SEQ
    sta op_dispatch_flag
    rts


dispatch_increment_sequencer_cell:
    lda GridState::entrymode
    beq @end
    lda #OP_INC_SEQ_CELL
    sta op_dispatch_flag
@end:
    rts

dispatch_increment_sequencer_max_row:
    lda GridState::entrymode
    beq @end
    lda #OP_INC_SEQ_MAX_ROW
    sta op_dispatch_flag
@end:
    rts


dispatch_grid_entry:
    sta op_dispatch_operand
    lda #OP_GRID_ENTRY
    sta op_dispatch_flag
    rts

dispatch_insert:
    lda #OP_INSERT
    sta op_dispatch_flag
    rts

dispatch_insert_sequencer_row:
    sta op_dispatch_operand
    lda #OP_INSERT_SEQ
    sta op_dispatch_flag
    rts


dispatch_note_entry: ; make note entry happen outside of IRQ
    ; .A = notecode, we need convert to note value (MIDI number)
    cmp #$ff ; note delete
    beq @note_delete
    cmp #$fe ; note cut
    beq @note_cut
    cmp #$fd ; note release
    beq @note_release

    dec
    sta op_dispatch_operand
    ; note stored is 0 for C0, we need to add the octave+1 so that 12 is C0
    clc
    lda #0
    ldy GridState::octave
    iny
@octave_loop:
    adc #12
    dey
    bne @octave_loop
    adc op_dispatch_operand
    bra @end
@note_delete:
    lda #0
    bra @end
@note_cut:
    lda #1
    bra @end
@note_release:
    lda #2
@end:
    cmp #$80 ; clamp to 0-127 here, cancel entry if >= 128
    bcc :+
        lda #$ff
    :
    sta op_dispatch_operand
    lda #OP_NOTE
    sta op_dispatch_flag
    rts

dispatch_paste:
    sta op_dispatch_operand
    lda #OP_PASTE
    sta op_dispatch_flag
    rts

dispatch_redo:
    lda #OP_REDO
    sta op_dispatch_flag
    rts

dispatch_set_sequencer_cell:
    sta op_dispatch_operand
    lda #OP_SET_SEQ_CELL
    sta op_dispatch_flag
    rts


dispatch_undo:
    lda #OP_UNDO
    sta op_dispatch_flag
    rts





increment_mix:
    lda SeqState::mix
    inc
    cmp #SeqState::MIX_LIMIT
    bcc :+
        dec
    :
    sta SeqState::mix
    inc redraw
    rts


increment_sequencer_cell:
    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_row
    jsr Undo::mark_checkpoint

    ldy SeqState::y_position
    jsr SeqState::set_lookup_addr

    ldy GridState::x_position
    lda (SeqState::lookup_addr),y
    cmp #$FF
    bne :+
        lda (SeqState::mix0_lookup_addr),y
    :
    cmp SeqState::max_pattern
    bcs @end

    inc
    sta (SeqState::lookup_addr),y
@end:
    inc redraw
    rts

increment_sequencer_max_row: ; increment max row, and populate with first unused pattern
    lda SeqState::max_row
    inc
    cmp #SeqState::ROW_LIMIT
    bcs @end

    jsr Sequencer::Func::get_first_unused_patterns

    ldx GridState::x_position
    ldy SeqState::max_row
    jsr Undo::store_sequencer_max_row
    inc SeqState::max_row
    ldy SeqState::max_row
    sty SeqState::y_position
    lda SeqState::mix
    pha
    stz SeqState::mix
    jsr Undo::store_sequencer_row
    ldy SeqState::max_row
    jsr SeqState::set_lookup_addr
    ldy #0
    :
        lda tmp8b,y
        inc
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-
    pla
    sta SeqState::mix
    jsr Undo::mark_checkpoint
@end:
    inc redraw
    rts





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

insert_sequencer_row: ; uses tmp1,tmp2,tmp3,tmp4
    sta tmp1 ; number of rows we're inserting
    ; if we would exceed max rows, return with error
    clc
    adc SeqState::max_row
    cmp #SeqState::ROW_LIMIT
    bcc :+
        ; carry is already set to indicate error
        rts
    :

    lda SeqState::mix
    pha ; preserve currently selected mix

    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_max_row ; makes sure undo returns us to the correct mix and position

    ; we need to shift everything from cursor position down
    ; to the end of the sequencer, (in all mixes!)
    lda #0
    sta SeqState::mix
@mixloop:
    lda SeqState::max_row
    sta tmp2 ; tmp3 is the src cursor
    clc
    adc tmp1
    sta tmp3 ; tmp3 is the dest cursor
@loop:
    ldy tmp3
    ldx GridState::x_position
    jsr Undo::store_sequencer_row

    ldy tmp2
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda (SeqState::lookup_addr),y
        sta tmp8b,y
        iny
        cpy #8
        bcc :-

    ldy tmp3
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda tmp8b,y
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-

    dec tmp2
    dec tmp3
    lda tmp2
    bmi @fill_loop ; in case we wrapped around to FF
    cmp SeqState::y_position
    bcs @loop
@fill_loop:
    ; tmp2 is now in the row above our insert
    ; tmp3 is now in a row that we must nullify (in mixes 1-7)
    ; or populate (in mix 0)
    ldy tmp3
    ldx GridState::x_position
    jsr Undo::store_sequencer_row
    ldy tmp3
    jsr SeqState::set_lookup_addr

    lda SeqState::mix
    beq @mix0


    lda #$FF
    ldy #0
    :
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-
    bra @check_fill
@mix0:
    jsr Sequencer::Func::get_first_unused_patterns ; stores in tmp8b

    ldy tmp3
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda tmp8b,y
        inc
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-
@check_fill:
    dec tmp3
    lda tmp3
    bmi @check_mix
    cmp SeqState::y_position
    bcs @fill_loop
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
    lda SeqState::max_row
    clc
    adc tmp1
    sta SeqState::max_row
    inc redraw
@end:
    ; carry should already be clear to indicate no error
    rts




paste: ; .A = paste type
    ldx xf_state
    cpx #XF_STATE_GRID
    bne @not_grid
    jmp Clipboard::paste_cells
@not_grid:
    cpx #XF_STATE_SEQUENCER
    bne @not_seq
    cmp #0
    beq @seq
    ; paste insert
    lda Clipboard::y_height
    jsr insert_sequencer_row
    bcs @end
    jsr Undo::unmark_checkpoint
@seq:
    jmp Clipboard::paste_sequencer_rows
@not_seq:
@end:
    rts



sequencer_select_all:
    lda #2
    sta SeqState::selection_active
    lda SeqState::max_row
    sta SeqState::selection_bottom_y
    stz SeqState::selection_top_y
    inc redraw
    rts

sequencer_select_none:
    stz SeqState::selection_active
    inc redraw
    rts



.endscope
