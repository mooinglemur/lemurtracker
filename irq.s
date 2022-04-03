; This is for the 65C02.  This assembler directive enables
; the use of 65C02-specific mnemonics.
; (PHX/PLX, PHY/PLY, BRA, ...)
.PC02

.scope xf_irq
.segment "BSS"
previous_handler: .res 2

.segment "CODE"
setup:
    sei
    lda $0314
    sta previous_handler
    lda $0315
    sta previous_handler+1

    lda #<handler
    sta $0314
    lda #>handler
    sta $0315
    cli

    rts

teardown:
    sei
    lda previous_handler
    sta $0314
    lda previous_handler+1
    sta $0315
    cli

    rts

handler:
    php
    sei

    lda Vera::Reg::ISR
    and #$01
    beq @after_handler

    ; we're pulling this out of the concerto isr.  We're using the vblank instead of AFLOW so we can't use that code directly
    ; backup shared variables (shared means: both main program and ISR can use them)
    lda concerto_synth::mzpba
    pha
    lda concerto_synth::mzpbe
    pha
    lda concerto_synth::mzpbf
    pha
    lda concerto_synth::mzpbg
    pha
    lda Vera::Reg::AddrL
    pha
    lda Vera::Reg::AddrM
    pha
    lda Vera::Reg::AddrH
    pha
    ; call playback routine
    jsr concerto_synth::concerto_playback_routine
    ; do synth tick updates
    jsr concerto_synth::synth_engine::synth_tick
    ; restore shared variables
    pla
    sta Vera::Reg::AddrH
    pla
    sta Vera::Reg::AddrM
    pla
    sta Vera::Reg::AddrL
    pla
    sta concerto_synth::mzpbg
    pla
    sta concerto_synth::mzpbf
    pla
    sta concerto_synth::mzpbe
    pla
    sta concerto_synth::mzpba

@after_handler:

    plp
    jmp (previous_handler)

.endscope
