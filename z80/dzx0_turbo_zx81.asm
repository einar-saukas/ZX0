; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Turbo" version (91 bytes, 25% faster) - ZX81 VARIANT: USE PUSH/POP INSTEAD OF AF'
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_turbo_zx81:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        ld      a, $80
dzx0t1_literals:
        call    dzx0t1_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0t1_new_offset
        call    dzx0t1_elias             ; obtain length
dzx0t1_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0t1_literals
dzx0t1_new_offset:
        pop     bc                      ; discard last offset
        call    dzx0t1_elias             ; obtain offset MSB
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
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        ld      bc, $8000               ; obtain length
        call    dzx0t1_elias_backtrack
        inc     bc
        jp      dzx0t1_copy
dzx0t1_elias:
        add     a, a                    ; check next bit
        call    z, dzx0t1_load_bits      ; no more bits left?
dzx0t1_elias_backtrack:
        ld      bc, 1
        ret     c
        scf
dzx0t1_elias_size:
        rr      b
        rr      c
        add     a, a                    ; check next bit
        call    z, dzx0t1_load_bits      ; no more bits left?
        jr      nc, dzx0t1_elias_size
        inc     c
dzx0t1_elias_value:
        add     a, a                    ; check next bit
        call    z, dzx0t1_load_bits      ; no more bits left?
        rl      c
        rl      b
        jr      nc, dzx0t1_elias_value
        ret
dzx0t1_load_bits:
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
; -----------------------------------------------------------------------------
