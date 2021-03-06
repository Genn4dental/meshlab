/*********************************************************************/
/*                                                                   */
/*             Optimized BLAS libraries                              */
/*                     By Kazushige Goto <kgoto@tacc.utexas.edu>     */
/*                                                                   */
/* Copyright (c) The University of Texas, 2009. All rights reserved. */
/* UNIVERSITY EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES CONCERNING  */
/* THIS SOFTWARE AND DOCUMENTATION, INCLUDING ANY WARRANTIES OF      */
/* MERCHANTABILITY, FITNESS FOR ANY PARTICULAR PURPOSE,              */
/* NON-INFRINGEMENT AND WARRANTIES OF PERFORMANCE, AND ANY WARRANTY  */
/* THAT MIGHT OTHERWISE ARISE FROM COURSE OF DEALING OR USAGE OF     */
/* TRADE. NO WARRANTY IS EITHER EXPRESS OR IMPLIED WITH RESPECT TO   */
/* THE USE OF THE SOFTWARE OR DOCUMENTATION.                         */
/* Under no circumstances shall University be liable for incidental, */
/* special, indirect, direct or consequential damages or loss of     */
/* profits, interruption of business, or related expenses which may  */
/* arise from use of Software or Documentation, including but not    */
/* limited to those resulting from defects in Software and/or        */
/* Documentation, or loss or inaccuracy of data of any kind.         */
/*********************************************************************/

#define ASSEMBLER
#include "common.h"

#define STACK	12
#define ARGS	 0
	
#define STACK_M		 4 + STACK + ARGS(%esp)
#define STACK_X		 8 + STACK + ARGS(%esp)
#define STACK_INCX	12 + STACK + ARGS(%esp)
#define STACK_Y		16 + STACK + ARGS(%esp)
#define STACK_INCY	20 + STACK + ARGS(%esp)

#define M	%ebx
#define X	%esi
#define INCX	%ecx
#define Y	%edi
#define INCY	%edx

#define xmm8  xmm0
#define xmm9  xmm1
#define xmm10 xmm2
#define xmm11 xmm3
#define xmm12 xmm4
#define xmm13 xmm5
#define xmm14 xmm6
#define xmm15 xmm7

#include "l1param.h"

#ifdef OPTERON
#define LOAD(OFFSET, ADDR, REG)		xorps	REG, REG; addpd	OFFSET(ADDR), REG
#else
#define LOAD(OFFSET, ADDR, REG)		movaps	OFFSET(ADDR), REG
#endif

	PROLOGUE
	PROFCODE

	pushl	%edi
	pushl	%esi
	pushl	%ebx

	movl	STACK_M,     M
	movl	STACK_X,     X
	movl	STACK_INCX,  INCX
	movl	STACK_Y,     Y
	movl	STACK_INCY,  INCY

	sall	$ZBASE_SHIFT, INCX
	sall	$ZBASE_SHIFT, INCY

	cmpl	$2 * SIZE, INCX
	jne	.L50
	cmpl	$2 * SIZE, INCY
	jne	.L50

	addl	M, M

#ifdef ALIGNED_ACCESS
	testl	$SIZE, Y
#else
	testl	$SIZE, X
#endif
	je	.L10

	movsd	(X), %xmm0
	movsd	%xmm0, (Y)
	addl	$1 * SIZE, X
	addl	$1 * SIZE, Y
	decl	M
	jle	.L19
	ALIGN_4

.L10:
	subl	$-16 * SIZE, X
	subl	$-16 * SIZE, Y

#ifdef ALIGNED_ACCESS
	testl	$SIZE, X
#else
	testl	$SIZE, Y
#endif
	jne	.L20

	movl	M,  %eax
	sarl	$4, %eax
	jle	.L13

	movaps	-16 * SIZE(X), %xmm0
	movaps	-14 * SIZE(X), %xmm1
	movaps	-12 * SIZE(X), %xmm2
	movaps	-10 * SIZE(X), %xmm3
	movaps	 -8 * SIZE(X), %xmm4
	movaps	 -6 * SIZE(X), %xmm5
	movaps	 -4 * SIZE(X), %xmm6
	movaps	 -2 * SIZE(X), %xmm7

	decl	%eax
	jle .L12
	ALIGN_3

.L11:
#ifdef PREFETCHW
	PREFETCHW (PREFETCHSIZE +  0) - PREOFFSET(Y)
