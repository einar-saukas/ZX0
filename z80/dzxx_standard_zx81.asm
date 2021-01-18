; -----------------------------------------------------------------------------
; ZXX decoder by Einar Saukas
; "Standard" version (79 bytes only) - ZX81 VARIANT: USE PUSH/POP INSTEAD OF AF'
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzxx_standard_zx81:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        ld      a, $80
dzxxs1_literals:
        call    dzxxs1_elias             ; obtain length
        ldir                            ; copy literals
        call    dzxxs1_next_bit          ; copy from last offset or new offset?
        jr      c, dzxxs1_new_offset
        call    dzxxs1_elias             ; obtain length
dzxxs1_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        call    dzxxs1_next_bit          ; copy from literals or new offset?
        jr      nc, dzxxs1_literals
dzxxs1_new_offset:
        pop     bc                      ; discard last offset
        call    dzxxs1_elias_carry       ; obtain offset MSB
        ret     nz                      ; check end marker
        push    af                      ; adjust for negative offset
        xor     a
        sub     c
        ld      b, a
        pop     af
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        push    bc                      ; preserve new offset
        call    dzxxs1_elias_carry       ; obtain length
        inc     bc
        jr      dzxxs1_copy
dzxxs1_elias:
        scf                             ; Elias gamma coding
dzxxs1_elias_carry:
        ld      bc, 0
dzxxs1_elias_size:
        rr      b
        rr      c
        call    dzxxs1_next_bit
        jr      nc, dzxxs1_elias_size
dzxxs1_elias_value:
        call    nc, dzxxs1_next_bit
        rl      c
        rl      b
        jr      nc, dzxxs1_elias_value
        ret
dzxxs1_next_bit:
        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
; -----------------------------------------------------------------------------
