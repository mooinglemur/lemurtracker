.scope IRQ
.segment "CODE"
previous_handler: .res 2


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
    inc framecounter


@after_handler:

    plp
    jmp (previous_handler)

.endscope
