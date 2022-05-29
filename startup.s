.scope Startup

.proc startup
    ; fall through to romcheck
.endproc

.proc romcheck
    lda x16::Kernal::VERSION
    bpl versioncheck
    eor #$ff
    beq detect_emu ; custom build, unable to detect
versioncheck:
    cmp #39
    bcc badversion
detect_emu:
    ; detect emulator
    lda $9FBE
    cmp #$31
    bne continue_startup ; not emulator

    lda $9FBF
    cmp #$36
    bne continue_startup ; not emulator

    ; toggle emulator keys off
    lda #1
    sta $9FB7

    lda $9FB7
    cmp #1
    beq continue_startup

    ; emulator detected, but we can't disable control keys
    ldx #0
emumessageloop:
    lda emu_message,x
    cmp #0
    beq emumessagedone
    phx
    jsr x16::Kernal::CHROUT
    plx
    inx
    bra emumessageloop
emumessagedone:
    jsr x16::Kernal::CHRIN
    bra continue_startup
badversion:
    ldx #0
versionmessageloop:
    lda version_message,x
    cmp #0
    beq versionmessagedone
    phx
    jsr x16::Kernal::CHROUT
    plx
    inx
    bra versionmessageloop
versionmessagedone:
    sec
    rts
.endproc



.proc continue_startup
    jsr Util::set_charset

    jsr Util::clear_screen

    jsr CustomChars::install

    lda #XF_STATE_GRID
    sta xf_state

    lda #64
    sta GridState::global_pattern_length

    lda #16
    sta GridState::long_hilight_interval
    lda #4
    sta GridState::short_hilight_interval

    jsr IRQ::setup

    jsr Keyboard::setup_handler

    sec
    jsr x16::Kernal::SCREEN_MODE ; get current screen size (in 8px) into .X and .Y
    lda #1
    jsr x16::Kernal::MOUSE_CONFIG ; show the default mouse pointer

    lda #1
    sta redraw

    lda #$00
    sta Undo::lookup_addr
    lda #$A0
    sta Undo::lookup_addr+1

    jsr SeqState::init

    clc
    rts

.endproc

emu_message:
    .byte 13,13
    .byte "!!! EMULATOR ENVIRONMENT DETECTED, BUT WE COULDN'T DISABLE THE EMULATOR'S   !!!",13
    .byte "!!! COMMAND KEYS. SOME CTRL SHORTCUTS MAY NOT WORK, BUT YOU CAN USE THE F10 !!!",13
    .byte "!!! MENU TO REACH THOSE TRACKER FUNCTIONS INSTEAD",13,13
    .byte "PRESS RETURN TO CONTINUE",0
version_message:
    .byte 13,13
    .byte "ROM VERSION TOO OLD, MUST BE >=39",13,0


.endscope
