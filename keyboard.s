; keyboard.s - handler for intercepting PS/2 scancodes and dispatching their effects

.scope Keyboard

old_vec: .res 2
tmp1: .res 1
tmp2: .res 1

scancode = KeyboardState::scancode
keycode = KeyboardState::keycode
notecode = KeyboardState::notecode
charcode = KeyboardState::charcode

modkeys = KeyboardState::modkeys

MOD_LALT = KeyboardState::MOD_LALT
MOD_RALT = KeyboardState::MOD_RALT
MOD_LCTRL = KeyboardState::MOD_LCTRL
MOD_RCTRL = KeyboardState::MOD_RCTRL
MOD_LSHIFT = KeyboardState::MOD_LSHIFT
MOD_RSHIFT = KeyboardState::MOD_RSHIFT

.include "keyboard/handler.s"

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

    sta scancode
    stx scancode+1

    bcs @keyup
@keydown:
    ldy #0
    jsr Keyboard::Handler::set_modkeys

    jsr dohandler

    bra @exit
@keyup:
    ldy #1
    jsr Keyboard::Handler::set_modkeys

    stz scancode
    stz scancode+1
    stz notecode
    stz keycode
    stz charcode
@exit:
    plx
    pla
    plp
    jmp (old_vec)
    ; ^^ we're outta here




dohandler:
    lda xf_state
    asl
    tax
    jmp (handlertbl,x)
;   ^^ we're outta here

handlertbl:
    .word handler0,handler1,handler2,handler3
;         4/XF_STATE_GRID         5/XF_STATE_TEXT
    .word Keyboard::Handler::grid,Keyboard::Handler::text
;         6/XF_STATE_SEQUENCER         7/XF_STATE_INSTRUMENTS
    .word Keyboard::Handler::sequencer,Keyboard::Handler::instruments
    .word handler8,handler9,handler10,handler11
    .word handler12,handler13,handler14,handler15

handler0:
handler1:
handler2:
handler3:
handler8:
handler9:
handler10:
handler11:
handler12:
handler13:
handler14:
handler15:
    rts


.endscope
