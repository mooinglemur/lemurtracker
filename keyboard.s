; keyboard.s - handler for intercepting PS/2 scancodes and dispatching their effects

.scope Keyboard

old_vec: .res 2
tmp1: .res 2
tmp2: .res 2

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
    stz notecode
    stz keycode
    stz charcode
@exit:
    plx
    pla
    plp
    jmp (old_vec)
    ; ^^ we're outta here



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

handler4: ; XF_STATE_GRID
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
    ; handle Ctrl+A / Ctrl+Shift+A
    lda keycode
    cmp #$61
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Grid::Func::select_none
        :
        jmp Grid::Func::select_all
    :
    ; handle Ctrl+C / Ctrl+Shift+C
    lda keycode
    cmp #$63
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp @end ; ignore Ctrl+Shift+C for now
        :
        jmp Dispatch::copy_grid
    :
    ; above here are "nondestructive" ops that don't require note_entry to be true

    lda GridState::entrymode
    bne :+
        jmp @noentry
    :

    ; below here are "destructive" ops, note_entry needs to be on for these

    ; handle Ctrl+V / Ctrl+Shift+V

    lda keycode
    cmp #$76
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            lda #%00011111 ; merge paste all
            jmp Dispatch::paste_grid
        :
        lda #%00011110 ; non-merge paste all
        jmp Dispatch::paste_grid
    :

    ; handle Ctrl+X / Ctrl+Shift+X

    lda keycode
    cmp #$78
    bne :+
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :+
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        bne :+ ; don't do anything for Ctrl+Shift+X
        jmp Dispatch::cut
    :

    ; handle Ctrl+Y

    lda keycode
    cmp #$79
    bne :+
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :+
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        bne :+
        jmp Dispatch::redo
    :


    ; handle Ctrl+Z / Ctrl+Shift+Z

    lda keycode
    cmp #$7A
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Dispatch::redo
        :
        jmp Dispatch::undo
    :

    ; handle Delete key with selection active
    lda keycode
    cmp #$89
    bne :+
        lda GridState::selection_active
        beq :+
        jmp Dispatch::delete_selection
    :

    ; if we're holding down mod keys, don't process entries
;    lda modkeys
;    bne @end

    lda GridState::cursor_position ; are we in the note column?
    beq @notecolumn
    ; XXX entry for other columns besides the note column
    lda charcode
    beq @end
    jsr Dispatch::grid_entry ;.A = keycode
    bra @end
@notecolumn:
    ; XXX handle non note functions here that affect the notes
    lda notecode ; if we don't have a valid notecode, skip dispatch
    beq @end
    jsr Dispatch::note_entry ;.A = notecode
@noentry:
@end:
    rts
@ktbl:
    ;     up  dn  lt  rt  hm  end pgu pgd tab spc [   ]   F2  bsp ins
    .byte $80,$81,$82,$83,$84,$85,$86,$87,$09,$20,$5B,$5D,$8B,$08,$88
    ;     n/  n*  -   =   F9
    .byte $96,$97,$2D,$3D,$92
@fntbl:
    .word @key_up
    .word @key_down
    .word @key_left
    .word @key_right
    .word @key_home
    .word @key_end
    .word Grid::Func::decrement_y_page
    .word Grid::Func::increment_y_page
    .word @key_tab
    .word @key_space
    .word @key_leftbracket
    .word @key_rightbracket
    .word @key_F2
    .word @key_backspace
    .word @key_insert
    .word Grid::Func::decrement_octave
    .word Grid::Func::increment_octave
    .word @key_minus
    .word @key_equalsplus
    .word @text_test
@key_up:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :+
        jmp Grid::Func::decrement_y_steps
    :
    lda modkeys
    and #(MOD_LALT|MOD_RALT)
    beq :+
        jmp Sequencer::Func::decrement_y
    :
    jmp Grid::Func::decrement_y
@key_down:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :+
        jmp Grid::Func::increment_y_steps
    :
    lda modkeys
    and #(MOD_LALT|MOD_RALT)
    beq :+
        jmp Sequencer::Func::increment_y
    :
    jmp Grid::Func::increment_y
@key_left:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL|MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::decrement_x
    :
    jmp Grid::Func::decrement_cursor
@key_right:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL|MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::increment_x
    :
    jmp Grid::Func::increment_cursor
@key_home:
    lda #0
    jmp Grid::Func::set_y
@key_end:
    lda GridState::global_pattern_length
    dec
    jmp Grid::Func::set_y
