; -----------------------------------------------------------------------------
; ZXX decoder by Einar Saukas
; "Turbo" version (88 bytes, 25% faster) - BACKWARDS VARIANT
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------

dzxx_turbo_back:
        ld      bc, 1                   ; preserve default offset 1
        push    bc
        ld      a, $80
dzxxtb_literals:
        call    dzxxtb_elias            ; obtain length
        lddr                            ; copy literals
        add     a, a                    ; check next bit
        call    z, dzxxtb_load_bits     ; no more bits left?
        jr      c, dzxxtb_new_offset    ; copy from last offset or new offset?
        call    dzxxtb_elias            ; obtain length
dzxxtb_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; check next bit
        call    z, dzxxtb_load_bits     ; no more bits left?
        jr      nc, dzxxtb_literals     ; copy from literals or new offset?
dzxxtb_new_offset:
        pop     bc                      ; discard last offset
        call    dzxxtb_elias            ; obtain offset MSB
        inc     b
        dec     b
        ret     nz                      ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        inc     bc
        push    bc                      ; preserve new offset
        call    dzxxtb_elias            ; obtain length
        inc     bc
        jp      dzxxtb_copy
dzxxtb_elias:
        add     a, a                    ; check next bit
        call    z, dzxxtb_load_bits     ; no more bits left?
        ld      bc, 1
        ret     c
        scf
dzxxtb_elias_size:
        rr      b
        rr      c
        add     a, a                    ; check next bit
        call    z, dzxxtb_load_bits     ; no more bits left?
        jr      nc, dzxxtb_elias_size
        inc     c
dzxxtb_elias_value:
        add     a, a                    ; check next bit
        call    z, dzxxtb_load_bits     ; no more bits left?
        rl      c
        rl      b
        jr      nc, dzxxtb_elias_value
        ret
dzxxtb_load_bits:
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
        ret
; -----------------------------------------------------------------------------
