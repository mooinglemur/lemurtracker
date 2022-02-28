;   Macros

.macro VERA_SET_ADDR addr, stride
   .ifnblank stride
      .if stride < 0
         lda #((^addr) | $08 | ((0-stride) << 4))
      .else
         lda #((^addr) | (stride << 4))
      .endif
   .else
      lda #(^addr) | $10
   .endif

   sta $9F22
   lda #(>addr)
   sta $9F21
   lda #(<addr)
   sta $9F20
.endmacro


