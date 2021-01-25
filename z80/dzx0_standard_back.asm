; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Standard" version (79 bytes only) - BACKWARDS VARIANT
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_standard_back:
        ld      bc, 1                   ; preserve default offset 1
        push    bc
        dec     bc
        ld      a, $80
dzx0sb_literals:
        call    dzx0sb_elias            ; obtain length
        lddr                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0sb_new_offset
        call    dzx0sb_elias            ; obtain length
dzx0sb_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0sb_literals
dzx0sb_new_offset:
        inc     sp                      ; discard last offset
        inc     sp
        call    dzx0sb_elias_size       ; obtain offset MSB
        ret     nz                      ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        srl     b                       ; last offset bit becomes first length bit
        rr      c
        inc     bc
        push    bc                      ; preserve new offset
        ld      bc, $8000               ; obtain length
        call    dzx0sb_elias_backtrack
        inc     bc
        jr      dzx0sb_copy
dzx0sb_elias:
        scf                             ; Elias gamma coding
dzx0sb_elias_size:
        rr      b
        rr      c
        call    dzx0sb_next_bit
dzx0sb_elias_backtrack:
        jr      nc, dzx0sb_elias_size
dzx0sb_elias_value:
        call    nc, dzx0sb_next_bit
        rl      c
        rl      b
        jr      nc, dzx0sb_elias_value
        ret
dzx0sb_next_bit:
        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
        ret
; -----------------------------------------------------------------------------
