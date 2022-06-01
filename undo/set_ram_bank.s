set_ram_bank:
    lda base_bank
    clc
    adc current_bank_offset
    sta X16::Reg::RAMBank
    rts
