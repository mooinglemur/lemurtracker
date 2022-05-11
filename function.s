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
    lda Sequencer::mix
    beq :+
        dec
    :
    sta Sequencer::mix
    inc redraw
    rts


decrement_sequencer_cell:
    ldx ::Grid::x_position
    ldy Sequencer::y_position
    jsr Undo::store_sequencer_row
    jsr Undo::mark_checkpoint

    ldy Sequencer::y_position
    jsr Sequencer::set_lookup_addr


    ldy ::Grid::x_position
    lda (Sequencer::lookup_addr),y
    beq @end
    cmp #$FF
    bne :+
        lda (Sequencer::mix0_lookup_addr),y
        beq @end
    :

    dec
    sta (Sequencer::lookup_addr),y
@end:
    inc redraw
    rts

decrement_sequencer_x:
    jsr sequencer_selection_start
decrement_sequencer_x_without_starting_selection:
    ldy ::Grid::x_position
    bne :+
        ldy #(::Grid::NUM_CHANNELS - 1)
        sty ::Grid::x_position
        bra @end
    :
    dec ::Grid::x_position
@end:
    jsr sequencer_selection_continue
    inc redraw
    rts


decrement_sequencer_y:
    jsr sequencer_selection_start
    ldy Sequencer::y_position
    bne :+
        ldy Sequencer::max_row
        sty Sequencer::y_position
        bra @end
    :
    dec Sequencer::y_position
@end:
    jsr sequencer_selection_continue
    inc redraw
    rts


decrement_sequencer_y_page:
    jsr sequencer_selection_start
    lda Sequencer::y_position
    sec
    sbc #4
    bcs :+
        lda #0
    :
    sta Sequencer::y_position
    jsr sequencer_selection_continue
    inc redraw
    rts




delete_sequencer_row: ; uses tmp1,tmp2,tmp3,tmp4
    ; if we only have one row, do nothing
    ldy Sequencer::max_row
    bne :+
        jmp @end
    :

    lda Sequencer::mix
    pha ; preserve currently selected mix

    ldx ::Grid::x_position
    ldy Sequencer::y_position ; start y position
    iny
    sty tmp3 ; end y position (this is the row we copy up)
    lda Sequencer::selection_active ; is selection active? if so, we delete the selection instead
    beq @after_selection

    ldy Sequencer::selection_top_y
    sty Sequencer::y_position ; start y position
    ldy Sequencer::selection_bottom_y
    iny
    sty tmp3 ; end y position
    stz Sequencer::selection_active ; deselect

@after_selection:
    lda tmp3
    sta tmp4 ; need to keep a copy of tmp3 for the mix loop
    ldy Sequencer::y_position
    jsr Undo::store_sequencer_max_row ; makes sure undo returns us to the correct mix and position
    lda tmp3
    sec
    sbc Sequencer::y_position
    sta tmp2
    lda Sequencer::max_row
    sec
    sbc tmp2
    sta tmp2; save new max_row
    bpl :+
        inc tmp2
    :
    ; we need to shift everything up in this column from cursor position down
    ; to the end of the sequencer, (in all mixes!)
    lda #0
    sta Sequencer::mix
@mixloop:
    ldy Sequencer::y_position
    sty tmp1 ; reset tmp1 to remaining top row of deletion
    ldy tmp4
    sty tmp3
@loop:
    ldy tmp3
    cpy Sequencer::max_row
    beq @copy_row
    bcs @empty_row
@copy_row:
    ldy tmp1
    ldx ::Grid::x_position
    jsr Undo::store_sequencer_row
    jsr Sequencer::set_ram_bank

    ldy tmp3
    jsr Sequencer::set_lookup_addr

    ldy #0
    :
        lda (Sequencer::lookup_addr),y
        sta tmp8b,y
        iny
        cpy #8
        bcc :-

    ldy tmp1
    jsr Sequencer::set_lookup_addr

    ldy #0
    :
        lda tmp8b,y
        sta (Sequencer::lookup_addr),y
        iny
        cpy #8
        bcc :-

    inc tmp1
    inc tmp3
    bra @loop

