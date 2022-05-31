.proc editinst_psg
    jsr decode_scancode
    ldy #(fntbl-ktbl)
loop:
    lda keycode
    cmp ktbl-1,y
    beq match
    dey
    bne loop
    bra nomatch
match:
    dey
    tya
    asl
    tax
    jmp (fntbl,x)
nomatch:
    jsr common_undo
    bcc :+
        bra noentry
    :
entry:
noentry:
end:
    rts
uptbl:    .byte $00,$00,$00,$01,$01,$02,$02,$03,$07,$07,$08,$09
downtbl:  .byte $01,$03,$06,$07,$07,$07,$07,$08,$0A,$0B,$0A,$0B
lefttbl:  .byte $00,$01,$01,$03,$03,$04,$05,$07,$08,$08,$0A,$0A
righttbl: .byte $00,$02,$02,$04,$05,$06,$06,$07,$09,$09,$0B,$0B
ktbl:
    ; this is the static keymapping
    ;     ent esc up  dn  lt  rt
    .byte $0D,$1B,$80,$81,$82,$83
fntbl:
    .word key_enter
    .word key_esc
    .word key_up
    .word key_dn
    .word key_lt
    .word key_rt
key_enter:
    lda InstState::edit_field_idx
    bne :+
        lda #<Dispatch::inst_name_entry_end
        sta TextField::callback
        lda #>Dispatch::inst_name_entry_end
        sta TextField::callback+1
        jmp Dispatch::inst_name_entry_start
    :
    rts
key_esc:
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw
    rts
key_up:
    ldy InstState::edit_field_idx
    lda uptbl,y
    sta InstState::edit_field_idx
    inc redraw
    rts
key_dn:
    ldy InstState::edit_field_idx
    lda downtbl,y
    sta InstState::edit_field_idx
    inc redraw
    rts
key_lt:
    ldy InstState::edit_field_idx
    lda lefttbl,y
    sta InstState::edit_field_idx
    inc redraw
    rts
key_rt:
    ldy InstState::edit_field_idx
    lda righttbl,y
    sta InstState::edit_field_idx
    inc redraw
    rts
.endproc