#endif

	movaps	%xmm0, -16 * SIZE(Y)
	LOAD( 0 * SIZE, X, %xmm0)
	movaps	%xmm1, -14 * SIZE(Y)
	LOAD( 2 * SIZE, X, %xmm1)

#ifdef PREFETCH
	PREFETCH (PREFETCHSIZE +  0) - PREOFFSET(X)
#endif

	movaps	%xmm2, -12 * SIZE(Y)
	LOAD( 4 * SIZE, X, %xmm2)
	movaps	%xmm3, -10 * SIZE(Y)
	LOAD( 6 * SIZE, X, %xmm3)

#if defined(PREFETCHW) && !defined(FETCH128)
	PREFETCHW (PREFETCHSIZE +  64) - PREOFFSET(Y)
#endif

	movaps	%xmm4, -8 * SIZE(Y)
	LOAD( 8 * SIZE, X, %xmm4)
	movaps	%xmm5, -6 * SIZE(Y)
	LOAD(10 * SIZE, X, %xmm5)

#if defined(PREFETCH) && !defined(FETCH128)
	PREFETCH (PREFETCHSIZE +  64) - PREOFFSET(X)
#endif

	movaps	%xmm6, -4 * SIZE(Y)
	LOAD(12 * SIZE, X, %xmm6)
	movaps	%xmm7, -2 * SIZE(Y)
	LOAD(14 * SIZE, X, %xmm7)

	subl	$-16 * SIZE, Y
	subl	$-16 * SIZE, X
	decl	%eax
	jg	.L11
	ALIGN_3

.L12:
	movaps	%xmm0, -16 * SIZE(Y)
	movaps	%xmm1, -14 * SIZE(Y)
	movaps	%xmm2, -12 * SIZE(Y)
	movaps	%xmm3, -10 * SIZE(Y)
	movaps	%xmm4,  -8 * SIZE(Y)
	movaps	%xmm5,  -6 * SIZE(Y)
	movaps	%xmm6,  -4 * SIZE(Y)
	movaps	%xmm7,  -2 * SIZE(Y)

	subl	$-16 * SIZE, Y
	subl	$-16 * SIZE, X
	ALIGN_3

.L13:
	testl	$8, M
	jle	.L14
	ALIGN_3

	movaps	-16 * SIZE(X), %xmm0
	movaps	-14 * SIZE(X), %xmm1
	movaps	-12 * SIZE(X), %xmm2
	movaps	-10 * SIZE(X), %xmm3

	movaps	%xmm0, -16 * SIZE(Y)
	movaps	%xmm1, -14 * SIZE(Y)
	movaps	%xmm2, -12 * SIZE(Y)
	movaps	%xmm3, -10 * SIZE(Y)

	addl	$8 * SIZE, X
	addl	$8 * SIZE, Y
	ALIGN_3

.L14:
	testl	$4, M
	jle	.L15
	ALIGN_3

	movaps	-16 * SIZE(X), %xmm0
	movaps	-14 * SIZE(X), %xmm1

	movaps	%xmm0, -16 * SIZE(Y)
	movaps	%xmm1, -14 * SIZE(Y)

	addl	$4 * SIZE, X
	addl	$4 * SIZE, Y
	ALIGN_3

.L15:
	testl	$2, M
	jle	.L16
	ALIGN_3

	movaps	-16 * SIZE(X), %xmm0
	movaps	%xmm0, -16 * SIZE(Y)

	addl	$2 * SIZE, X
	addl	$2 * SIZE, Y
	ALIGN_3

.L16:
	testl	$1, M
	jle	.L19
	ALIGN_3

	movsd	-16 * SIZE(X), %xmm0
	movsd	%xmm0, 	-16 * SIZE(Y)
	ALIGN_3

.L19:
	popl	%ebx
	popl	%esi
	popl	%edi
	ret
	ALIGN_3

.L20:
#ifdef ALIGNED_ACCESS

	movhps	-16 * SIZE(X), %xmm0

	movl	M,  %eax
	sarl	$4, %eax
	jle	.L23

	movaps	-15 * SIZE(X), %xmm1
	movaps	-13 * SIZE(X), %xmm2
	movaps	-11 * SIZE(X), %xmm3
	movaps	 -9 * SIZE(X), %xmm4
	movaps	 -7 * SIZE(X), %xmm5
	movaps	 -5 * SIZE(X), %xmm6
	movaps	 -3 * SIZE(X), %xmm7

	decl	%eax
	jle .L22
	ALIGN_4

