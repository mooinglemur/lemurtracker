.proc grid
    jsr decode_scancode
    ldy #(fntbl-ktbl)
loop:
    lda keycode
    cmp ktbl-1,y
    beq match
    dey
    bne loop
    bra nomatch
match:
    dey
    tya
    asl
    tax
    jmp (fntbl,x)
nomatch:

    jsr common_fkeys
    bcc :+
        jmp noentry
    :
    jsr common_mute
    bcc :+
        jmp noentry
    :
    jsr common_undo
    bcc :+
        jmp noentry
    :

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
            jmp Grid::Func::select_none
        :
        jmp Grid::Func::select_all
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
            jmp end ; ignore Ctrl+Shift+C for now
        :
        jmp Dispatch::copy_grid
    :


    ; above here are "nondestructive" ops that don't require note_entry to be true

    lda GridState::entrymode
    bne :+
        jmp noentry
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
            lda #%00011111 ; merge paste all
            jmp Dispatch::paste_grid
        :
        lda #%00011110 ; non-merge paste all
        jmp Dispatch::paste_grid
    :

    ; handle Ctrl+X / Ctrl+Shift+X

    lda keycode
    cmp #$78
    bne :+
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :+
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        bne :+ ; don't do anything for Ctrl+Shift+X
        jmp Dispatch::cut
    :


    ; handle Delete key with selection active
    lda keycode
    cmp #$89
    bne :+
        lda GridState::selection_active
        beq :+
        jmp Dispatch::delete_selection
    :

    ; if we're holding down mod keys besides shift, don't process entries
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL|MOD_LALT|MOD_RALT)
    bne end

    lda GridState::cursor_position ; are we in the note column?
    beq notecolumn
    ; XXX entry for other columns besides the note column
    lda charcode
    beq end
    jsr Dispatch::grid_entry ;.A = keycode
    bra end
notecolumn:
    ; XXX handle non note functions here that affect the notes
    lda notecode ; if we don't have a valid notecode, skip dispatch
    beq end
    jsr Dispatch::note_entry ;.A = notecode
noentry:
end:
    rts
ktbl:
    ;     up  dn  lt  rt  hm  end pgu pgd tab spc [   ]   bsp ins
    .byte $80,$81,$82,$83,$84,$85,$86,$87,$09,$20,$5B,$5D,$08,$88
    ;     n/  n*  -   =   ent
    .byte $96,$97,$2D,$3D,$0D
fntbl:
    .word key_up
    .word key_down
    .word key_left
    .word key_right
    .word key_home
    .word key_end
    .word Grid::Func::decrement_y_page
    .word Grid::Func::increment_y_page
    .word key_tab
    .word key_space
    .word key_leftbracket
    .word key_rightbracket
    .word key_backspace
    .word key_insert
    .word Grid::Func::decrement_octave
    .word Grid::Func::increment_octave
    .word key_minus
    .word key_equalsplus
    .word key_enter
key_up:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :+
        jmp Grid::Func::decrement_y_steps
    :
    lda modkeys
    and #(MOD_LALT|MOD_RALT)
    beq :+
        jmp Sequencer::Func::decrement_y
    :
    jmp Grid::Func::decrement_y
key_down:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :+
        jmp Grid::Func::increment_y_steps
    :
    lda modkeys
    and #(MOD_LALT|MOD_RALT)
    beq :+
        jmp Sequencer::Func::increment_y
    :
    jmp Grid::Func::increment_y
key_left:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL|MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::decrement_x
    :
    jmp Grid::Func::decrement_cursor
key_right:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL|MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::increment_x
    :
    jmp Grid::Func::increment_cursor
key_home:
    lda #0
    jmp Grid::Func::set_y
key_end:
    lda GridState::global_pattern_length
    dec
    jmp Grid::Func::set_y
key_space:
    ; Flip state of audition/entry flag
    lda GridState::entrymode
    eor #$01
    sta GridState::entrymode
    inc redraw
    rts
key_tab:
    stz GridState::cursor_position
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::decrement_x_without_starting_selection
    :
    jmp Grid::Func::increment_x
key_leftbracket:
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::decrement_step
    :
    jmp Grid::Func::decrement_octave
key_rightbracket:
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::increment_step
    :
    jmp Grid::Func::increment_octave
key_backspace:
    lda GridState::entrymode
    beq :+
        jsr Dispatch::backspace
    :
    rts
key_insert:
    lda GridState::entrymode
    beq :+
        jsr Dispatch::insert
    :
    rts
key_minus:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp end
        :
        jmp Sequencer::Func::decrement_mix
    :
    jmp Dispatch::decrement_sequencer_cell
key_equalsplus:
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
key_enter:
    lda #XF_STATE_PLAYBACK_START
    sta xf_state
    rts
.endproc
