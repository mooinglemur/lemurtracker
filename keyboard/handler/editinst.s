.proc editinst
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
    jsr common_all
    bcs @noentry

    jsr common_all
    bcc :+
        jmp @noentry
    :


@entry:
@noentry:
@end:
    rts
@ktbl:
    ; this is the static keymapping
    ;     ent
    .byte $0D
@fntbl:
    .word @key_enter
@key_enter:
    rts

.endproc
