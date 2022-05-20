.proc decode_scancode
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
.endproc