@empty_row:
    ldy tmp1
    jsr Sequencer::set_lookup_addr
    jsr Undo::store_sequencer_row
    jsr Sequencer::set_ram_bank

    lda #$FF
    ldy #0
    :
        sta (Sequencer::lookup_addr),y
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
    inc Sequencer::mix
    lda Sequencer::mix
    cmp #Sequencer::MIX_LIMIT
    bcs :+
        jmp @mixloop
    :
@finalize:
    pla ; restore active mix
    sta Sequencer::mix
    ldx ::Grid::x_position
    ldy Sequencer::y_position
    jsr Undo::store_sequencer_max_row ; makes sure redo returns us to the correct mix too
    jsr Undo::mark_checkpoint
    lda tmp2
    sta Sequencer::max_row
    ldy Sequencer::y_position
    beq :+
        cpy Sequencer::max_row
        bcc :+
        dec Sequencer::y_position
    :
    inc redraw
@check_mix0_row0: ; if we zeroed out (nulled out) all rows, we need to set them to 0
    lda Sequencer::mix
    pha
    stz Sequencer::mix
    ldy #0
    jsr Sequencer::set_lookup_addr
    pla
    sta Sequencer::mix
    ldy #8
    :
        dey
        bmi @end
        lda (Sequencer::lookup_addr),y
        cmp #$FF
        bne :-
        lda #0
        sta (Sequencer::lookup_addr),y
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
    lda ::Grid::entrymode
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
    lda ::Grid::entrymode
    beq @end
    lda #OP_INC_SEQ_CELL
    sta op_dispatch_flag
@end:
    rts

dispatch_increment_sequencer_max_row:
    lda ::Grid::entrymode
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
    ldy ::Grid::octave
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
    lda Sequencer::mix
    inc
    cmp #Sequencer::MIX_LIMIT
    bcc :+
        dec
    :
    sta Sequencer::mix
    inc redraw
    rts


increment_sequencer_cell:
    ldx ::Grid::x_position
    ldy Sequencer::y_position
    jsr Undo::store_sequencer_row
    jsr Undo::mark_checkpoint

    ldy Sequencer::y_position
    jsr Sequencer::set_lookup_addr

    ldy ::Grid::x_position
    lda (Sequencer::lookup_addr),y
    cmp #$FF
    bne :+
        lda (Sequencer::mix0_lookup_addr),y
    :
    cmp Sequencer::max_pattern
    bcs @end

    inc
    sta (Sequencer::lookup_addr),y
@end:
    inc redraw
    rts

increment_sequencer_max_row: ; increment max row, and populate with first unused pattern
    lda Sequencer::max_row
    inc
    cmp #Sequencer::ROW_LIMIT
    bcs @end

    jsr Function::Grid::get_first_unused_patterns

    ldx ::Grid::x_position
    ldy Sequencer::max_row
    jsr Undo::store_sequencer_max_row
    inc Sequencer::max_row
    ldy Sequencer::max_row
    sty Sequencer::y_position
    lda Sequencer::mix
    pha
    stz Sequencer::mix
    jsr Undo::store_sequencer_row
    ldy Sequencer::max_row
    jsr Sequencer::set_lookup_addr
    ldy #0
    :
        lda tmp8b,y
        inc
        sta (Sequencer::lookup_addr),y
        iny
        cpy #8
        bcc :-
    pla
    sta Sequencer::mix
    jsr Undo::mark_checkpoint
@end:
    inc redraw
    rts


increment_sequencer_x:
    jsr sequencer_selection_start
    ldy ::Grid::x_position
    cpy #(::Grid::NUM_CHANNELS - 1)
    bcc :+
        stz ::Grid::x_position
        bra @end
    :
    inc ::Grid::x_position
@end:
    jsr sequencer_selection_continue
    inc redraw
    rts

increment_sequencer_y:
    jsr sequencer_selection_start
    ldy Sequencer::y_position
    cpy Sequencer::max_row
    bcc :+
        stz Sequencer::y_position
        bra @end
    :
    inc Sequencer::y_position
@end:
    jsr sequencer_selection_continue
    inc redraw
    rts

