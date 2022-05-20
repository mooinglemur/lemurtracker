.proc text
    jsr decode_scancode
    lda charcode
    jmp TextField::entry
.endproc
