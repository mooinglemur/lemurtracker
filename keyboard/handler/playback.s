.proc playback
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
    jsr common_mute
    bcs noentry
noentry:
end:
    rts
ktbl:
    ;     end
    .byte $0D
fntbl:
    .word key_enter
key_enter:
    lda #XF_STATE_PLAYBACK_STOP
    sta xf_state
    inc redraw
    rts
.endproc
