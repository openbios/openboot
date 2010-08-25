/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_mmu.c
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

#pragma ident	"@(#)prom_mmu.c	1.1	00/08/07 SMI"

/*
 * This file contains platform-dependent MMU support routines,
 * suitable for mmu methods with 2-cell physical addresses.
 * Use of these routines makes the caller platform-dependent,
 * since the caller assumes knowledge of the physical layout of
 * the machines address space.  Generic programs should use the
 * standard client interface memory allocators.
 */

#include <sys/promif.h>
#include <sys/promimpl.h>

ihandle_t
prom_mmu_ihandle(void)
{
	static ihandle_t immu;

	if (immu != (ihandle_t)0)
		return (immu);

	if (prom_getproplen(prom_chosennode(), "mmu") != sizeof (ihandle_t))
		return (immu = (ihandle_t)-1);

	(void) prom_getprop(prom_chosennode(), "mmu", (caddr_t)(&immu));
	immu = (ihandle_t)prom_decode_int(immu);
	return (immu);
}

/*
 * prom_map_phys:
 *
 * Create an MMU mapping for a given physical address to a given virtual
 * address. The given resources are assumed to be owned by the caller,
 * and are *not* removed from any free lists.
 *
 * This routine is suitable for mapping a 2-cell physical address.
 */

int
prom_map_phys(int32_t mode, size_t size, caddr_t virt, u_longlong_t physaddr)
{
	cell_t ci[11];
	int32_t rv;
	ihandle_t immu = prom_mmu_ihandle();

	if ((immu == (ihandle_t)-1))
		return (-1);

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)7;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ptr2cell("map");		/* Arg1: method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: mmu ihandle */
	ci[5] = p1275_int2cell(mode);		/* Arg3: SA1: mode */
	ci[6] = p1275_size2cell(size);		/* Arg4: SA2: size */
	ci[7] = p1275_ptr2cell(virt);		/* Arg5: SA3: virt */
	ci[8] = p1275_ull2cell_high(physaddr);	/* Arg6: SA4: phys.hi */
	ci[9] = p1275_ull2cell_low(physaddr);	/* Arg7: SA5: phys.low */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (-1);
	if (ci[10] != 0)			/* Res1: Catch result */
		return (-1);
	return (0);
}

void
prom_unmap_phys(size_t size, caddr_t virt)
{
	(void) prom_unmap_virt(size, virt);
}

/*
 * Allocate aligned or unaligned virtual address space, unmapped.
 */
caddr_t
prom_allocate_virt(uint32_t align, size_t size)
{
	cell_t ci[9];
	int32_t rv;
	ihandle_t immu = prom_mmu_ihandle();

	if ((immu == (ihandle_t)-1))
		return ((caddr_t)-1);

	if (align == 0)
		align = 1;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)2;			/* #result cells */
	ci[3] = p1275_ptr2cell("claim");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: mmu ihandle */
	ci[5] = p1275_uint2cell(align);		/* Arg3: SA1: align */
	ci[6] = p1275_size2cell(size);		/* Arg4: SA2: size */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return ((caddr_t)-1);
	if (ci[7] != 0)				/* Res1: Catch result */
		return ((caddr_t)-1);
	return (p1275_cell2ptr(ci[8]));		/* Res2: SR1: base */
}

/*
 * Claim a region of virtual address space, unmapped.
 */
caddr_t
prom_claim_virt(size_t size, caddr_t virt)
{
	cell_t ci[10];
	int32_t rv;
	ihandle_t immu = prom_mmu_ihandle();

	if ((immu == (ihandle_t)-1))
		return ((caddr_t)-1);

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)5;			/* #argument cells */
	ci[2] = (cell_t)2;			/* #result cells */
	ci[3] = p1275_ptr2cell("claim");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: mmu ihandle */
	ci[5] = (cell_t)0;			/* Arg3: align */
	ci[6] = p1275_size2cell(size);		/* Arg4: length */
	ci[7] = p1275_ptr2cell(virt);		/* Arg5: virt */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return ((caddr_t)-1);
	if (ci[8] != 0)				/* Res1: Catch result */
		return ((caddr_t)-1);
	return (p1275_cell2ptr(ci[9]));		/* Res2: base */
}

/*
 * Free virtual address resource (no unmapping is done).
 */
void
prom_free_virt(size_t size, caddr_t virt)
{
	cell_t ci[7];
	ihandle_t immu = prom_mmu_ihandle();

	if ((immu == (ihandle_t)-1))
		return;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)0;			/* #return cells */
	ci[3] = p1275_ptr2cell("release");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: mmu ihandle */
	ci[5] = p1275_size2cell(size);		/* Arg3: length */
	ci[6] = p1275_ptr2cell(virt);		/* Arg4: virt */

	(void) p1275_cif_handler(&ci);
}

