/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: crt0.s
* 
* Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
* 
*  - Do no alter or remove copyright notices
* 
*  - Redistribution and use of this software in source and binary forms, with 
*    or without modification, are permitted provided that the following 
*    conditions are met: 
* 
*  - Redistribution of source code must retain the above copyright notice, 
*    this list of conditions and the following disclaimer.
* 
*  - Redistribution in binary form must reproduce the above copyright notice,
*    this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution. 
* 
*    Neither the name of Sun Microsystems, Inc. or the names of contributors 
* may be used to endorse or promote products derived from this software 
* without specific prior written permission. 
* 
*     This software is provided "AS IS," without a warranty of any kind. 
* ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
* INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
* PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
* MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
* ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
* DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
* OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
* FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
* DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
* ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
* SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
* 
* You acknowledge that this software is not designed, licensed or
* intended for use in the design, construction, operation or maintenance of
* any nuclear facility. 
* 
* ========== Copyright Header End ============================================
*/
/*
 * Copyright (c) 1986-1995, 2003 Sun Microsystems, Inc. All Rights Reserved
 * Use is subject to license terms.
 */

#pragma ident	"@(#)srt0.s	1.4	01/03/26 SMI"

/*
 * srt0.s - standalone startup code
 * Generate the code with a fake a.out header if INETBOOT is defined.
 * inetboot is loaded directly by the PROM, other booters are loaded via
 * a bootblk and don't need the fake a.out header.
 */

#include <sys/asm_linkage.h>
#include <sys/cpu.h>
#include <sys/privregs.h>
#include <sys/stack.h>

	.seg	".text"
	.align	8
	.global	end
	.global	edata
	.global	main


/*
 * The following variables are machine-dependent and are set in fiximp.
 * Space is allocated there.
 */
	.seg	".data"
	.align	8

_local_p1275cif:
	.word	0

#define STACK_SIZE	0x14000
	.skip	STACK_SIZE
.ebootstack:			! end (top) of boot stack

/*
 * The following variables are more or less machine-independent
 * (or are set outside of fiximp).
 */

	.seg	".text"
	.align	8
	.global	prom_exit_to_mon
	.type	prom_exit_to_mon, #function


! Each standalone program is responsible for its own stack. Our strategy
! is that each program which uses this runtime code creates a stack just
! below its relocation address. Previous windows may (and probably do)
! have frames allocated on the prior stack; leave them alone. Starting with
! this window, allocate our own stack frames for our windows. (Overflows
! or a window flush would then pass seamlessly from our stack to the old.)
! RESTRICTION: A program running at some relocation address must not exec
! another which will run at the very same address: the stacks would collide.
!
! Careful: don't touch %o4 until the save, since it contains the
! address of the IEEE 1275 SPARC v9 CIF handler (linkage to the prom).
!
!
! We cannot write to any symbols until we are relocated.
! Note that with the advent of 5.x boot, we no longer have to
! relocate ourselves, but this code is kept around cuz we *know*
! someone would scream if we did the obvious.
!


#ifndef	INETBOOT

!
! Enter here for all booters loaded by a bootblk program.
! Careful, do not lose value of the SPARC v9 P1275 CIF handler in %o4
! Setup temporary 32 bit stack at _start.
!
! NB: Until the common startup code, AM may not be set.
!

	ENTRY_NP(_start)
	set	_start - 0x10000, %o1
!	and	%o1, ~(STACK_ALIGN64-1), %o1
!	save	%o1, -SA(MINFRAME64), %sp	! %i4: 1275 sparcv9 CIF handler
        and	%o6, (STACK_ALIGN64-1), %o2
	add	%o1,  -SA(MINFRAME64), %o1
	save	%o1, %o2, %sp			! %i4: 1275 sparcv9 CIF handler
!	ta	0x7f
	!
	! zero the bss
	!
	sethi	%hi(edata), %o0			! Beginning of bss
	or	%o0, %lo(edata), %o0
	set	end, %i2
	call	bzero
	sub	%i2, %o0, %o1			! end - edata = size of bss

#endif !INETBOOT

!
! All booters end up here...
!

9:
#ifndef __sparcv9
	/*
	 *  Use our own 32 bit stack now. But, zero it first (do we have to?)
	 */
	set	.ebootstack, %o0
	set	STACK_SIZE, %o1
	sub	%o0, %o1, %o1
1:	dec	4, %o0
	st	%g0, [%o0]
	cmp	%o0, %o1
	bne	1b
	nop

	set	.ebootstack, %o0
	and	%o0, ~(STACK_ALIGN64-1), %o0
	sub	%o0, SA64(MINFRAME64), %sp

	/*
	 * Set the psr into a known state:
	 * Set AM, supervisor mode, interrupt level >= 13, traps enabled
	 */
	wrpr	%g0, 13, %pil
	wr      %g0, FPRS_FEF, %fprs
	wrpr	%g0, PSTATE_PEF+PSTATE_AM+PSTATE_PRIV+PSTATE_IE, %pstate
	nop; nop; nop
	sethi	%hi(_local_p1275cif), %o2
	st	%i4, [%o2 + %lo(_local_p1275cif)]
#else
	wrpr	%g0, 13, %pil
	wr      %g0, FPRS_FEF, %fprs
	wrpr	%g0, PSTATE_PEF+PSTATE_PRIV+PSTATE_IE, %pstate
	nop; nop; nop
	sethi	%hi(_local_p1275cif), %o2
	stx	%i4, [%o2 + %lo(_local_p1275cif)]
#endif

	mov	%g0, %o0
	call	prom_init		! prom-init(NULL, prom-cookie)
	mov	%i4, %o1		! SPARCV9/CIF 

	mov	%g0, %o0
	call	main			! main(0)
	mov	%g0, %o1		! 

	call	prom_exit_to_mon	! can't happen .. :-)
	nop
	SET_SIZE(_start)


/*
 * The interface for a 32-bit client program
 * calling the 64-bit romvec OBP.
 */

#if defined(lint)
#include <sys/promif.h>

/* ARGSUSED */
int
client_handler(void *cif_handler, cell_t **)
{}

#else	/* !lint */

	ENTRY_NP(client_handler)
	save	%sp, -SA64(MINFRAME64), %sp	! 32 bit frame, 64 bit sized
#ifndef __sparcv9
	mov	%i1, %o0
	rdpr	%pstate, %l1			! Get the present pstate value
	wrpr	%l1, PSTATE_AM, %pstate		! Set PSTATE_AM = 0
	jmpl	%i0, %o7			! Call cif handler
	sub	%sp, V9BIAS64, %sp		! delay; Now a 64 bit frame
	rdpr	%pstate, %l1			! Get the present pstate value
	wrpr	%l1, PSTATE_AM, %pstate		! Set PSTATE_AM = 1
#else
	mov	%i1, %o0
	jmpl	%i0, %o7			! Call cif handler
        nop
#endif
	ret					! Return result ...
	restore %o0, %g0, %o0			! delay; result in %o0

	SET_SIZE(client_handler)


	ENTRY_NP(set_intr)			! Set the interrupt level.
	rdpr	%pil, %o1			! Save existing intr level.
	wrpr	%o0, 0, %pil			! Write new intr level.
	retl					
	mov	%o1, %o0			! Return old intr level.

	SET_SIZE(set_intr)

#endif	/* !lint */
