; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas
; "Standard" version (81 bytes only) - ZX81 VARIANT: USE PUSH/POP INSTEAD OF AF'
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_standard_zx81:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        inc     bc
        ld      a, $80
dzx0s1_literals:
        call    dzx0s1_elias            ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0s1_new_offset
        call    dzx0s1_elias            ; obtain length
dzx0s1_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0s1_literals
dzx0s1_new_offset:
        inc     sp                      ; discard last offset
        inc     sp
        call    dzx0s1_elias_size       ; obtain offset MSB
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
        call    dzx0s1_elias_backtrack
        inc     bc
        jr      dzx0s1_copy
dzx0s1_elias:
        scf                             ; Elias gamma coding
dzx0s1_elias_size:
        rr      b
        rr      c
        call    dzx0s1_next_bit
dzx0s1_elias_backtrack:
        jr      nc, dzx0s1_elias_size
dzx0s1_elias_value:
        call    nc, dzx0s1_next_bit
        rl      c
        rl      b
        jr      nc, dzx0s1_elias_value
        ret
dzx0s1_next_bit:
        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
; -----------------------------------------------------------------------------
