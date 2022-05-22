.proc backspace
    stz GridState::selection_active
    lda GridState::cursor_position
    beq note_column
    cmp #4
    beq move_left
    cmp #7
    bcs move_left
    bra end
move_left:
    jmp decrement_cursor
note_column:
    jmp delete_cell_above
end:
    rts
.endproc
