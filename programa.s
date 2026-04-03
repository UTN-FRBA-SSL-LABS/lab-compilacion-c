	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 26, 0	sdk_version 26, 2
	.globl	_sumar                          ; -- Begin function sumar
	.p2align	2
_sumar:                                 ; @sumar
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #16
	.cfi_def_cfa_offset 16
	str	w0, [sp, #12]
	str	w1, [sp, #8]
	adrp	x9, _llamadas@PAGE
	ldr	w8, [x9, _llamadas@PAGEOFF]
	add	w8, w8, #1
	str	w8, [x9, _llamadas@PAGEOFF]
	ldr	w8, [sp, #12]
	ldr	w9, [sp, #8]
	add	w0, w8, w9
	add	sp, sp, #16
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #80
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	stur	wzr, [x29, #-4]
	fmov	d0, #5.00000000
	stur	d0, [x29, #-24]
	mov	x9, sp
	adrp	x8, l_.str.1@PAGE
	add	x8, x8, l_.str.1@PAGEOFF
	str	x8, [x9]
	adrp	x0, l_.str@PAGE
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
	mov	w0, #3                          ; =0x3
	mov	w1, #4                          ; =0x4
	bl	_sumar
	stur	w0, [x29, #-12]
	ldur	w8, [x29, #-12]
                                        ; kill: def $x8 killed $w8
	mov	x9, sp
	str	x8, [x9]
	adrp	x0, l_.str.2@PAGE
	add	x0, x0, l_.str.2@PAGEOFF
	bl	_printf
	mov	x9, sp
	mov	x8, #5                          ; =0x5
	str	x8, [x9]
	mov	x8, #25                         ; =0x19
	str	x8, [x9, #8]
	adrp	x0, l_.str.3@PAGE
	add	x0, x0, l_.str.3@PAGEOFF
	bl	_printf
	mov	x9, sp
	mov	x8, #12                         ; =0xc
	str	x8, [x9]
	adrp	x0, l_.str.4@PAGE
	add	x0, x0, l_.str.4@PAGEOFF
	bl	_printf
	bl	_imprimir_separador
	ldur	d0, [x29, #-24]
	str	d0, [sp, #32]                   ; 8-byte Folded Spill
	ldur	d0, [x29, #-24]
	bl	_area_circulo
	ldr	d1, [sp, #32]                   ; 8-byte Folded Reload
	mov	x8, sp
	str	d1, [x8]
	str	d0, [x8, #8]
	adrp	x0, l_.str.5@PAGE
	add	x0, x0, l_.str.5@PAGEOFF
	bl	_printf
	adrp	x0, l_.str.6@PAGE
	add	x0, x0, l_.str.6@PAGEOFF
	bl	_printf
	stur	wzr, [x29, #-8]
	b	LBB1_1
LBB1_1:                                 ; =>This Inner Loop Header: Depth=1
	ldur	w8, [x29, #-8]
	subs	w8, w8, #5
	b.gt	LBB1_4
	b	LBB1_2
LBB1_2:                                 ;   in Loop: Header=BB1_1 Depth=1
	ldur	w8, [x29, #-8]
                                        ; kill: def $x8 killed $w8
	str	x8, [sp, #24]                   ; 8-byte Folded Spill
	ldur	w0, [x29, #-8]
	bl	_factorial
	ldr	x8, [sp, #24]                   ; 8-byte Folded Reload
	mov	x9, sp
	str	x8, [x9]
                                        ; implicit-def: $x8
	mov	x8, x0
	str	x8, [x9, #8]
	adrp	x0, l_.str.7@PAGE
	add	x0, x0, l_.str.7@PAGEOFF
	bl	_printf
	b	LBB1_3
LBB1_3:                                 ;   in Loop: Header=BB1_1 Depth=1
	ldur	w8, [x29, #-8]
	add	w8, w8, #1
	stur	w8, [x29, #-8]
	b	LBB1_1
LBB1_4:
	bl	_imprimir_separador
	adrp	x8, _llamadas@PAGE
	ldr	w8, [x8, _llamadas@PAGEOFF]
                                        ; kill: def $x8 killed $w8
	mov	x9, sp
	str	x8, [x9]
	adrp	x0, l_.str.8@PAGE
	add	x0, x0, l_.str.8@PAGEOFF
	bl	_printf
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	add	sp, sp, #80
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_imprimir_separador             ; -- Begin function imprimir_separador
	.p2align	2
_imprimir_separador:                    ; @imprimir_separador
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	adrp	x0, l_.str.9@PAGE
	add	x0, x0, l_.str.9@PAGEOFF
	bl	_printf
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_llamadas                       ; @llamadas
.zerofill __DATA,__common,_llamadas,4,2
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"=== Laboratorio de Compilacion en C (v%s) ===\n\n"

l_.str.1:                               ; @.str.1
	.asciz	"1.0"

l_.str.2:                               ; @.str.2
	.asciz	"sumar(3, 4)       = %d\n"

l_.str.3:                               ; @.str.3
	.asciz	"CUADRADO(%d)      = %d\n"

l_.str.4:                               ; @.str.4
	.asciz	"MAX(7, 12)        = %d\n"

l_.str.5:                               ; @.str.5
	.asciz	"area_circulo(%.1f) = %.4f\n"

l_.str.6:                               ; @.str.6
	.asciz	"Factoriales:\n"

l_.str.7:                               ; @.str.7
	.asciz	"  %d! = %d\n"

l_.str.8:                               ; @.str.8
	.asciz	"Llamadas a sumar(): %d\n"

l_.str.9:                               ; @.str.9
	.asciz	"----------------------------------------\n"

.subsections_via_symbols