@key_space:
    ; Flip state of audition/entry flag
    lda GridState::entrymode
    eor #$01
    sta GridState::entrymode
    inc redraw
    rts
@key_tab:
    stz GridState::cursor_position
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::decrement_x_without_starting_selection
    :
    jmp Grid::Func::increment_x
@key_leftbracket:
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::decrement_step
    :
    jmp Grid::Func::decrement_octave
@key_rightbracket:
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Grid::Func::increment_step
    :
    jmp Grid::Func::increment_octave
@key_F2:
    lda #XF_STATE_SEQUENCER
    sta xf_state
    inc redraw
    rts
@key_backspace:
    lda GridState::entrymode
    beq :+
        jsr Dispatch::backspace
    :
    rts
@key_insert:
    lda GridState::entrymode
    beq :+
        jsr Dispatch::insert
    :
    rts
@key_minus:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp @end
        :
        jmp Sequencer::Func::decrement_mix
    :
    jmp Dispatch::decrement_sequencer_cell
@key_equalsplus:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Dispatch::increment_sequencer_max_row
        :
        jmp Sequencer::Func::increment_mix
    :
    jmp Dispatch::increment_sequencer_cell
@text_test:
    lda #<SeqState::default_handler
    sta TextField::callback
    lda #>SeqState::default_handler
    sta TextField::callback+1
    lda #TextField::CONSTRAINT_ASCII
    sta TextField::constraint
    lda #TextField::ENTRYMODE_NORMAL
    sta TextField::entrymode
    lda #30
    sta TextField::width
    ldx #5
    ldy #10
    jsr TextField::start
    rts

handler5:
    jsr decode_scancode
    lda charcode
    jmp TextField::entry



handler6: ; XF_STATE_SEQUENCER
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
    ; handle Ctrl+A / Ctrl+Shift+A
    lda keycode
    cmp #$61
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Sequencer::Func::select_none
        :
        jmp Sequencer::Func::select_all
    :

; handle Ctrl+C / Ctrl+Shift+C
    lda keycode
    cmp #$63
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp @end ; ignore Ctrl+Shift+C for now
        :
        jmp Dispatch::copy_seq
    :

    ; above here are "nondestructive" ops that don't require note_entry to be true

    lda GridState::entrymode
    beq @noentry

    ; below here are "destructive" ops, note_entry needs to be on for these

    ; handle Ctrl+V / Ctrl+Shift+V

    lda keycode
    cmp #$76
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            lda #1 ; insert paste
            jmp Dispatch::paste_seq
        :
        lda #0 ; regular paste
        jmp Dispatch::paste_seq
    :


    ; handle Ctrl+Z / Ctrl+Shift+Z

    lda keycode
    cmp #$7A
    bne :++
        lda modkeys
        and #(MOD_LCTRL|MOD_RCTRL)
        beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Dispatch::redo
        :
        jmp Dispatch::undo
    :

    ; handle direct pattern number entry
    lda keycode
    cmp #$30
    bcc @end
    cmp #$3A
    bcc @entry
    cmp #$61
    bcc @end
    cmp #$67
    bcs @end
@entry:
    lda #<Sequencer::Func::entry_callback
    sta TextField::callback
    lda #>Sequencer::Func::entry_callback
    sta TextField::callback+1
    lda #TextField::CONSTRAINT_HEX
    sta TextField::constraint
    lda #TextField::ENTRYMODE_FILL
    sta TextField::entrymode
    lda #2
    sta TextField::width
    lda GridState::x_position
    asl
    adc #3
    tax
    ldy #(SeqState::SEQUENCER_LOCATION_Y+SeqState::SEQUENCER_GRID_ROWS/2+1)
    lda charcode
    jmp TextField::start
@noentry:
@end:
    rts
@ktbl:
    ; this is the static keymapping
    ;     up  dn  lt  rt  hm  end pgu pgd F1  spc
    .byte $80,$81,$82,$83,$84,$85,$86,$87,$8A,$20
    ;     -   =   tab ins del I
    .byte $2D,$3D,$09,$88,$89,$69
@fntbl:
    .word Sequencer::Func::decrement_y ;up
    .word Sequencer::Func::increment_y ;dn
    .word Sequencer::Func::decrement_x ;lt wrapper for grid_x
    .word Sequencer::Func::increment_x ;rt wrapper for grid_x
    .word @key_home
    .word @key_end
    .word Sequencer::Func::decrement_y_page
    .word Sequencer::Func::increment_y_page
    .word @key_F1
    .word @key_space
    .word @key_minus
    .word @key_equalsplus
    .word @key_tab
    .word @key_insert
    .word @key_delete
    .word @key_i
