; These process the hotkeys common to XF_STATE_GRID, XF_STATE_SEQUENCER
; and potentially XF_STATE_INSTRUMENTS

.proc common_all

    ; F1/F2/F3
    lda keycode
    cmp #$8A
    beq f1
    cmp #$8B
    beq f2
    cmp #$8C
    beq f3
    bra after_fkeys
f1:
    lda #XF_STATE_GRID
    sta xf_state
    inc redraw
    jmp end
f2:
    lda #XF_STATE_SEQUENCER
    sta xf_state
    inc redraw
    jmp end
f3:
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw
    jmp end

after_fkeys:
mute:
    ; process Shift-1 through 8 (mute)
    lda keycode
    cmp #$31
    bcc :+
    cmp #$39
    bcs :+
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
    lda keycode
    sec
    sbc #$31
    tay
    lda GridState::channel_is_muted,y
    and #1
    eor #1
    sta GridState::channel_is_muted,y
    inc redraw
    bra end
    :

    ; above here are "nondestructive" ops that don't require note_entry to be true


    lda GridState::entrymode
    beq end

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
        jsr Dispatch::redo
        bra end
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
            jsr Dispatch::redo
            bra end
        :
        jsr Dispatch::undo
        bra end
    :

    clc
    rts
end:
    sec
    rts

.endproc


.proc common_grid_seq

    clc
    rts
.endproc
