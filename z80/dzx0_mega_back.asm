; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Mega" version (246 bytes, 40% faster) - BACKWARDS VARIANT
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_mega:
        ld      bc, 1                   ; preserve default offset 1
        push    bc
        ld      a, $80
dzx0mb_literals:
        call    dzx0mb_elias            ; obtain length
        lddr                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0mb_new_offset
        call    dzx0mb_elias            ; obtain length
dzx0mb_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        lddr                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0mb_literals
dzx0mb_new_offset:
        pop     bc                      ; discard last offset
        call    dzx0mb_elias            ; obtain offset MSB
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
        call    dzx0mb_elias_backtrack  ; obtain length
        inc     bc
        jp      dzx0mb_copy
dzx0mb_elias:
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_backtrack
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_backtrack:
        ld      bc, 1
        ret     c
        add     a, a
        jp      c, dzx0mb_elias_value1
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_size2
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_size2:
        jp      c, dzx0mb_elias_value2
        add     a, a
        jp      c, dzx0mb_elias_value3
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_size4
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_size4:
        jp      c, dzx0mb_elias_value4
        add     a, a
        jr      c, dzx0mb_elias_value5
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_size6
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_size6:
        jr      c, dzx0mb_elias_value6
        add     a, a
        jr      c, dzx0mb_elias_value7
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_size8
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_size8:
        jr      c, dzx0mb_elias_value8
        add     a, a
        jr      c, dzx0mb_elias_value9
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_size10
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_size10:
        jr      c, dzx0mb_elias_value10
        add     a, a
        jr      c, dzx0mb_elias_value11
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_size12
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_size12:
        jr      c, dzx0mb_elias_value12
        add     a, a
        jr      c, dzx0mb_elias_value13
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_size14
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_size14:
        jr      c, dzx0mb_elias_value14
        add     a, a                    ; check next bit
        ld      b, c
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_value14
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_value14:
        rl      b
        add     a, a
dzx0mb_elias_value13:
        rl      b
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_value12
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_value12:
        rl      b
        add     a, a
dzx0mb_elias_value11:
        rl      b
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_value10
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_value10:
        rl      b
        add     a, a
dzx0mb_elias_value9:
        rl      b
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_value8
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_value8:
        rl      b
        add     a, a
        rl      c
dzx0mb_elias_value7:
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_value7b
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_value7b:
        rl      c
dzx0mb_elias_value6:
        add     a, a
        rl      c
dzx0mb_elias_value5:
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_value5b
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_value5b:
        rl      c
dzx0mb_elias_value4:
        add     a, a
        rl      c
dzx0mb_elias_value3:
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_value3b
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_value3b:
        rl      c
dzx0mb_elias_value2:
        add     a, a
        rl      c
dzx0mb_elias_value1:
        add     a, a                    ; check next bit
        jp      nz, dzx0mb_elias_value1b
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
dzx0mb_elias_value1b:
        rl      c
        ret
; -----------------------------------------------------------------------------
