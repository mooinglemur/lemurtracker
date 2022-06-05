.proc ym_wait
    nop
    :
        bit X16::Reg::YM2151::Data
        bmi :-

    rts
.endproc