.L21:
#ifdef PREFETCHW
	PREFETCHW (PREFETCHSIZE +  0) - PREOFFSET(Y)
#endif

	SHUFPD_1 %xmm1, %xmm0
	movaps	%xmm0, -16 * SIZE(Y)
	LOAD(-1 * SIZE, X, %xmm0)

	SHUFPD_1 %xmm2, %xmm1
	movaps	%xmm1, -14 * SIZE(Y)
	LOAD( 1 * SIZE, X, %xmm1)

#ifdef PREFETCH
	PREFETCH (PREFETCHSIZE +  0) - PREOFFSET(X)
#endif

	SHUFPD_1 %xmm3, %xmm2
	movaps	%xmm2, -12 * SIZE(Y)
	LOAD( 3 * SIZE, X, %xmm2)

	SHUFPD_1 %xmm4, %xmm3
	movaps	%xmm3, -10 * SIZE(Y)
	LOAD( 5 * SIZE, X, %xmm3)

#if defined(PREFETCHW) && !defined(FETCH128)
	PREFETCHW (PREFETCHSIZE +  64) - PREOFFSET(Y)
#endif

	SHUFPD_1 %xmm5, %xmm4
	movaps	%xmm4,  -8 * SIZE(Y)
	LOAD( 7 * SIZE, X, %xmm4)

	SHUFPD_1 %xmm6, %xmm5
	movaps	%xmm5, -6 * SIZE(Y)
	LOAD( 9 * SIZE, X, %xmm5)

#if defined(PREFETCH) && !defined(FETCH128)
	PREFETCH (PREFETCHSIZE +  64) - PREOFFSET(X)
#endif

	SHUFPD_1 %xmm7, %xmm6
	movaps	%xmm6, -4 * SIZE(Y)
	LOAD(11 * SIZE, X, %xmm6)

	SHUFPD_1 %xmm0, %xmm7
	movaps	%xmm7, -2 * SIZE(Y)
	LOAD(13 * SIZE, X, %xmm7)

	subl	$-16 * SIZE, X
	subl	$-16 * SIZE, Y
	decl	%eax
	jg	.L21
	ALIGN_3

.L22:
	SHUFPD_1 %xmm1, %xmm0
	movaps	%xmm0, -16 * SIZE(Y)
	LOAD(-1 * SIZE, X, %xmm0)

	SHUFPD_1 %xmm2, %xmm1
	movaps	%xmm1, -14 * SIZE(Y)

	SHUFPD_1 %xmm3, %xmm2
	movaps	%xmm2, -12 * SIZE(Y)
	SHUFPD_1 %xmm4, %xmm3
	movaps	%xmm3, -10 * SIZE(Y)

	SHUFPD_1 %xmm5, %xmm4
	movaps	%xmm4,  -8 * SIZE(Y)
	SHUFPD_1 %xmm6, %xmm5
	movaps	%xmm5,  -6 * SIZE(Y)

	SHUFPD_1 %xmm7, %xmm6
	movaps	%xmm6,  -4 * SIZE(Y)
	SHUFPD_1 %xmm0, %xmm7
	movaps	%xmm7,  -2 * SIZE(Y)

	subl	$-16 * SIZE, X
	subl	$-16 * SIZE, Y
	ALIGN_3

.L23:
	testl	$8, M
	jle	.L24
	ALIGN_3

	movaps	-15 * SIZE(X), %xmm1
	movaps	-13 * SIZE(X), %xmm2
	movaps	-11 * SIZE(X), %xmm3
	movaps	 -9 * SIZE(X), %xmm4

	SHUFPD_1 %xmm1, %xmm0
	movaps	%xmm0, -16 * SIZE(Y)

	SHUFPD_1 %xmm2, %xmm1
	movaps	%xmm1, -14 * SIZE(Y)

	SHUFPD_1 %xmm3, %xmm2
	movaps	%xmm2, -12 * SIZE(Y)

	SHUFPD_1 %xmm4, %xmm3
	movaps	%xmm3, -10 * SIZE(Y)

	movaps	%xmm4, %xmm0

	addl	$8 * SIZE, X
	addl	$8 * SIZE, Y
	ALIGN_3

