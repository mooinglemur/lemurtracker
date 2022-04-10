; keyboard.s - handler for intercepting PS/2 scancodes and storing their effects

.scope Keyboard

; storage
old_vec: .res 2
scancode: .res 2
modkeys: .res 1

tmp1: .res 2
tmp2: .res 2


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
    jsr set_modkeys

    jsr dohandler

    bra @exit
@keyup:
    ldy #1
    jsr set_modkeys

    stz scancode
    stz scancode+1
@exit:
    plx
    pla
    plp
    jmp (old_vec)
    ; ^^ we're outta here

MOD_LSHIFT = 1
MOD_RSHIFT = 2
MOD_LCTRL = 4
MOD_RCTRL = 8
MOD_LALT = 16
MOD_RALT = 32

set_modkeys:
    ; sets or clears bits in the modkeys variable
    ; bit 0 - $12 - left shift
    ; bit 1 - $59 - right shift
    ; bit 2 - $14 - left ctrl
    ; bit 3 - $E0 $14 - right ctrl
    ; bit 4 - $11 - left alt
    ; bit 5 - $E0 $11 - right alt/altgr

    lda #0
    ldx scancode
    cpx #$12
    bne @not_lshift
    lda #1
    bra @end
@not_lshift:
    cpx #$59
    bne @not_rshift
    lda #2
    bra @end
@not_rshift:
    cpx #$14
    bne @not_ctrl
    lda #4
    ldx scancode+1
    cpx #$E0
    bne @end
    lda #8
    bra @end
@not_ctrl:
    cpx #$11
    bne @not_alt
    lda #16
    ldx scancode+1
    cpx #$E0
    bne @end
    lda #32
@not_alt:
@end:
    cpy #0
    beq @keydown
@keyup:
    eor #$ff
    and modkeys
    sta modkeys
    bra @exit
@keydown:
    ora modkeys
    sta modkeys
@exit:
    rts

dohandler:
    lda xf_state
    asl
    tax
    jmp (handlertbl,x)
;   ^^ we're outta here

handlertbl:
    .word handler0,handler1,handler2,handler3
    .word handler4,handler5,handler6,handler7
    .word handler8,handler9,handler10,handler11
    .word handler12,handler13,handler14,handler15

handler0:
handler1:
handler2:
handler3:
    rts

; handler for states 4 and 5 are in the grid editor, which are different
; for the input events but not most of the navigation events
handler4:
handler5:
    ldy #(@ktblh-@ktbl)
@loop:
    lda scancode
    cmp @ktbl-1,y
    beq @checkh
@loop_cont:
    dey
    bne @loop
    bra @nomatch
@checkh:
    lda scancode+1
    cmp @ktblh-1,y
    beq @match
    bra @loop_cont
@match:
    dey
    tya
    asl
    tay
    lda @fntbl,y
    sta tmp1
    lda @fntbl+1,y
    sta tmp1+1
    jmp (tmp1)
@nomatch:
    rts
@ktbl:
    ; this is the static keymapping
    ;     up  dn  lt  rt  hm  end pgu pgd
    .byte $75,$72,$6B,$74,$6C,$69,$7D,$7A
@ktblh:
    .byte $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
@fntbl:
    .word Function::decrement_grid_y ;up
    .word Function::increment_grid_y ;dn
    .word @key_left
    .word @key_right
    .word @key_home
    .word @key_end
    .word Function::mass_decrement_grid_y
    .word Function::mass_increment_grid_y
@key_left:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :+
        jmp Function::decrement_grid_x
    :
    jmp Function::decrement_grid_cursor
@key_right:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :+
        jmp Function::increment_grid_x
    :
    jmp Function::increment_grid_cursor
@key_home:
    lda #0
    jmp Function::set_grid_y
@key_end:
    lda Grid::global_frame_length
    jmp Function::set_grid_y


handler6:
handler7:
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
