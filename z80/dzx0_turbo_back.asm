; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Turbo" version (91 bytes, 25% faster) - BACKWARDS VARIANT
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_turbo_back:
        ld      bc, 1                   ; preserve default offset 1
        push    bc
        ld      a, $80
dzx0tb_literals:
        call    dzx0tb_elias            ; obtain length
        lddr                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0tb_new_offset
        call    dzx0tb_elias            ; obtain length
dzx0tb_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0tb_literals
dzx0tb_new_offset:
        pop     bc                      ; discard last offset
        call    dzx0tb_elias            ; obtain offset MSB
        inc     b
        dec     b
        ret     nz                      ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        push    bc                      ; preserve new offset
        call    dzx0tb_elias_backtrack  ; obtain length
        inc     bc
        jp      dzx0tb_copy
dzx0tb_elias:
        add     a, a                    ; check next bit
        jp      nz, dzx0tb_elias_backtrack ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0tb_elias_backtrack:
        ld      bc, 1
        ret     c
        scf
dzx0tb_elias_size:
        rr      b
        rr      c
        add     a, a                    ; check next bit
        jp      nz, dzx0tb_elias_size2  ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0tb_elias_size2:
        jr      nc, dzx0tb_elias_size
        inc     c
dzx0tb_elias_value:
        add     a, a                    ; check next bit
        jp      nz, dzx0tb_elias_value2 ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0tb_elias_value2:
        rl      c
        rl      b
        jr      nc, dzx0tb_elias_value
        ret
; -----------------------------------------------------------------------------
