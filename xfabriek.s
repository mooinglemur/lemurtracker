
; Xfabriek - started 2022-02-18
; by MooingLemur

; Music tracker for the Commander X16

; Let's start with something simple

; This is for the 65C02.  This assembler directive enables
; the use of 65C02-specific mnemonics.
; (PHX/PLX, PHY/PLY, BRA, ...)
.PC02


; Add the PRG header
.segment "HEADER"
.word $0801

.segment "CODE"
; Add a BASIC startline
.word entry-2
.byte $00,$00,$9e
.byte "2061"
.byte $00,$00,$00

; Entry point at $080d
entry:
    jmp main

.pushseg
.segment "ZEROPAGE"
xf_tmp1: .res 1
xf_tmp2: .res 1
xf_tmp3: .res 1
.popseg

;.include "cx16-concerto/concerto_synth/x16.asm"
.include "x16.inc"
.include "customchars.s"
concerto_use_timbres_from_file = 1
.define CONCERTO_TIMBRES_PATH "cx16-concerto/FACTORY.COB"
.include "cx16-concerto/concerto_synth/concerto_synth.asm"
.include "util.s"
.include "irq.s"
.include "tracker_grid.s"
.include "keyboard.s"


XF_BASE_BG_COLOR = $00 ; black
XF_AUDITION_BG_COLOR = $60 ; blue
XF_NOTE_ENTRY_BG_COLOR = $20 ; red
XF_CURSOR_BG_COLOR = $F0 ; light grey
XF_HILIGHT_BG_COLOR_1 = $B0 ; dark grey
XF_HILIGHT_BG_COLOR_2 = $C0 ; grey

XF_BASE_FG_COLOR = $01 ; white
XF_NOTE_FG_COLOR = $05 ; green
XF_INST_FG_COLOR = $03 ; cyan

.segment "CODE"


tracker_frame_x_offset: .res 1 ; in the frame editor, what voice (column) are we in
tracker_frame_y_offset: .res 1 ; in the frame editor, what row are we in?
tracker_frame_mix: .res 1 ; in the frame editor, what mix's patterns are we showing?
tracker_songno: .res 1 ; what song are we showing?
tracker_global_frame_length: .res 1 ; frame length for frames that don't end early.

xf_state: .res 1

XF_STATE_NEW_DIALOG = 1
XF_STATE_SAVE_DIALOG = 2
XF_STATE_LOAD_DIALOG = 3
XF_STATE_PATTERN_EDITOR_AUDITION = 4
XF_STATE_PATTERN_EDITOR_ENTRY = 5
XF_STATE_MIX_EDITOR = 6
XF_STATE_INSTRUMENT_PSG = 7
XF_STATE_INSTRUMENT_FM = 8
XF_STATE_INSTRUMENT_PCM = 9


XF_PATTERN_BANK = 16
XF_BASE_BANK = 1

main:
    jsr xf_set_charset

    jsr xf_clear_screen

    jsr xf_install_custom_chars

    lda #XF_STATE_NEW_DIALOG
    sta xf_state

    lda #$3F
    sta tracker_global_frame_length

    jsr xf_irq::setup
    jsr concerto_synth::initialize

    jsr Keyboard::setup_handler

@mainloop:
    jsr Grid::draw
    wai

    VERA_SET_ADDR ($0000+$1B000),2
    jsr x16::Kernal::GETIN
    pha

    beq :+
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    :

    VERA_SET_ADDR ($0010+$1B000),2
    lda Grid::cursor_position
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda Grid::x_position
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda Keyboard::scancode
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda Keyboard::scancode+1
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0


    pla
    cmp #$11 ; down
    bne :++
    ldy Grid::y_position
    cpy tracker_global_frame_length
    bcc :+
    stz Grid::y_position
    bra :++
    :
    inc Grid::y_position
    :
    cmp #$91 ; up
    bne :++
    ldy Grid::y_position
    bne :+
    ldy tracker_global_frame_length
    sty Grid::y_position
    bra :++

    :
    dec Grid::y_position
    :
    cmp #$9D ; left
    bne @endleft
    ldx Grid::cursor_position
    dex
    cpx #1
    bne :+
    dex
    :
    cpx #8
    bcc :+
    ldx #7
    dec Grid::x_position
    ldy Grid::x_position
    cpy #8
    bcc :+
    stx Grid::x_position
    :
    stx Grid::cursor_position

    @endleft:
    cmp #$1D ; right
    bne @endright
    ldx Grid::cursor_position
    inx
    cpx #1
    bne :+
    inx
    :
    cpx #8
    bcc :+
    ldx #0
    inc Grid::x_position
    ldy Grid::x_position
    cpy #8
    bcc :+
    stz Grid::x_position
    :
    stx Grid::cursor_position

    @endright:

    cmp #$51 ; Q
    bne :+
    ldy #1
    sty concerto_synth::note_channel
    ldy Grid::y_position
    sty concerto_synth::note_timbre
    ldy #50
    sty concerto_synth::note_pitch
    lda #63

    jsr concerto_synth::play_note
    :
    jmp @mainloop
@exit:
;	DO THIS WHEN WE'RE EXITING FOR REAL
    jsr xf_irq::teardown
    jsr xf_reset_charset
    rts
