/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_mem.c
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
 * Copyright (c) 2000-2003 Sun Microsystems, Inc.
 * All rights reserved.
 * Use is subject to license terms.
 */

#pragma ident	"@(#)prom_mem.c	1.1	00/08/07 SMI"

/*
 * This file contains platform-dependent memory support routines,
 * suitable for memory methods with 2-cell physical addresses.
 * Use of these routines makes the caller platform-dependent,
 * since the caller assumes knowledge of the physical layout of
 * the machines address space.  Generic programs should use the
 * standard client interface memory allocators.
 */

#include <sys/promif.h>
#include <sys/promimpl.h>

ihandle_t
prom_memory_ihandle(void)
{
	static ihandle_t imemory;

	if (imemory != (ihandle_t)0)
		return (imemory);

	if (prom_getproplen(prom_chosennode(), "memory") != sizeof (ihandle_t))
		return (imemory = (ihandle_t)-1);

	(void) prom_getprop(prom_chosennode(), "memory", (caddr_t)(&imemory));
	imemory = (ihandle_t)prom_decode_int(imemory);
	return (imemory);
}

/*
 * Allocate physical memory, unmapped and possibly aligned.
 * Returns 0: Success; Non-zero: failure.
 * Returns *physaddr only if successful.
 *
 * This routine is suitable for platforms with 2-cell physical addresses
 * and a single size cell in the "memory" node.
 */
int
prom_allocate_phys(size_t size, uint32_t align, u_longlong_t *physaddr)
{
	cell_t ci[10];
	int32_t rv;
	ihandle_t imemory = prom_memory_ihandle();

	if ((imemory == (ihandle_t)-1))
		return (-1);

	if (align == 0)
		align = (uint32_t)1;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)3;			/* #result cells */
	ci[3] = p1275_ptr2cell("claim");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(imemory);	/* Arg2: memory ihandle */
	ci[5] = p1275_uint2cell(align);		/* Arg3: SA1: align */
	ci[6] = p1275_size2cell(size);		/* Arg4: SA2: size */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (rv);
	if (p1275_cell2int(ci[7]) != 0)		/* Res1: Catch result */
		return (-1);

	*physaddr = p1275_cells2ull(ci[8], ci[9]);
				/* Res2: SR1: phys.hi ... Res3: SR2: phys.lo */
	return (0);
}

/*
 * Claim a region of physical memory, unmapped.
 * Returns 0: Success; Non-zero: failure.
 *
 * This routine is suitable for platforms with 2-cell physical addresses
 * and a single size cell in the "memory" node.
 */
int
prom_claim_phys(size_t size, u_longlong_t physaddr)
{
	cell_t ci[10];
	int32_t rv;
	ihandle_t imemory = prom_memory_ihandle();

	if ((imemory == (ihandle_t)-1))
		return (-1);

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)6;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ptr2cell("claim");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(imemory);	/* Arg2: mmu ihandle */
	ci[5] = 0;				/* Arg3: SA1: align */
	ci[6] = p1275_size2cell(size);		/* Arg4: SA2: len */
	ci[7] = p1275_ull2cell_high(physaddr);	/* Arg5: SA3: phys.hi */
	ci[8] = p1275_ull2cell_low(physaddr);	/* Arg6: SA4: phys.lo */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (rv);
	if (p1275_cell2int(ci[9]) != 0)		/* Res1: Catch result */
		return (-1);

	return (0);
}

/*
 * Free physical memory (no unmapping is done).
 * This routine is suitable for platforms with 2-cell physical addresses
 * with a single size cell.
 */
void
prom_free_phys(size_t size, u_longlong_t physaddr)
{
	cell_t ci[8];
	ihandle_t imemory = prom_memory_ihandle();

	if ((imemory == (ihandle_t)-1))
		return;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)5;			/* #argument cells */
	ci[2] = (cell_t)0;			/* #return cells */
	ci[3] = p1275_ptr2cell("release");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(imemory);	/* Arg2: memory ihandle */
	ci[5] = p1275_size2cell(size);		/* Arg3: SA1: size */
	ci[6] = p1275_ull2cell_high(physaddr);	/* Arg4: SA2: phys.hi */
	ci[7] = p1275_ull2cell_low(physaddr);	/* Arg5: SA3: phys.lo */

	(void) p1275_cif_handler(&ci);
}
