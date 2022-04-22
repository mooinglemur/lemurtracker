
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


.include "x16.inc"
.include "vars.s"
.include "customchars.s"
.include "tracker_grid.s"
.include "sequencer.s"
.include "instruments.s"
.include "function.s"
.include "util.s"
.include "irq.s"
.include "keyboard.s"



XF_BASE_BG_COLOR = $00 ; black
XF_AUDITION_BG_COLOR = $60 ; blue
XF_NOTE_ENTRY_BG_COLOR = $20 ; red
XF_CURSOR_BG_COLOR = $F0 ; light grey
XF_HILIGHT_BG_COLOR_1 = $B0 ; dark grey
XF_HILIGHT_BG_COLOR_2 = $C0 ; grey
XF_SELECTION_BG_COLOR = $50 ; green

XF_BASE_FG_COLOR = $01 ; white
XF_NOTE_FG_COLOR = $0D ; green
XF_INST_FG_COLOR = $03 ; cyan

.segment "CODE"


tracker_frame_x_offset: .res 1 ; in the frame editor, what voice (column) are we in
tracker_frame_y_offset: .res 1 ; in the frame editor, what row are we in?
tracker_frame_mix: .res 1 ; in the frame editor, what mix's patterns are we showing?
tracker_songno: .res 1 ; what song are we showing/playing
redraw: .res 1 ; flag on when a redraw is necessary
xf_state: .res 1

XF_STATE_DUMP = 0 ; we end up here when we need to dump memory state to SD
XF_STATE_NEW_DIALOG = 1
XF_STATE_SAVE_DIALOG = 2
XF_STATE_LOAD_DIALOG = 3
XF_STATE_PATTERN_EDITOR = 4
;XF_STATE_PATTERN_EDITOR_ENTRY = 5
XF_STATE_MIX_EDITOR = 6
XF_STATE_INSTRUMENT_PSG = 7
XF_STATE_INSTRUMENT_FM = 8
XF_STATE_INSTRUMENT_PCM = 9
XF_STATE_PLAYBACK = 10

main:
    jsr xf_set_charset

    jsr xf_clear_screen

    jsr CustomChars::install

    lda #XF_STATE_PATTERN_EDITOR
    sta xf_state

    lda #$7F
    sta Grid::global_frame_length

    jsr xf_irq::setup

    jsr Keyboard::setup_handler

    sec
    jsr x16::Kernal::SCREEN_MODE ; get current screen size (in 8px) into .X and .Y
    lda #1
    JSR x16::Kernal::MOUSE_CONFIG ; show the default mouse pointer

    lda #1
    sta Sequencer::base_bank

    lda #2
    sta Instruments::base_bank

    lda #6
    sta Grid::base_bank

    lda #127
    sta Sequencer::max_frame

    inc redraw

    lda #4
    sta Grid::step


;;;;; temp vvv
    lda Sequencer::base_bank
    sta x16::Reg::RAMBank

    lda #9
    sta xf_tmp1
    lda #$A0
    sta xf_tmp2
    lda #1
    sta (xf_tmp1)




;;;;; temp ^^^

    ; toggle emulator keys off
    lda #1
    sta $9FB7



@mainloop:

    lda redraw
    beq :+
        stz redraw
        jsr Sequencer::draw
        jsr Instruments::draw
        jsr Grid::draw
    :
    wai

    ; if we have a pending note entry to do
    lda Function::note_entry_dispatch_value
    cmp #$ff
    beq :+
        jsr Function::note_entry
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

    lda Keyboard::modkeys
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda #' '
    sta Vera::Reg::Data0
    lda Grid::selection_top_y
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda #' '
    sta Vera::Reg::Data0
    lda Grid::selection_bottom_y
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    jmp @mainloop
@exit:
;	DO THIS WHEN WE'RE EXITING FOR REAL
    jsr xf_irq::teardown
    jsr xf_reset_charset
    rts
