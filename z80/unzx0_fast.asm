;
;  Speed-optimized ZX0 decompressor by spke (191 bytes)
;
;  ver.00 by spke (27/01-23/03/2021, 191 bytes)
;
;  Original ZX0 decompressors were written by Einar Saukas
;
;  This decompressor was written on the basis of "Standard" decompressor by
;  Einar Saukas and optimized for speed by spke. This decompressor is
;  about 5% faster than the "Turbo" decompressor, which is 128 bytes long.
;  It has about the same speed as the "Mega" decompressor, which occupies 412 bytes.
;  
;  The decompressor uses AF, AF', BC, DE, HL and IX and relies upon self-modified code.
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

		MACRO	RELOAD_BITS
			ld a,(hl) : inc hl : rla
		ENDM

		MACRO	INLINE_READ_GAMMA
.ReadGammaBits		add a : rl c : add a : jr nc,.ReadGammaBits
		ENDM

@DecompressZX0:		ld ix,CopyMatch1
			ld bc,#FFFF : ld (PrevOffset),bc				; default offset is -1
			inc bc : ld a,#80 : jr RunOfLiterals				; BC is assumed to contains 0 most of the time
			
ShorterOffsets			; 7-bit offsets allow additional optimizations,
				; based on the facts that C==0 and AF' has C ON!
				ld (ix+PrevOffset+1-CopyMatch1),#FF			; the top byte of the offset is always #FF
				exa : ld a,(hl) : inc hl
				rra : ld (PrevOffset),a					; note that AF' always has flag C ON

			jr nc,LongerMatch

CopyMatch2			; the case of matches with len=2
				exa : ld c,2

CopyMatch1			; the faster match copying code
				push hl							; preserve source
PrevOffset			EQU $+1 : ld hl,#FFFF					; restore offset (default offset is -1)
				add hl,de						; HL = dest - offset
				ldir
				pop hl							; restore source

			; after a match you can have either
			; 0 + <elias length> = run of literals, or
			; 1 + <elias offset msb> + [7-bits of offset lsb + 1-bit of length] + <elias length> = another match
AfterMatch1		add a : jr nc,RunOfLiterals

UsualMatch:			; this is the case of usual match+offset
				add a : jr nc,LongerOffets : jr nz,ShorterOffsets	; NZ after NC == "confirmed C"
					RELOAD_BITS : jr c,ShorterOffsets

LongerOffets			inc c : INLINE_READ_GAMMA				; reading gamma requires C=1
				call z,ReloadReadGamma

ProcessOffset			exa : xor a : sub c
				ret z							; end-of-data marker (only checked for longer offsets)

				rra : ld (PrevOffset+1),a
				ld a,(hl) : inc hl
				rra : ld (PrevOffset),a

			; lowest bit is the first bit of the gamma code for length
			jr c,CopyMatch2

				; this wastes 1 t-state for longer matches far away,
				; but saves 4 t-states for longer nearby (seems to pay off in testing)
				ld c,b
LongerMatch			inc c
				; doing SCF here ensures that AF' has flag C ON and costs
				; cheaper than doing SCF in the ShortestOffsets branch
				scf : exa

				INLINE_READ_GAMMA
				call z,ReloadReadGamma
				inc bc

CopyMatch3			push hl						; preserve source
				ld hl,(PrevOffset)				; restore offset
				add hl,de					; HL = dest - offset
				; because BC>=3, we can do 2 x LDI safely
				ldi : ldi : ldir
				pop hl						; restore source

			; after a match you can have either
			; 0 + <elias length> = run of literals, or
			; 1 + <elias offset msb> + [7-bits of offset lsb + 1-bit of length] + <elias length> = another match
AfterMatch3		add a : jr c,UsualMatch

RunOfLiterals:			inc c : add a : jr nc,LongerRun : jr nz,CopyLiteral	; NZ after NC == "confirmed C"
					RELOAD_BITS : jr c,CopyLiteral

LongerRun			INLINE_READ_GAMMA : jr nz,CopyLiterals
					RELOAD_BITS
				call nc,ReadGammaAligned

CopyLiterals			ldi
CopyLiteral			ldir

			; after a literal run you can have either
			; 0 + <elias length> = match using a repeated offset, or
			; 1 + <elias offset msb> + [7-bits of offset lsb + 1-bit of length] + <elias length> = another match
			add a : jr c,UsualMatch

RepMatch:			inc c : add a : jr nc,LongerRepMatch : jr nz,CopyMatch1	; NZ after NC == "confirmed C"
					RELOAD_BITS : jr c,CopyMatch1

LongerRepMatch			INLINE_READ_GAMMA
				jp nz,CopyMatch1

				; this is a crafty equivalent of
				; CALL ReloadReadGamma : JP CopyMatch1
				push ix

;
;  the subroutine for reading the remainder of the partly read Elias gamma code.
;  it has two entry points: ReloadReadGamma first refills the bit reservoir in A,
;  while ReadGammaAligned assumes that the bit reservoir has just been refilled.

ReloadReadGamma:	RELOAD_BITS

ReadGammaAligned:	; this loop can be unrolled for a very minor increase in decompression speed
			; (we are talking about +0.2% for +8 bytes, i.e. not really recommended)

		;DEFINE	UNROLL_ME
		IFNDEF	UNROLL_ME
				DUP 2
				ret c
				add a : rl c
				add a
				EDUP
				jr nz,ReadGammaAligned
		ELSE
				DUP 4
				ret c
				add a : rl c
				add a
				EDUP
		ENDIF

ReloadBits		RELOAD_BITS

ReadingLongGamma		; this loop does not need unrolling,
				; as it does not get much use anyway
				ret c
				add a : rl c : rl b
				add a :	jr nz,ReadingLongGamma

			jr ReloadBits