increment_sequencer_y_page:
    lda sequencer_selection_start
    lda Sequencer::y_position
    clc
    adc #4
    bcs @clamp

    cmp Sequencer::max_row
    bcc @end

@clamp:
    lda Sequencer::max_row
@end:
    sta Sequencer::y_position
    jsr sequencer_selection_continue
    inc redraw
    rts


insert_cell:

    ldy ::Grid::global_pattern_length
    dey
    dey
    sty tmp1
    ; to get us back to the row where we did the insert, we have to
    ; store an undo event here first
    ldy ::Grid::y_position
    ldx ::Grid::x_position
    jsr Undo::store_grid_cell

    ; we need to shift everything down in this column starting from the end
    ; of the pattern and going toward the current position
@copy_cell:
    ldx ::Grid::x_position
    ldy tmp1
    iny
    jsr Undo::store_grid_cell

    ldx ::Grid::x_position
    ldy tmp1
    jsr ::Grid::set_lookup_addr


    ldy #0
    :
        phy
        lda (::Grid::lookup_addr),y
        pha

        tya
        clc
        adc #(8*::Grid::NUM_CHANNELS)
        tay

        pla
        sta (::Grid::lookup_addr),y

        ply
        iny
        cpy #8
        bcc :-

    ldy tmp1
    cpy ::Grid::y_position
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
        sta (::Grid::lookup_addr),y
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
    adc Sequencer::max_row
    cmp #Sequencer::ROW_LIMIT
    bcc :+
        ; carry is already set to indicate error
        rts
    :

    lda Sequencer::mix
    pha ; preserve currently selected mix

    ldx ::Grid::x_position
    ldy Sequencer::y_position
    jsr Undo::store_sequencer_max_row ; makes sure undo returns us to the correct mix and position

    ; we need to shift everything from cursor position down
    ; to the end of the sequencer, (in all mixes!)
    lda #0
    sta Sequencer::mix
@mixloop:
    lda Sequencer::max_row
    sta tmp2 ; tmp3 is the src cursor
    clc
    adc tmp1
    sta tmp3 ; tmp3 is the dest cursor
@loop:
    ldy tmp3
    ldx ::Grid::x_position
    jsr Undo::store_sequencer_row

    ldy tmp2
    jsr Sequencer::set_lookup_addr

    ldy #0
    :
        lda (Sequencer::lookup_addr),y
        sta tmp8b,y
        iny
        cpy #8
        bcc :-

    ldy tmp3
    jsr Sequencer::set_lookup_addr

    ldy #0
    :
        lda tmp8b,y
        sta (Sequencer::lookup_addr),y
        iny
        cpy #8
        bcc :-

    dec tmp2
    dec tmp3
    lda tmp2
    bmi @fill_loop ; in case we wrapped around to FF
    cmp Sequencer::y_position
    bcs @loop
@fill_loop:
    ; tmp2 is now in the row above our insert
    ; tmp3 is now in a row that we must nullify (in mixes 1-7)
    ; or populate (in mix 0)
    ldy tmp3
    ldx ::Grid::x_position
    jsr Undo::store_sequencer_row
    ldy tmp3
    jsr Sequencer::set_lookup_addr

    lda Sequencer::mix
    beq @mix0


    lda #$FF
    ldy #0
    :
        sta (Sequencer::lookup_addr),y
        iny
        cpy #8
        bcc :-
    bra @check_fill
@mix0:
    jsr Function::Grid::get_first_unused_patterns ; stores in tmp8b

    ldy tmp3
    jsr Sequencer::set_lookup_addr

    ldy #0
    :
        lda tmp8b,y
        inc
        sta (Sequencer::lookup_addr),y
        iny
        cpy #8
        bcc :-
@check_fill:
    dec tmp3
    lda tmp3
    bmi @check_mix
    cmp Sequencer::y_position
    bcs @fill_loop
@check_mix: ; Chex mix
    inc Sequencer::mix
    lda Sequencer::mix
    cmp #Sequencer::MIX_LIMIT
    bcs :+
        jmp @mixloop
    :