@key_home:
    lda #0
    jmp Sequencer::Func::set_y
@key_end:
    lda SeqState::max_row
    jmp Sequencer::Func::set_y
@key_space:
    ; Flip state of audition/entry flag
    lda GridState::entrymode
    eor #$01
    sta GridState::entrymode
    inc redraw
    rts
@key_F1:
    lda #XF_STATE_GRID
    sta xf_state
    inc redraw
    rts
@key_minus:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp @end
        :
        jmp Sequencer::Func::decrement_mix
    :
    jmp Dispatch::decrement_sequencer_cell
@key_equalsplus:
    lda modkeys
    and #(MOD_LCTRL|MOD_RCTRL)
    beq :++
        lda modkeys
        and #(MOD_LSHIFT|MOD_RSHIFT)
        beq :+
            jmp Dispatch::increment_sequencer_max_row
        :
        jmp Sequencer::Func::increment_mix
    :
    jmp Dispatch::increment_sequencer_cell
@key_tab:
    stz GridState::cursor_position
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq :+
        jmp Sequencer::Func::decrement_x_without_starting_selection
    :
    jmp Sequencer::Func::increment_x
@key_insert:
    lda GridState::entrymode
    bne :+
        jmp @end
    :
    lda #1
    jmp Dispatch::insert_sequencer_row
@key_delete:
    jmp Dispatch::delete_sequencer_row
@key_i: ; inherit
    lda #$FF
    jmp Dispatch::set_sequencer_cell

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


decode_scancode:
    ldy #(@scancodeh-@scancodel)
@loop:
    lda scancode
    cmp @scancodel-1,y
    beq @checkh
@loop_cont:
    dey
    bne @loop
    bra @nomatch
@checkh:
    lda scancode+1
    cmp @scancodeh-1,y
    beq @match
    bra @loop_cont
@match:
    lda @notecode-1,y
    sta notecode
    lda @keycode-1,y
    sta keycode
    sta charcode
    lda modkeys
    and #(MOD_LSHIFT|MOD_RSHIFT)
    beq @nomatch
    lda @shiftcode-1,y
    sta charcode
@nomatch:
    rts
@scancodel:
    ;     spc cr  ncr up  dn  lt  rt  tab bsp \
    .byte $29,$5A,$5A,$75,$72,$6B,$74,$0D,$66,$5D
    ;     n0  n1  n2  n3  n4  n5  n6  n7  n8  n9
    .byte $70,$69,$72,$7A,$6B,$73,$74,$6C,$75,$7D
    ;     0   1   2   3   4   5   6   7   8   9
    .byte $45,$16,$1E,$26,$25,$2E,$36,$3D,$3E,$46
    ;     A   B   C   D   E   F   G   H   I   J
    .byte $1C,$32,$21,$23,$24,$2B,$34,$33,$43,$3B
    ;     K   L   M   N   O   P   Q   R   S   T
    .byte $42,$4B,$3A,$31,$44,$4D,$15,$2D,$1B,$2C
    ;     U   V   W   X   Y   Z   n+  n-  =   -
    .byte $3C,$2A,$1D,$22,$35,$1A,$79,$7B,$55,$4E
    ;     hm  end pgu pgd ins del ,   .   /   ;
    .byte $6C,$69,$7D,$7A,$70,$71,$41,$49,$4A,$4C
    ;     [   ]   F1  F2  F3  F4  F5  F6  F7  F8
    .byte $54,$5B,$05,$06,$04,$0C,$03,$0B,$83,$0A
    ;     F9  F10 F11 F12 n/  n*  `   '   BRK ESC
    .byte $01,$10,$78,$07,$4A,$7C,$0E,$52,$14,$76
@scancodeh:
    ;     spc cr  ncr up  dn  lt  rt  tab bsp \
    .byte $00,$00,$E0,$E0,$E0,$E0,$E0,$00,$00,$00
    ;     n0  n1  n2  n3  n4  n5  n6  n7  n8  n9
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ;     0   1   2   3   4   5   6   7   8   9
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ;     A   B   C   D   E   F   G   H   I   J
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ;     K   L   M   N   O   P   Q   R   S   T
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ;     U   V   W   X   Y   Z   n+  n-  =   -
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ;     hm  end pgu pgd ins del ,   .   /   ;
    .byte $E0,$E0,$E0,$E0,$E0,$E0,$00,$00,$00,$00
    ;     [   ]   F1  F2  F3  F4  F5  F6  F7  F8
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ;     F9  F10 F11 F12 n/  n*  `   '   BRK ESC
    .byte $00,$00,$00,$00,$E0,$00,$00,$00,$E1,$00