.L24:
	testl	$4, M
	jle	.L25
	ALIGN_3

	movaps	-15 * SIZE(X), %xmm1
	movaps	-13 * SIZE(X), %xmm2

	SHUFPD_1 %xmm1, %xmm0
	SHUFPD_1 %xmm2, %xmm1

	movaps	%xmm0, -16 * SIZE(Y)
	movaps	%xmm1, -14 * SIZE(Y)
	movaps	%xmm2, %xmm0

	addl	$4 * SIZE, X
	addl	$4 * SIZE, Y
	ALIGN_3

.L25:
	testl	$2, M
	jle	.L26
	ALIGN_3

	movaps	-15 * SIZE(X), %xmm1
	SHUFPD_1 %xmm1, %xmm0

	movaps	%xmm0, -16 * SIZE(Y)

	addl	$2 * SIZE, X
	addl	$2 * SIZE, Y
	ALIGN_3

.L26:
	testl	$1, M
	jle	.L29
	ALIGN_3

	movsd	-16 * SIZE(X), %xmm0
	movsd	%xmm0, 	-16 * SIZE(Y)
	ALIGN_3

.L29:
	popl	%ebx
	popl	%esi
	popl	%edi
	ret
	ALIGN_3

#else

	movl	M,  %eax
	sarl	$4, %eax
	jle	.L23

	movaps	-16 * SIZE(X), %xmm0
	movaps	-14 * SIZE(X), %xmm1
	movaps	-12 * SIZE(X), %xmm2
	movaps	-10 * SIZE(X), %xmm3
	movaps	 -8 * SIZE(X), %xmm4
	movaps	 -6 * SIZE(X), %xmm5
	movaps	 -4 * SIZE(X), %xmm6
	movaps	 -2 * SIZE(X), %xmm7

	decl	%eax
	jle .L22
	ALIGN_3

.L21:
#ifdef PREFETCHW
	PREFETCHW (PREFETCHSIZE +  0) - PREOFFSET(Y)
#endif

	movlps	%xmm0, -16 * SIZE(Y)
	movhps	%xmm0, -15 * SIZE(Y)
	LOAD( 0 * SIZE, X, %xmm0)
	movlps	%xmm1, -14 * SIZE(Y)
	movhps	%xmm1, -13 * SIZE(Y)
	LOAD( 2 * SIZE, X, %xmm1)

#ifdef PREFETCH
	PREFETCH (PREFETCHSIZE +  0) - PREOFFSET(X)
#endif

	movlps	%xmm2, -12 * SIZE(Y)
	movhps	%xmm2, -11 * SIZE(Y)
	LOAD( 4 * SIZE, X, %xmm2)
	movlps	%xmm3, -10 * SIZE(Y)
	movhps	%xmm3,  -9 * SIZE(Y)
	LOAD( 6 * SIZE, X, %xmm3)

#if defined(PREFETCHW) && !defined(FETCH128)
	PREFETCHW (PREFETCHSIZE +  64) - PREOFFSET(Y)
#endif

	movlps	%xmm4,  -8 * SIZE(Y)
	movhps	%xmm4,  -7 * SIZE(Y)
	LOAD( 8 * SIZE, X, %xmm4)
	movlps	%xmm5,  -6 * SIZE(Y)
	movhps	%xmm5,  -5 * SIZE(Y)
	LOAD(10 * SIZE, X, %xmm5)

#if defined(PREFETCH) && !defined(FETCH128)
	PREFETCH (PREFETCHSIZE +  64) - PREOFFSET(X)
#endif

	movlps	%xmm6,  -4 * SIZE(Y)
	movhps	%xmm6,  -3 * SIZE(Y)
	LOAD(12 * SIZE, X, %xmm6)
	movlps	%xmm7,  -2 * SIZE(Y)
	movhps	%xmm7,  -1 * SIZE(Y)
	LOAD(14 * SIZE, X, %xmm7)

	subl	$-16 * SIZE, Y
	subl	$-16 * SIZE, X
	decl	%eax
	jg	.L21
	ALIGN_3

.L22:
	movlps	%xmm0, -16 * SIZE(Y)
	movhps	%xmm0, -15 * SIZE(Y)
	movlps	%xmm1, -14 * SIZE(Y)
	movhps	%xmm1, -13 * SIZE(Y)
	movlps	%xmm2, -12 * SIZE(Y)
	movhps	%xmm2, -11 * SIZE(Y)
	movlps	%xmm3, -10 * SIZE(Y)
	movhps	%xmm3,  -9 * SIZE(Y)
	movlps	%xmm4,  -8 * SIZE(Y)
	movhps	%xmm4,  -7 * SIZE(Y)
	movlps	%xmm5,  -6 * SIZE(Y)
	movhps	%xmm5,  -5 * SIZE(Y)
	movlps	%xmm6,  -4 * SIZE(Y)
	movhps	%xmm6,  -3 * SIZE(Y)
	movlps	%xmm7,  -2 * SIZE(Y)
	movhps	%xmm7,  -1 * SIZE(Y)

	subl	$-16 * SIZE, Y
	subl	$-16 * SIZE, X
	ALIGN_3