/*
 * Un-map virtual address. Does not free underlying resources.
 */
void
prom_unmap_virt(size_t size, caddr_t virt)
{
	cell_t ci[7];
	ihandle_t immu = prom_mmu_ihandle();

	if ((immu == (ihandle_t)-1))
		return;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)0;			/* #result cells */
	ci[3] = p1275_ptr2cell("unmap");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: mmu ihandle */
	ci[5] = p1275_size2cell(size);		/* Arg3: SA1: size */
	ci[6] = p1275_ptr2cell(virt);		/* Arg4: SA2: virt */

	(void) p1275_cif_handler(&ci);
}

/*
 * Translate virtual address to physical address.
 * Returns 0: Success; Non-zero: failure.
 * Returns *phys_hi, *phys_lo and *mode only if successful.
 */
int
prom_translate_virt(caddr_t virt, int32_t *valid,
		u_longlong_t *physaddr, int32_t *mode)
{
	cell_t ci[11];
	int32_t rv;
	ihandle_t immu = prom_mmu_ihandle();

	*valid = 0;

	if ((immu == (ihandle_t)-1))
		return (-1);

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)3;			/* #argument cells */
	ci[2] = (cell_t)5;			/* #result cells */
	ci[3] = p1275_ptr2cell("translate");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: mmu ihandle */
	ci[5] = p1275_ptr2cell(virt);		/* Arg3: virt */
	ci[6] = 0;				/* Res1: catch-result */
	ci[7] = 0;				/* Res2: sr1: valid */

	rv = p1275_cif_handler(&ci);

	if (rv == -1)				/* Did the call fail ? */
		return (-1);
	if (ci[6] != 0)				/* Catch result */
		return (-1);

	if (p1275_cell2int(ci[7]) != -1)	/* Valid results ? */
		return (0);

	*mode = p1275_cell2int(ci[8]);		/* Res3: sr2: mode, if valid */
	*physaddr = p1275_cells2ull(ci[9], ci[10]);
				/* Res4: sr3: phys-hi ... Res5: sr4: phys-lo */
	*valid = -1;				/* Indicate valid result */
	return (0);
}

int
prom_modify_mapping(caddr_t virt, size_t size, int32_t mode)
{
	cell_t ci[8];
	int32_t rv;
	ihandle_t immu = prom_mmu_ihandle();

	if ((immu == (ihandle_t)-1))
		return (-1);

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)3;			/* #argument cells */
	ci[2] = (cell_t)0;			/* #result cells */
	ci[3] = p1275_ptr2cell("modify");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: immu handle */
	ci[5] = p1275_int2cell(mode);		/* Arg3: mode */
	ci[6] = p1275_size2cell(size);		/* Arg4: size */
	ci[7] = p1275_ptr2cell(virt);		/* Arg5: virt */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (-1);
	if (ci[8] != 0)				/* Res1: Catch result */
		return (-1);
	return (0);
}

/*
 * prom_itlb_load, prom_dtlb_load:
 *
 * Manage the TLB. Returns 0 if successful, -1 otherwise.
 * Flush the address in context zero mapped by tte_data and virt,
 * and load the {i,d} tlb entry index with tte_data and virt.
 */

int
prom_itlb_load(int32_t index, u_longlong_t tte_data, caddr_t virt)
{
	cell_t ci[9];
	int32_t rv;
	ihandle_t immu = prom_mmu_ihandle();

	if ((immu == (ihandle_t)-1))
		return (-1);

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)5;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ptr2cell("SUNW,itlb-load"); /* Arg1: method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: mmu ihandle */
	ci[5] = p1275_ptr2cell(virt);		/* Arg3: SA1: virt */
	ci[6] = (cell_t)tte_data;		/* Arg4: SA2: tte_data */
	ci[7] = p1275_int2cell(index);		/* Arg5: SA3: index */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (-1);
	if (ci[8] != 0)				/* Res1: Catch result */
		return (-1);
	return (0);
}

int
prom_dtlb_load(int32_t index, u_longlong_t tte_data, caddr_t virt)
{
	cell_t ci[9];
	int32_t rv;
	ihandle_t immu = prom_mmu_ihandle();

	if ((immu == (ihandle_t)-1))
		return (-1);

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)5;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ptr2cell("SUNW,dtlb-load"); /* Arg1: method name */
	ci[4] = p1275_ihandle2cell(immu);	/* Arg2: mmu ihandle */
	ci[5] = p1275_ptr2cell(virt);		/* Arg3: SA1: virt */
	ci[6] = (cell_t)tte_data;		/* Arg4: SA2: tte_data */
	ci[7] = p1275_int2cell(index);		/* Arg5: SA3: index */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (-1);
	if (ci[8] != 0)				/* Res1: Catch result */
		return (-1);
	return (0);
}
