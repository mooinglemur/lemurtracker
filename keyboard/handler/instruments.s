.proc instruments ; XF_STATE_INSTRUMENTS
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
    ; above here are "nondestructive" ops that don't require note_entry to be true

    lda GridState::entrymode
    beq @noentry

    ; below here are "destructive" ops, note_entry needs to be on for these

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

@entry:
@noentry:
@end:
    rts
@ktbl:
    ; this is the static keymapping
    ;     up  dn  hm  end pgu pgd F1  F2  spc del
    .byte $80,$81,$84,$85,$86,$87,$8A,$8B,$20,$89
@fntbl:
    .word Instruments::Func::decrement_y ;up
    .word Instruments::Func::increment_y ;dn
    .word @key_home
    .word @key_end
    .word Instruments::Func::decrement_y_page
    .word Instruments::Func::increment_y_page
    .word @key_F1
    .word @key_F2
    .word @key_space
    .word @key_delete
@key_home:
    lda #0
    jmp Instruments::Func::set_y
@key_end:
    lda InstState::max_instrument
    jmp Instruments::Func::set_y
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
@key_F2:
    lda #XF_STATE_SEQUENCER
    sta xf_state
    inc redraw
    rts
@key_delete:
    lda GridState::entrymode
    bne :+
        jmp @end
    :
    jmp Dispatch::delete_instrument
.endproc
