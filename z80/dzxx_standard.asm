; -----------------------------------------------------------------------------
; ZXX decoder by Einar Saukas
; "Standard" version (79 bytes only)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzxx_standard:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        ld      a, $80
dzxxs_literals:
        call    dzxxs_elias             ; obtain length
        ldir                            ; copy literals
        call    dzxxs_next_bit          ; copy from last offset or new offset?
        jr      c, dzxxs_new_offset
        call    dzxxs_elias             ; obtain length
dzxxs_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        call    dzxxs_next_bit          ; copy from literals or new offset?
        jr      nc, dzxxs_literals
dzxxs_new_offset:
        pop     bc                      ; discard last offset
        call    dzxxs_elias_carry       ; obtain offset MSB
        ret     nz                      ; check end marker
        ex      af, af'                 ; adjust for negative offset
        xor     a
        sub     c
        ld      b, a
        ex      af, af'                 
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        push    bc                      ; preserve new offset
        call    dzxxs_elias_carry       ; obtain length
        inc     bc
        jr      dzxxs_copy
dzxxs_elias:
        scf                             ; Elias gamma coding
dzxxs_elias_carry:
        ld      bc, 0
dzxxs_elias_size:
        rr      b
        rr      c
        call    dzxxs_next_bit
        jr      nc, dzxxs_elias_size
dzxxs_elias_value:
        call    nc, dzxxs_next_bit
        rl      c
        rl      b
        jr      nc, dzxxs_elias_value
        ret
dzxxs_next_bit:
        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
; -----------------------------------------------------------------------------
