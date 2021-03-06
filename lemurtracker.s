
; LemurTracker - started 2022-02-18
; originially known as xfabriek
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
zp_tmp1: .res 1
zp_tmp2: .res 1
zp_tmp3: .res 1
zp_tmp4: .res 1
.popseg

framecounter: .res 2

.include "githash.s"

.include "x16.inc"
.include "customchars.s"

.include "keyboardstate.s"
.include "gridstate.s"
.include "seqstate.s"
.include "inststate.s"
.include "playerstate.s"
.include "util.s"
.include "textfield.s"

.include "undo.s"
.include "grid.s"
.include "sequencer.s"
.include "instruments.s"
.include "clipboard.s"
.include "playerengine.s"

.include "dispatch.s"
.include "irq.s"
.include "keyboard.s"
.include "debugpanel.s"
.include "startup.s"


XF_BASE_BG_COLOR = $00 ; black
XF_AUDITION_BG_COLOR = $60 ; blue
XF_NOTE_ENTRY_BG_COLOR = $20 ; red
XF_CURSOR_BG_COLOR = $F0 ; light grey
XF_HILIGHT_BG_COLOR_1 = $B0 ; dark grey
XF_HILIGHT_BG_COLOR_2 = $C0 ; grey
XF_SELECTION_BG_COLOR = $50 ; green
XF_PLAYBACK_BG_COLOR = $80 ; orange?

XF_BASE_FG_COLOR = $01 ; white
XF_DIM_FG_COLOR = $0F ; grey
XF_INST_FG_COLOR = $0D ; green
XF_VOL_FG_COLOR = $07 ; yellow
XF_EFFECT_FG_COLOR = $03 ; cyan
XF_MUTED_FG_COLOR = $02 ; red

.segment "CODE"

redraw: .res 1 ; flag on when a redraw is necessary
xf_state: .res 1

XF_STATE_NOOP = 0
XF_STATE_EDITINST = 1
XF_STATE_PLAYBACK = 2
XF_STATE_PLAYBACK_START = 3
XF_STATE_GRID = 4
XF_STATE_TEXT = 5
XF_STATE_SEQUENCER = 6
XF_STATE_INSTRUMENTS = 7
XF_STATE_PLAYBACK_STOP = 8


main:
    jsr Startup::startup
    bcc :+
        rts ; exit on error
    :

mainloop:
    jsr DebugPanel::Func::draw

    lda xf_state
    beq check_dispatch ; no-op state means we're handing off between IRQ and main loop
    cmp #XF_STATE_TEXT
    bne check_editinst

    jsr TextField::draw
    wai
    bra mainloop

check_editinst:
    lda xf_state
    cmp #XF_STATE_EDITINST
    bne mainstates

    lda redraw
    beq check_dispatch
    stz redraw
    jsr Instruments::Func::draw
    jsr Instruments::Func::draw_edit
    bra check_dispatch

mainstates:
    lda redraw
    beq :+
        stz redraw
        jsr Sequencer::Func::draw
        jsr Instruments::Func::draw
        jsr Grid::Func::draw
    :
    wai

check_dispatch:
    ldy #$FF
    :
        iny
        lda dispatch_flags,y
        beq mainloop

        cmp Dispatch::flag
        bne :-

    tya
    asl
    tax

    jsr dispatch_function
    bra mainloop

dispatch_function:
    sei
    stz Dispatch::flag
    lda Dispatch::operand
    stz Dispatch::operand
    cli
    jmp (dispatch_functions,x)


do_grid_cut:
    jsr Clipboard::copy_grid_cells
    jmp Grid::Func::delete_selection



exit:
;	DO THIS WHEN WE'RE EXITING FOR REAL
    jsr IRQ::teardown
    jsr Util::reset_charset
    rts


dispatch_flags:
    .byte Dispatch::OP_NOTE
    .byte Dispatch::OP_UNDO
    .byte Dispatch::OP_REDO
    .byte Dispatch::OP_BACKSPACE

    .byte Dispatch::OP_INSERT
    .byte Dispatch::OP_COPY_GRID
    .byte Dispatch::OP_COPY_SEQ
    .byte Dispatch::OP_DELETE

    .byte Dispatch::OP_CUT
    .byte Dispatch::OP_PASTE_GRID
    .byte Dispatch::OP_PASTE_SEQ
    .byte Dispatch::OP_DEC_SEQ_CELL

    .byte Dispatch::OP_INC_SEQ_CELL
    .byte Dispatch::OP_GRID_ENTRY
    .byte Dispatch::OP_INC_SEQ_MAX_ROW
    .byte Dispatch::OP_DELETE_SEQ

    .byte Dispatch::OP_SET_SEQ_CELL
    .byte Dispatch::OP_INSERT_SEQ
    .byte Dispatch::OP_SEQ_ENTRY
    .byte Dispatch::OP_DELETE_INST

    .byte Dispatch::OP_NEW_PATTERN
    .byte Dispatch::OP_INST_SET_TYPE
    .byte Dispatch::OP_INST_NAME_ENTRY_START
    .byte Dispatch::OP_INST_NAME_ENTRY_END
    .byte 0
dispatch_functions:
    .word Grid::Func::note_entry
    .word Undo::undo
    .word Undo::redo
    .word Grid::Func::backspace

    .word Grid::Func::insert_cell
    .word Clipboard::copy_grid_cells
    .word Clipboard::copy_sequencer_rows
    .word Grid::Func::delete_selection

    .word do_grid_cut
    .word Clipboard::paste_cells
    .word Clipboard::paste_sequencer_rows
    .word Sequencer::Func::decrement_cell

    .word Sequencer::Func::increment_cell
    .word Grid::Func::entry
    .word Sequencer::Func::increment_max_row
    .word Sequencer::Func::delete_row

    .word Sequencer::Func::set_cell
    .word Sequencer::Func::insert_row
    .word Sequencer::Func::entry
    .word Instruments::Func::delete

    .word Sequencer::Func::new_pattern
    .word Instruments::Func::set_instrument_type
    .word Instruments::Func::name_entry_start
    .word Instruments::Func::name_entry_end
