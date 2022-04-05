; keyboard.s - handler for intercepting PS/2 scancodes and storing their effects

.scope Keyboard

; storage
old_vec: .res 2
last_key: .res 2

setup_handler:
    sei

    lda x16::Vec::KbdVec
    sta old_vec
    lda x16::Vec::KbdVec+1
    sta old_vec+1

    lda #<handler
    sta x16::Vec::KbdVec
    lda #>handler
    sta x16::Vec::KbdVec+1

    cli
    rts

teardown_handler:
    sei

    lda old_vec
    sta x16::Vec::KbdVec
    lda old_vec+1
    sta x16::Vec::KbdVec+1

    cli
    rts

handler:
    php
    pha
    phx

@exit:
    plx
    pla
    plp
    jmp (old_vec)

.endscope
