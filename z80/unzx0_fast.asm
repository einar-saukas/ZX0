;
;  Speed-optimized ZX0 decompressor by spke (161+ bytes)
;
;  ver.00 by spke (21-25/01/2021, 161+ bytes)
;
;  Original ZX0 decompressors were written by Einar Saukas
;
;  This decompressor was written on the basis of "Standard" decompressor by
;  Einar Saukas and optimized for speed by spke. Depending on the combination of
;  compilation options below, it provides the following performance improvements
;  compared to the standard 249 byte "Mega" decompressor:
;
;  				AllowUsingIX-		AllowUsingIX+
;  AllowSelfmodifyingCode-	161 bytes, 7% faster	167 bytes, 8% faster
;  AllowSelfmodifyingCode+	166 bytes, 14% faster	169 bytes, 14% faster
;
;  The decompressor only uses AF, AF', BC, DE, HL and, optionally, IX.
;
;  The decompression is done in the standard way:
;
;  ld hl,FirstByteOfCompressedData
;  ld de,FirstByteOfMemoryForDecompressedData
;  call DecompressZX0
;
;  Of course, ZX0 compression algorithms are (c) 2021 Einar Saukas,
;  see https://github.com/einar-saukas/ZX0 for more information
;
;  Drop me an email if you have any comments/ideas/suggestions: zxintrospec@gmail.com
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.

;	DEFINE	AllowSelfmodifyingCode
;	DEFINE	AllowUsingIX

		MACRO	SLOW_GET_BIT
			call ReadOneBit
		ENDM

		MACRO	GET_BIT
			add a : call z,ReloadByte
		ENDM

		MACRO	FASTER_GET_BIT
			add a : jp nz,1f
				ld a,(hl) : inc hl : rla
1
		ENDM


@DecompressZX0:		ld bc,#FFFF					; default offset is -1
	IFNDEF	AllowSelfmodifyingCode
		IFDEF	AllowUsingIX
			ld ix,0 : add ix,sp
		ENDIF
			push bc
	ELSE
		IFDEF	AllowUsingIX
			ld ix,CopyMatch
		ENDIF
			ld (PrevOffset),bc
	ENDIF
			inc bc : inc c					; BC must contain 1 most of the time
			ld a,#80 : jr RunOfLiterals

UsualMatch:
	IFNDEF	AllowSelfmodifyingCode
		IFDEF	AllowUsingIX
			ld sp,ix
		ELSE
			inc sp : inc sp					; discard last offset
		ENDIF
	ENDIF
			FASTER_GET_BIT : call nc,ReadEliasGamma
			dec b : ret z					; end-of-data

			exa : xor a : sub c
			ld c,(hl) : inc hl
			rra : ld b,a : rr c				; lowest bit is the first bit of gamma code for length

	IFNDEF	AllowSelfmodifyingCode
        		push bc						; preserve new offset
	ELSE
			ld (PrevOffset),bc
	ENDIF
			ld bc,2 : jr c,MatchLength2
				dec c : exa
				call ReadEliasGamma
				inc bc : db #FE				; #FE = CP .. (this is the quickest way to skip EXA below)
MatchLength2		exa

	IFNDEF	AllowSelfmodifyingCode
CopyMatch		ex (sp),hl					; preserve source, restore offset
        		push hl						; preserve offset
			add hl,de
			ldir : inc c
			pop hl						; restore offset
			ex (sp),hl					; preserve offset, restore source
	ELSE
CopyMatch		push hl						; preserve source
PrevOffset		EQU $+1 : ld hl,#FFFF				; restore offset (default offset is -1)
			add hl,de
			ldir : inc c
			pop hl						; restore source
	ENDIF

			; after a match you can have either
			; 0 + <elias length> = run of literals, or
			; 1 + <elias offset msb> + [7-bits of offset lsb + 1-bit of length] + <elias length> = another match
			add a : jr c,UsualMatch

RunOfLiterals:		FASTER_GET_BIT : call nc,ReadEliasGamma
			ldir : inc c

			; after a literal run you can have either
			; 0 + <elias length> = match using a repeated offset, or
			; 1 + <elias offset msb> + [7-bits of offset lsb + 1-bit of length] + <elias length> = another match
			add a : jr c,UsualMatch

RepMatch:		; flaz NZ after NC is synonymous with "confirmed C"
			add a : jr nc,LongerRepMatch : jr nz,CopyMatch
				ld a,(hl) : inc hl : rla
LongerRepMatch		call nc,ReadEliasGamma
	IFNDEF	AllowSelfmodifyingCode
			jp CopyMatch
	ELSE
		IFDEF	AllowUsingIX
			jp (ix)
		ELSE
			jp CopyMatch
		ENDIF
	ENDIF

;
;  standard elias gamma codes are defined as follows:
;  1 -> 1, 01x -> 1x, 001xx -> 1xx, etc
;
;  this routine is only called when the first bit is already guaranteed
;  to be zero, while BC is guaranteed to be 1. the partial unrolling ensures
;  that shorter codes are read using substantially streamlined code paths

ReadEliasGamma:		add a : jr c,EliasCode01
				FASTER_GET_BIT : jr c,EliasCode001
					add a : jr c,EliasCode0001
						GET_BIT : jr c,EliasCode00001

						ld bc,#0800
.CodeLengthLoop					rr b : rr c
						SLOW_GET_BIT : jr nc,.CodeLengthLoop

.CodeValueLoop					call nc,ReadOneBit : rl c : rl b
						jr nc,.CodeValueLoop
						ret

EliasCode00001					add a : rl c
EliasCode0001				GET_BIT : rl c
EliasCode001			add a : rl c
EliasCode01		add a : jr z,ReloadByte1
			rl c : ret

ReloadByte1		ld a,(hl) : inc hl : rla
			rl c : ret


;
;  standard routines for reading the bitstream

ReadOneBit:		add a : ret nz
ReloadByte:		ld a,(hl) : inc hl : rla : ret
