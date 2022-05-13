.proc increment_x
    jsr selection_start
    ldy GridState::x_position
    cpy #(GridState::NUM_CHANNELS - 1)
    bcc :+
        stz GridState::x_position
        bra end
    :
    inc GridState::x_position
end:
    jsr selection_continue
    inc redraw
    rts
.endproc
