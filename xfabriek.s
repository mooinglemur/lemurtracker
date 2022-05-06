
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
.include "grid.s"
.include "sequencer.s"
.include "instruments.s"
.include "undo.s"
.include "clipboard.s"
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
XF_DIM_FG_COLOR = $0F ; grey
XF_INST_FG_COLOR = $0D ; green
XF_VOL_FG_COLOR = $07 ; yellow
XF_EFFECT_FG_COLOR = $03 ; cyan

.segment "CODE"

redraw: .res 1 ; flag on when a redraw is necessary
xf_state: .res 1

XF_STATE_DUMP = 0 ; we end up here when we need to dump memory state to SD
XF_STATE_NEW_DIALOG = 1
XF_STATE_SAVE_DIALOG = 2
XF_STATE_LOAD_DIALOG = 3
XF_STATE_GRID = 4
;XF_STATE_PATTERN_EDITOR_ENTRY = 5
XF_STATE_SEQUENCER = 6
XF_STATE_INSTRUMENT_PSG = 7
XF_STATE_INSTRUMENT_FM = 8
XF_STATE_INSTRUMENT_PCM = 9
XF_STATE_PLAYBACK = 10

main:
    ; rom check
    lda x16::Kernal::VERSION
    bpl @versioncheck
    eor #$ff
    beq @detect_emu ; custom build, unable to detect
@versioncheck:
    cmp #39
    bcc @badversion
@detect_emu:
    ; detect emulator
    lda $9FBE
    cmp #$31
    bne @continue_startup ; not emulator

    lda $9FBF
    cmp #$36
    bne @continue_startup ; not emulator

    ; toggle emulator keys off
    lda #1
    sta $9FB7

    lda $9FB7
    cmp #1
    beq @continue_startup

    ; emulator detected, but we can't disable control keys
    ldx #0
@emumessageloop:
    lda @emumessage,x
    cmp #0
    beq @emumessagedone
    phx
    jsr x16::Kernal::CHROUT
    plx
    inx
    bra @emumessageloop
@emumessagedone:
    jsr x16::Kernal::CHRIN
    bra @continue_startup
@badversion:
    ldx #0
@versionmessageloop:
    lda @versionmessage,x
    cmp #0
    beq @versionmessagedone
    phx
    jsr x16::Kernal::CHROUT
    plx
    inx
    bra @versionmessageloop
@versionmessagedone:
    rts
@continue_startup:
    jsr xf_set_charset

    jsr xf_clear_screen

    jsr CustomChars::install

    lda #XF_STATE_GRID
    sta xf_state

    lda #64
    sta Grid::global_pattern_length

    lda #16
    sta Grid::long_hilight_interval
    lda #4
    sta Grid::short_hilight_interval

    jsr xf_irq::setup

    jsr Keyboard::setup_handler

    sec
    jsr x16::Kernal::SCREEN_MODE ; get current screen size (in 8px) into .X and .Y
    lda #1
    jsr x16::Kernal::MOUSE_CONFIG ; show the default mouse pointer

    lda #1
    sta Sequencer::base_bank

    lda #2
    sta Instruments::base_bank

    lda #6
    sta Undo::base_bank

    lda #$0A
    sta Clipboard::base_bank

    lda #$10
    sta Grid::base_bank

    lda #0
    sta Sequencer::max_row

    lda #95
    sta Sequencer::max_pattern

    lda #254
    sta Instruments::max_instrument

    inc redraw

    lda #1
    sta Grid::step

    lda #$00
    sta Undo::lookup_addr
    lda #$A0
    sta Undo::lookup_addr+1

    jsr Sequencer::init

; tmp vvv
    ldy #0
    jsr Instruments::set_lookup_addr
    ldy #0
    :
        lda @tempinst,y
        sta (Instruments::lookup_addr),y
        iny
        cpy #160
        bcc :-

        jmp @mainloop


