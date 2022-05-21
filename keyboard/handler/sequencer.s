.proc sequencer ; XF_STATE_SEQUENCER
    jsr decode_scancode
    ldy #(@fntbl-@ktbl)
@loop:
    lda keycode
    cmp @ktbl-1,y
    beq @match
    dey
    bne @loop
    bra @nomatch
@match:
    dey
    tya
    asl
    tax
    jmp (@fntbl,x)
@nomatch:
    ; handle Ctrl+A / Ctrl+Shift+A
    lda keycode
    cmp #$61
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Sequencer::Func::select_none
        :
        jmp Sequencer::Func::select_all
    :

; handle Ctrl+C / Ctrl+Shift+C
    lda keycode
    cmp #$63
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp @end ; ignore Ctrl+Shift+C for now
        :
        jmp Dispatch::copy_seq
    :

    ; above here are "nondestructive" ops that don't require note_entry to be true

    lda GridState::entrymode
    bne :+
        jmp @noentry
    :

    ; below here are "destructive" ops, note_entry needs to be on for these

    ; handle Ctrl+V / Ctrl+Shift+V

    lda keycode
    cmp #$76
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            lda #1 ; insert paste
            jmp Dispatch::paste_seq
        :
        lda #0 ; regular paste
        jmp Dispatch::paste_seq
    :

    ; handle Ctrl+Y

    lda keycode
    cmp #$79
    bne :+
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :+
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        bne :+
        jmp Dispatch::redo
    :


    ; handle Ctrl+Z / Ctrl+Shift+Z

    lda keycode
    cmp #$7A
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Dispatch::redo
        :
        jmp Dispatch::undo
    :

    ; handle direct pattern number entry
    lda keycode
    cmp #$30
    bcc @end
    cmp #$3A
    bcc @entry
    cmp #$61
    bcc @end
    cmp #$67
    bcs @end
@entry:
    lda #<Dispatch::seq_entry
    sta TextField::callback
    lda #>Dispatch::seq_entry
    sta TextField::callback+1
    lda #TextField::CONSTRAINT_HEX
    sta TextField::constraint
    lda #TextField::ENTRYMODE_FILL
    sta TextField::entrymode
    stz TextField::insertmode
    lda #1
    sta TextField::gridmode
    lda #2
    sta TextField::width
    lda GridState::x_position
    asl
    adc #3
    tax
    ldy #(SeqState::SEQUENCER_LOCATION_Y+SeqState::SEQUENCER_GRID_ROWS/2+1)
    lda charcode
    jmp TextField::start
@noentry:
@end:
    rts
@ktbl:
    ; this is the static keymapping
    ;     up  dn  lt  rt  hm  end pgu pgd F1  F3  spc
    .byte $80,$81,$82,$83,$84,$85,$86,$87,$8A,$8C,$20
    ;     -   =   tab ins del I   N
    .byte $2D,$3D,$09,$88,$89,$69,$6E
@fntbl:
    .word Sequencer::Func::decrement_y ;up
    .word Sequencer::Func::increment_y ;dn
    .word Sequencer::Func::decrement_x ;lt wrapper for grid_x
    .word Sequencer::Func::increment_x ;rt wrapper for grid_x
    .word @key_home
    .word @key_end
    .word Sequencer::Func::decrement_y_page
    .word Sequencer::Func::increment_y_page
    .word @key_F1
    .word @key_F3
    .word @key_space
    .word @key_minus
    .word @key_equalsplus
    .word @key_tab
    .word @key_insert
    .word @key_delete
    .word @key_i
    .word @key_n
@key_home:
    lda #0
    jmp Sequencer::Func::set_y
@key_end:
    lda SeqState::max_row
    jmp Sequencer::Func::set_y
@key_space:
    ; Flip state of audition/entry flag
    lda GridState::entrymode
    eor #$01
    sta GridState::entrymode
    inc redraw
    rts
@key_F1:
    lda #XF_STATE_GRID
    sta xf_state
    inc redraw
    rts
@key_F3:
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw
    rts
@key_minus:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp @end
        :
        jmp Sequencer::Func::decrement_mix
    :
    jmp Dispatch::decrement_sequencer_cell
@key_equalsplus:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Dispatch::increment_sequencer_max_row
        :
        jmp Sequencer::Func::increment_mix
    :
    jmp Dispatch::increment_sequencer_cell
@key_tab:
    stz GridState::cursor_position
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Sequencer::Func::decrement_x_without_starting_selection
    :
    jmp Sequencer::Func::increment_x
@key_insert:
    lda GridState::entrymode
    bne :+
        jmp @end
    :
    lda #1
    jmp Dispatch::insert_sequencer_row
@key_delete:
    lda GridState::entrymode
    bne :+
        jmp @end
    :
    jmp Dispatch::delete_sequencer_row
@key_i: ; inherit
    lda GridState::entrymode
    bne :+
        jmp @end
    :
    lda #$FF
    jmp Dispatch::set_sequencer_cell
@key_n: ; new pattern (set to max used pattern + 1 if possible)
    lda GridState::entrymode
    bne :+
        jmp @end
    :
    jmp Dispatch::new_pattern


.endproc