@finalize:
    pla ; restore active mix
    sta Sequencer::mix
    ldx ::Grid::x_position
    ldy Sequencer::y_position
    jsr Undo::store_sequencer_max_row ; makes sure redo returns us to the correct mix too
    jsr Undo::mark_checkpoint
    lda Sequencer::max_row
    clc
    adc tmp1
    sta Sequencer::max_row
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

play_note: ;.A = note, .X = column, .Y = instrument
    rts

sequencer_select_all:
    lda #2
    sta Sequencer::selection_active
    lda Sequencer::max_row
    sta Sequencer::selection_bottom_y
    stz Sequencer::selection_top_y
    inc redraw
    rts

sequencer_select_none:
    stz Sequencer::selection_active
    inc redraw
    rts


sequencer_selection_continue:
    lda xf_state
    cmp #XF_STATE_SEQUENCER
    beq :+
        jmp @end
    :

    lda GKeyboard::modkeys
    and #(GKeyboard::MOD_LSHIFT|GKeyboard::MOD_RSHIFT)
    bne :+
        jmp @noshift
    :
    ; bail out if we aren't continuing a selection
    lda Sequencer::selection_active
    and #1
    bne :+
        jmp @noshift
    :

@check_y_extended:
    lda Sequencer::selection_bottom_y
    cmp Sequencer::selection_top_y
    bne @y_extended
    ; y is not extended yet
    cmp Sequencer::y_position
    beq @check_y_inverted ; y is unextended, but we're not extendeding it

    ; now we're going to determine our y extend direction here because
    ; y is about to be extended this frame
    bcc @extend_down ; selection top (and bottom) is less than new y pos,
                     ; so we extend down.
                     ; y increasing means selection is extending downward
@extend_up:
    smb2 Sequencer::selection_active
    bra @y_extended
@extend_down:
    rmb2 Sequencer::selection_active
@y_extended:
    bbr2 Sequencer::selection_active,@new_bottom
@new_top:
    lda Sequencer::y_position
    sta Sequencer::selection_top_y
    bra @check_y_inverted
@new_bottom:
    lda Sequencer::y_position
    sta Sequencer::selection_bottom_y

@check_y_inverted:
    lda Sequencer::selection_bottom_y
    cmp Sequencer::selection_top_y
    bcs @y_not_inverted
    ; y top and bottom switched places here
    pha
    lda Sequencer::selection_top_y
    sta Sequencer::selection_bottom_y
    pla
    sta Sequencer::selection_top_y
    lda Sequencer::selection_active
    eor #%00000100 ; flip the y estend direction bit
    sta Sequencer::selection_active
@y_not_inverted:


    bra @end
@noshift:
    lda Sequencer::selection_active
    and #3
    cmp #1
    bne @end
    lda #2
    sta Sequencer::selection_active
@end:
    rts


sequencer_selection_start:
    lda xf_state
    cmp #XF_STATE_SEQUENCER
    bne @end

    lda GKeyboard::modkeys
    and #(GKeyboard::MOD_LSHIFT|GKeyboard::MOD_RSHIFT)
    beq @end

    lda Sequencer::selection_active
    bne :+
        lda Sequencer::y_position
        sta Sequencer::selection_top_y
        sta Sequencer::selection_bottom_y
        lda #1
        sta Sequencer::selection_active
        bra @end
    :
    and #3
    cmp #2
    bne :+
        stz Sequencer::selection_active
        jmp sequencer_selection_start ; starting a new selection
    :
@end:
    rts






set_sequencer_cell:
    sta tmp1 ; store updated value
    ldx Sequencer::mix
    bne :+
        cmp #$FF ; if we were going to set the value to $FF, we must not be in mix 0
        beq @end
    :

    ldx ::Grid::x_position
    ldy Sequencer::y_position
    jsr Undo::store_sequencer_row
    jsr Sequencer::set_ram_bank
    ldy ::Grid::x_position

    lda tmp1
    sta (Sequencer::lookup_addr),y
    jsr Undo::mark_checkpoint
@end:
    inc redraw
    rts



set_sequencer_y:
    pha
    jsr sequencer_selection_start
    pla
    sta Sequencer::y_position
    jsr sequencer_selection_continue
    inc redraw
    rts



.endscope