.L23:
	testl	$8, M
	jle	.L24
	ALIGN_3

	movaps	-16 * SIZE(X), %xmm0
	movlps	%xmm0, -16 * SIZE(Y)
	movhps	%xmm0, -15 * SIZE(Y)
	movaps	-14 * SIZE(X), %xmm1
	movlps	%xmm1, -14 * SIZE(Y)
	movhps	%xmm1, -13 * SIZE(Y)
	movaps	-12 * SIZE(X), %xmm2
	movlps	%xmm2, -12 * SIZE(Y)
	movhps	%xmm2, -11 * SIZE(Y)
	movaps	-10 * SIZE(X), %xmm3
	movlps	%xmm3, -10 * SIZE(Y)
	movhps	%xmm3,  -9 * SIZE(Y)

	addl	$8 * SIZE, X
	addl	$8 * SIZE, Y
	ALIGN_3

.L24:
	testl	$4, M
	jle	.L25
	ALIGN_3

	movaps	-16 * SIZE(X), %xmm0
	movlps	%xmm0, -16 * SIZE(Y)
	movhps	%xmm0, -15 * SIZE(Y)
	movaps	-14 * SIZE(X), %xmm1
	movlps	%xmm1, -14 * SIZE(Y)
	movhps	%xmm1, -13 * SIZE(Y)

	addl	$4 * SIZE, X
	addl	$4 * SIZE, Y
	ALIGN_3

.L25:
	testl	$2, M
	jle	.L26
	ALIGN_3

	movaps	-16 * SIZE(X), %xmm0
	movlps	%xmm0, -16 * SIZE(Y)
	movhps	%xmm0, -15 * SIZE(Y)

	addl	$2 * SIZE, X
	addl	$2 * SIZE, Y
	ALIGN_3

.L26:
	testl	$1, M
	jle	.L29
	ALIGN_3

	movsd	-16 * SIZE(X), %xmm0
	movsd	%xmm0, 	-16 * SIZE(Y)
	ALIGN_3

.L29:
	popl	%ebx
	popl	%esi
	popl	%edi
	ret
	ALIGN_3
#endif

.L50:
	movl	M,  %eax
	sarl	$2, %eax
	jle	.L55
	ALIGN_3

.L51:
	movsd	0 * SIZE(X), %xmm0
	movhps	1 * SIZE(X), %xmm0
	addl	INCX, X

	movsd	0 * SIZE(X), %xmm1
	movhps	1 * SIZE(X), %xmm1
	addl	INCX, X

	movsd	0 * SIZE(X), %xmm2
	movhps	1 * SIZE(X), %xmm2
	addl	INCX, X

	movsd	0 * SIZE(X), %xmm3
	movhps	1 * SIZE(X), %xmm3
	addl	INCX, X


	movlps	%xmm0, 0 * SIZE(Y)
	movhps	%xmm0, 1 * SIZE(Y)
	addl	INCY, Y

	movlps	%xmm1, 0 * SIZE(Y)
	movhps	%xmm1, 1 * SIZE(Y)
	addl	INCY, Y

	movlps	%xmm2, 0 * SIZE(Y)
	movhps	%xmm2, 1 * SIZE(Y)
	addl	INCY, Y

	movlps	%xmm3, 0 * SIZE(Y)
	movhps	%xmm3, 1 * SIZE(Y)
	addl	INCY, Y

	decl	%eax
	jg	.L51
	ALIGN_3

.L55:
	movl	M,  %eax
	andl	$3, %eax
	jle	.L57
	ALIGN_3

.L56:
	movsd	0 * SIZE(X), %xmm0
	movhps	1 * SIZE(X), %xmm0
	addl	INCX, X

	movlps	%xmm0, 0 * SIZE(Y)
	movhps	%xmm0, 1 * SIZE(Y)
	addl	INCY, Y

	decl	%eax
	jg	.L56
	ALIGN_3

.L57:
	popl	%ebx
	popl	%esi
	popl	%edi
	ret

	EPILOGUE
