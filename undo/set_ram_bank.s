set_ram_bank:
    lda base_bank
    clc
    adc current_bank_offset
    sta x16::Reg::RAMBank
    rts
