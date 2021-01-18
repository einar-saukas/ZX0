; -----------------------------------------------------------------------------
; ZXX decoder by Einar Saukas
; "Standard" version (77 bytes only) - BACKWARDS VARIANT
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------

dzxx_standard_back:
        ld      bc, 1                   ; preserve default offset 1
        push    bc
        ld      a, $80
dzxxsb_literals:
        call    dzxxsb_elias            ; obtain length
        lddr                            ; copy literals
        call    dzxxsb_next_bit         ; copy from last offset or new offset?
        jr      c, dzxxsb_new_offset
        call    dzxxsb_elias            ; obtain length
dzxxsb_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        call    dzxxsb_next_bit         ; copy from literals or new offset?
        jr      nc, dzxxsb_literals
dzxxsb_new_offset:
        pop     bc                      ; discard last offset
        call    dzxxsb_elias_carry      ; obtain offset MSB
        ret     nz                      ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        inc     bc
        push    bc                      ; preserve new offset
        call    dzxxsb_elias_carry      ; obtain length
        inc     bc
        jr      dzxxsb_copy
dzxxsb_elias:
        scf                             ; Elias gamma coding
dzxxsb_elias_carry:
        ld      bc, 0
dzxxsb_elias_size:
        rr      b
        rr      c
        call    dzxxsb_next_bit
dzxxsb_elias_backtrack:
        jr      nc, dzxxsb_elias_size
dzxxsb_elias_value:
        call    nc, dzxxsb_next_bit
        rl      c
        rl      b
        jr      nc, dzxxsb_elias_value
        ret
dzxxsb_next_bit:
        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
        ret
; -----------------------------------------------------------------------------
