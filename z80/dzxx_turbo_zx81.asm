; -----------------------------------------------------------------------------
; ZXX decoder by Einar Saukas
; "Turbo" version (90 bytes, 25% faster) - ZX81 VARIANT: USE PUSH/POP INSTEAD OF AF'
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzxx_turbo_zx81:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        ld      a, $80
dzxxt1_literals:
        call    dzxxt1_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; check next bit
        call    z, dzxxt1_load_bits      ; no more bits left?
        jr      c, dzxxt1_new_offset     ; copy from last offset or new offset?
        call    dzxxt1_elias             ; obtain length
dzxxt1_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; check next bit
        call    z, dzxxt1_load_bits      ; no more bits left?
        jr      nc, dzxxt1_literals      ; copy from literals or new offset?
dzxxt1_new_offset:
        pop     bc                      ; discard last offset
        call    dzxxt1_elias             ; obtain offset MSB
        inc     b
        dec     b
        ret     nz                      ; check end marker
        push    af                      ; adjust for negative offset
        xor     a
        sub     c
        ld      b, a
        pop     af
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        push    bc                      ; preserve new offset
        call    dzxxt1_elias             ; obtain length
        inc     bc
        jp      dzxxt1_copy
dzxxt1_elias:
        add     a, a                    ; check next bit
        call    z, dzxxt1_load_bits      ; no more bits left?
        ld      bc, 1
        ret     c
        scf
dzxxt1_elias_size:
        rr      b
        rr      c
        add     a, a                    ; check next bit
        call    z, dzxxt1_load_bits      ; no more bits left?
        jr      nc, dzxxt1_elias_size
        inc     c
dzxxt1_elias_value:
        add     a, a                    ; check next bit
        call    z, dzxxt1_load_bits      ; no more bits left?
        rl      c
        rl      b
        jr      nc, dzxxt1_elias_value
        ret
dzxxt1_load_bits:
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
; -----------------------------------------------------------------------------
