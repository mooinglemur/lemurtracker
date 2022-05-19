; dispatch.s - dispatch handler for changing the state of the tracker
; predominantly originating through keystrokes

.scope Dispatch

OP_UNDO = 1
OP_REDO = 2
OP_BACKSPACE = 3
OP_INSERT = 4
OP_COPY_GRID = 5
OP_DELETE = 6
OP_PASTE_GRID = 7
OP_NOTE = 8
OP_CUT = 9
OP_DEC_SEQ_CELL = 10
OP_INC_SEQ_CELL = 11
OP_GRID_ENTRY = 12
OP_INC_SEQ_MAX_ROW = 13
OP_DELETE_SEQ = 14
OP_SET_SEQ_CELL = 15
OP_INSERT_SEQ = 16
OP_COPY_SEQ = 17
OP_PASTE_SEQ = 18
OP_SEQ_ENTRY = 19

flag: .byte $00
operand: .res 1

backspace:
    lda #OP_BACKSPACE
    sta flag
    rts

copy_grid:
    lda #OP_COPY_GRID
    sta flag
    rts

copy_seq:
    lda #OP_COPY_SEQ
    sta flag
    rts

cut:
    lda #OP_CUT
    sta flag
    rts

decrement_sequencer_cell:
    lda GridState::entrymode
    beq @end
    lda #OP_DEC_SEQ_CELL
    sta flag
@end:
    rts


delete_selection:
    lda #OP_DELETE
    sta flag
    rts

delete_sequencer_row:
    lda #OP_DELETE_SEQ
    sta flag
    rts


increment_sequencer_cell:
    lda GridState::entrymode
    beq @end
    lda #OP_INC_SEQ_CELL
    sta flag
@end:
    rts

increment_sequencer_max_row:
    lda GridState::entrymode
    beq @end
    lda #OP_INC_SEQ_MAX_ROW
    sta flag
@end:
    rts


grid_entry:
    sta operand
    lda #OP_GRID_ENTRY
    sta flag
    rts

insert:
    lda #OP_INSERT
    sta flag
    rts

insert_sequencer_row:
    sta operand
    lda #OP_INSERT_SEQ
    sta flag
    rts


note_entry: ; make note entry happen outside of IRQ
    ; .A = notecode, we need convert to note value (MIDI number)
    cmp #$ff ; note delete
    beq @note_delete
    cmp #$fe ; note cut
    beq @note_cut
    cmp #$fd ; note release
    beq @note_release

    dec
    sta operand
    ; note stored is 0 for C0, we need to add the octave+1 so that 12 is C0
    clc
    lda #0
    ldy GridState::octave
    iny
@octave_loop:
    adc #12
    dey
    bne @octave_loop
    adc operand
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
    sta operand
    lda #OP_NOTE
    sta flag
    rts

paste_grid:
    sta operand
    lda #OP_PASTE_GRID
    sta flag
    rts

paste_seq:
    sta operand
    lda #OP_PASTE_SEQ
    sta flag
    rts

redo:
    lda #OP_REDO
    sta flag
    rts

.proc seq_entry
    bcs end ; carry indicates abort
    lda #OP_SEQ_ENTRY
    sta flag
end:
    lda #XF_STATE_SEQUENCER
    sta xf_state
    inc redraw
    rts
.endproc


set_sequencer_cell:
    sta operand
    lda #OP_SET_SEQ_CELL
    sta flag
    rts


undo:
    lda #OP_UNDO
    sta flag
    rts




.endscope
