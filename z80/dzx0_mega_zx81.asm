; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Mega" version (249 bytes, 40% faster) - ZX81 VARIANT: USE PUSH/POP INSTEAD OF AF'
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_mega_zx81:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        ld      a, $80
dzx0m1_literals:
        call    dzx0m1_elias            ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0m1_new_offset
        call    dzx0m1_elias            ; obtain length
dzx0m1_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0m1_literals
dzx0m1_new_offset:
        pop     bc                      ; discard last offset
        call    dzx0m1_elias            ; obtain offset MSB
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
        scf
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        call    dzx0m1_elias_backtrack  ; obtain length
        inc     bc
        jp      dzx0m1_copy
dzx0m1_elias:
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_backtrack
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_backtrack:
        ld      bc, 1
        ret     c
        add     a, a
        jp      c, dzx0m1_elias_value1
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_size2
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_size2:
        jp      c, dzx0m1_elias_value2
        add     a, a
        jp      c, dzx0m1_elias_value3
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_size4
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_size4:
        jp      c, dzx0m1_elias_value4
        add     a, a
        jr      c, dzx0m1_elias_value5
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_size6
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_size6:
        jr      c, dzx0m1_elias_value6
        add     a, a
        jr      c, dzx0m1_elias_value7
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_size8
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_size8:
        jr      c, dzx0m1_elias_value8
        add     a, a
        jr      c, dzx0m1_elias_value9
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_size10
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_size10:
        jr      c, dzx0m1_elias_value10
        add     a, a
        jr      c, dzx0m1_elias_value11
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_size12
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_size12:
        jr      c, dzx0m1_elias_value12
        add     a, a
        jr      c, dzx0m1_elias_value13
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_size14
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_size14:
        jr      c, dzx0m1_elias_value14
        add     a, a                    ; check next bit
        ld      b, c
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_value14
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_value14:
        rl      b
        add     a, a
dzx0m1_elias_value13:
        rl      b
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_value12
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_value12:
        rl      b
        add     a, a
dzx0m1_elias_value11:
        rl      b
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_value10
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_value10:
        rl      b
        add     a, a
dzx0m1_elias_value9:
        rl      b
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_value8
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_value8:
        rl      b
        add     a, a
        rl      c
dzx0m1_elias_value7:
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_value7b
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_value7b:
        rl      c
dzx0m1_elias_value6:
        add     a, a
        rl      c
dzx0m1_elias_value5:
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_value5b
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_value5b:
        rl      c
dzx0m1_elias_value4:
        add     a, a
        rl      c
dzx0m1_elias_value3:
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_value3b
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_value3b:
        rl      c
dzx0m1_elias_value2:
        add     a, a
        rl      c
dzx0m1_elias_value1:
        add     a, a                    ; check next bit
        jp      nz, dzx0m1_elias_value1b
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0m1_elias_value1b:
        rl      c
        ret
; -----------------------------------------------------------------------------
