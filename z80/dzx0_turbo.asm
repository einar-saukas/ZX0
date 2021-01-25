; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Turbo" version (93 bytes, 25% faster)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_turbo:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        ld      a, $80
dzx0t_literals:
        call    dzx0t_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0t_new_offset
        call    dzx0t_elias             ; obtain length
dzx0t_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0t_literals
dzx0t_new_offset:
        pop     bc                      ; discard last offset
        call    dzx0t_elias             ; obtain offset MSB
        inc     b
        dec     b
        ret     nz                      ; check end marker
        ex      af, af'                 ; adjust for negative offset
        xor     a
        sub     c
        ld      b, a
        ex      af, af'
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        call    dzx0t_elias_backtrack   ; obtain length
        inc     bc
        jp      dzx0t_copy
dzx0t_elias:
        add     a, a                    ; check next bit
        jp      nz, dzx0t_elias_backtrack ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_elias_backtrack:
        ld      bc, 1
        ret     c
        scf
dzx0t_elias_size:
        rr      b
        rr      c
        add     a, a                    ; check next bit
        jp      nz, dzx0t_elias_size2   ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_elias_size2:
        jr      nc, dzx0t_elias_size
        inc     c
dzx0t_elias_value:
        add     a, a                    ; check next bit
        jp      nz, dzx0t_elias_value2  ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0t_elias_value2:
        rl      c
        rl      b
        jr      nc, dzx0t_elias_value
        ret
; -----------------------------------------------------------------------------