@tempinst:
    .byte $01,"PSG Instrument "
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $02,"FM Instrument  "
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $03,"PCM Instrument "
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $04,"Layered Inst.  "
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $05,"MIDI Instrument"
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00



; tmp ^^^
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
    lda Function::op_dispatch_flag
    cmp #Function::OP_NOTE
    bne :+
        ; clear selection too
        stz Grid::selection_active

        stz Function::op_dispatch_flag
        lda Function::op_dispatch_operand
        stz Function::op_dispatch_operand
        jsr Function::note_entry
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_UNDO
    bne :+
        stz Function::op_dispatch_flag
        jsr Undo::undo
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_REDO
    bne :+
        stz Function::op_dispatch_flag
        jsr Undo::redo
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_BACKSPACE
    bne :+
        ; clear selection too
        stz Grid::selection_active
        stz Function::op_dispatch_flag
        jsr Function::backspace
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_INSERT
    bne :+
        ; clear selection too
        stz Grid::selection_active

        stz Function::op_dispatch_flag
        jsr Function::insert_cell
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_COPY
    bne :+
        stz Function::op_dispatch_flag
        jsr Function::copy

    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_DELETE
    bne :+
        stz Function::op_dispatch_flag
        jsr Function::delete_selection

    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_CUT
    bne :+
        stz Function::op_dispatch_flag
        jsr Function::copy
        jsr Function::delete_selection
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_PASTE
    bne :+
        stz Function::op_dispatch_flag
        lda Function::op_dispatch_operand
        stz Function::op_dispatch_operand
        jsr Function::paste
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_DEC_SEQ_CELL
    bne :+
        stz Function::op_dispatch_flag
        jsr Function::decrement_sequencer_cell
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_INC_SEQ_CELL
    bne :+
        stz Function::op_dispatch_flag
        jsr Function::increment_sequencer_cell
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_GRID_ENTRY
    bne :+
        stz Function::op_dispatch_flag
        lda Function::op_dispatch_operand
        stz Function::op_dispatch_operand
        jsr Function::grid_entry
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_INC_SEQ_MAX_ROW
    bne :+
        stz Function::op_dispatch_flag
        stz Function::op_dispatch_operand
        jsr Function::increment_sequencer_max_row
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_DELETE_SEQ
    bne :+
        stz Function::op_dispatch_flag
        stz Function::op_dispatch_operand
        jsr Function::delete_sequencer_row
    :

    lda Function::op_dispatch_flag
    cmp #Function::OP_SET_SEQ_CELL
    bne :+
        stz Function::op_dispatch_flag
        lda Function::op_dispatch_operand
        stz Function::op_dispatch_operand
        jsr Function::set_sequencer_cell
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

    lda #' '
    sta Vera::Reg::Data0
    lda Undo::undo_size+1
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    lda Undo::undo_size
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0


    lda #' '
    sta Vera::Reg::Data0
    lda Undo::redo_size+1
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    lda Undo::redo_size
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0


    lda #' '
    sta Vera::Reg::Data0
    lda Undo::current_bank_offset
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    lda Undo::lookup_addr+1
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    lda Undo::lookup_addr
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda #' '
    sta Vera::Reg::Data0
    lda Sequencer::mix
    jsr xf_byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    jmp @mainloop
@exit:
;	DO THIS WHEN WE'RE EXITING FOR REAL
    jsr xf_irq::teardown
    jsr xf_reset_charset
    rts
@emumessage:
    .byte 13,13
    .byte "!!! EMULATOR ENVIRONMENT DETECTED, BUT WE COULDN'T DISABLE THE EMULATOR'S   !!!",13
    .byte "!!! COMMAND KEYS. SOME CTRL SHORTCUTS MAY NOT WORK, BUT YOU CAN USE THE F10 !!!",13
    .byte "!!! MENU TO REACH THOSE TRACKER FUNCTIONS INSTEAD",13,13
    .byte "PRESS RETURN TO CONTINUE",0
@versionmessage:
    .byte 13,13
    .byte "ROM VERSION TOO OLD, MUST BE >=39",13,0
