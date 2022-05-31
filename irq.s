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

.proc handler
    php
    sei

    lda Vera::Reg::ISR
    and #$01
    beq after_handler

    lda framecounter
    clc
    adc #1
    sta framecounter
    lda framecounter+1
    adc #0
    sta framecounter+1
save_state: ; preserve VERA regs as we need to use them for PSG
    lda Vera::Reg::Ctrl
    pha
    and #%11111110
    sta Vera::Reg::Ctrl
    lda Vera::Reg::AddrL
    pha
    lda Vera::Reg::AddrM
    pha
    lda Vera::Reg::AddrH
    pha
    ; store state of ram bank
    lda x16::Reg::RAMBank
    pha
    ; store state of zeropage lookup addresses that could be clobbered here
    lda GridState::lookup_addr
    pha
    lda GridState::lookup_addr+1
    pha
    lda SeqState::lookup_addr
    pha
    lda SeqState::lookup_addr+1
    pha
    lda InstState::lookup_addr
    pha
    lda InstState::lookup_addr+1
    pha

    jsr PlayerEngine::tick

restore_state:
    pla
    sta InstState::lookup_addr+1
    pla
    sta InstState::lookup_addr
    pla
    sta SeqState::lookup_addr+1
    pla
    sta SeqState::lookup_addr
    pla
    sta GridState::lookup_addr+1
    pla
    sta GridState::lookup_addr

    pla
    sta x16::Reg::RAMBank

    pla
    sta Vera::Reg::AddrH
    pla
    sta Vera::Reg::AddrM
    pla
    sta Vera::Reg::AddrL
    pla
    sta Vera::Reg::Ctrl
after_handler:
    plp
    jmp (previous_handler)

.endproc
.endscope