@keycode:
    ;     spc cr  ncr up  dn  lt  rt  tab bsp \
    .byte $20,$0D,$0D,$80,$81,$82,$83,$09,$08,$5C
    ;     n0  n1  n2  n3  n4  n5  n6  n7  n8  n9
    .byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39
    ;     0   1   2   3   4   5   6   7   8   9
    .byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39
    ;     a   b   c   d   e   f   g   h   i   j
    .byte $61,$62,$63,$64,$65,$66,$67,$68,$69,$6A
    ;     k   l   m   n   o   p   q   r   s   t
    .byte $6B,$6C,$6D,$6E,$6F,$70,$71,$72,$73,$74
    ;     u   v   w   x   y   z   n+  n-  =   -
    .byte $75,$76,$77,$78,$79,$7A,$2B,$2D,$3D,$2D
    ;     hm  end pgu pgd ins del ,   .   /   ;
    .byte $84,$85,$86,$87,$88,$89,$2C,$2E,$2F,$3B
    ;     [   ]   F1  F2  F3  F4  F5  F6  F7  F8
    .byte $5B,$5D,$8A,$8B,$8C,$8D,$8E,$8F,$90,$91
    ;     F9  F10 F11 F12 n/  n*  `   '   BRK ESC
    .byte $92,$93,$94,$95,$96,$97,$60,$27,$1B,$1B
@notecode: ; NULL/no action = $00, C in current octave = $01
           ; note delete = $FF, note cut = $FE, note release = $FD
    ;     spc cr  ncr up  dn  lt  rt  tab bsp \
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$FD
    ;     n0  n1  n2  n3  n4  n5  n6  n7  n8  n9
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ;     0   1   2   3   4   5   6   7   8   9
    .byte $1C,$FE,$0E,$10,$00,$13,$15,$17,$00,$1A
    ;     A   B   C   D   E   F   G   H   I   J
    .byte $00,$08,$05,$04,$11,$00,$07,$09,$19,$0B
    ;     K   L   M   N   O   P   Q   R   S   T
    .byte $00,$0E,$0C,$0A,$1B,$1D,$0D,$12,$02,$14
    ;     U   V   W   X   Y   Z   n+  n-  =   -
    .byte $18,$06,$0F,$03,$16,$01,$00,$00,$00,$00
    ;     hm  end pgu pgd ins del ,   .   /   ;
    .byte $00,$00,$00,$00,$00,$FF,$0D,$0F,$11,$10
    ;     [   ]   F1  F2  F3  F4  F5  F6  F7  F8
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ;     F9  F10 F11 F12 n/  n*  `   '   BRK ESC
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
@shiftcode:
    ;     spc cr  ncr up  dn  lt  rt  tab bsp |
    .byte $20,$0D,$0D,$80,$81,$82,$83,$09,$08,$7C
    ;     n0  n1  n2  n3  n4  n5  n6  n7  n8  n9
    .byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39
    ;     )   !   @   #   $   %   ^   &   *   (
    .byte $29,$21,$40,$23,$24,$25,$5E,$26,$2A,$28
    ;     A   B   C   D   E   F   G   H   I   J
    .byte $41,$42,$43,$44,$45,$46,$47,$48,$49,$4A
    ;     K   L   M   N   O   P   Q   R   S   T
    .byte $4B,$4C,$4D,$4E,$4F,$50,$51,$52,$53,$54
    ;     U   V   W   X   Y   Z   n+  n-  +   _
    .byte $55,$56,$57,$58,$59,$5A,$2B,$2D,$2B,$5F
    ;     hm  end pgu pgd ins del <   >   ?   :
    .byte $84,$85,$86,$87,$88,$89,$3C,$3E,$3F,$3A
    ;     {   }   F1  F2  F3  F4  F5  F6  F7  F8
    .byte $7B,$7D,$8A,$8B,$8C,$8D,$8E,$8F,$90,$91
    ;     F9  F10 F11 F12 n/  n*  ~   "   BRK ESC
    .byte $92,$93,$94,$95,$96,$97,$7E,$22,$1B,$1B
.endscope
