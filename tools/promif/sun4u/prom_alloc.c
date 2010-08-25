/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_alloc.c
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

#pragma ident	"@(#)prom_alloc.c	1.1	00/07/22 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

/*
 * This allocator has OBP-like semantics associated with it.
 * Specifically, the alignment value specifies both a physical
 * and virtual alignment. If virthint is zero, a suitable virt
 * is chosen. In either case, align is not ignored.
 *
 * This routine returns NULL on failure.
 *
 * Memory allocated with prom_alloc can be freed with prom_free.
 *
 * The generic allocator is prom_malloc.
 *
 */

caddr_t
prom_alloc(caddr_t virthint, size_t size, uint32_t align)
{

	caddr_t virt = virthint;
	u_longlong_t physaddr;

	if (align == 0)
		align = (uint32_t)1;

	/*
	 * First, allocate or claim the virtual address space.
	 * In either case, after this code, "virt" is the chosen address.
	 */
	if (virthint == 0) {
		virt = prom_allocate_virt(align, size);
		if (virt == (caddr_t)-1)
			return ((caddr_t)0);
	} else {
		if (prom_claim_virt(size, virthint) == (caddr_t)-1)
			return ((caddr_t)0);
	}

	/*
	 * Next, allocate the physical address space, at the specified
	 * physical alignment (or 1 byte alignment, if none specified)
	 */

	if (prom_allocate_phys(size, align, &physaddr) == -1) {

		/*
		 * Request failed, free virtual address space and return.
		 */
		prom_free_virt(size, virt);
		return ((caddr_t)0);
	}

	/*
	 * Next, create a mapping from the physical to virtual address,
	 * using a default "mode".
	 */

	if (prom_map_phys(-1, size, virt, physaddr) == -1)  {

		/*
		 * The call failed; release the physical and virtual
		 * addresses allocated or claimed, and return.
		 */

		prom_free_virt(size, virt);
		prom_free_phys(size, physaddr);
		return ((caddr_t)0);
	}
	return (virt);
}

/*
 * This is the generic client interface to "claim" memory.
 * These two routines belong in the common directory.
 */
caddr_t
prom_malloc(caddr_t virt, size_t size, uint32_t align)
{
	cell_t ci[7];
	int32_t rv;

	ci[0] = p1275_ptr2cell("claim");	/* Service name */
	ci[1] = (cell_t)3;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ptr2cell(virt);		/* Arg1: virt */
	ci[4] = p1275_size2cell(size);		/* Arg2: size */
	ci[5] = p1275_uint2cell(align);		/* Arg3: align */

	rv = p1275_cif_handler(&ci);

	if (rv == 0)
		return ((caddr_t)p1275_cell2ptr(ci[6])); /* Res1: base */
	return ((caddr_t)-1);
}


void
prom_free(caddr_t virt, size_t size)
{
	cell_t ci[5];

	ci[0] = p1275_ptr2cell("release");	/* Service name */
	ci[1] = (cell_t)2;			/* #argument cells */
	ci[2] = (cell_t)0;			/* #result cells */
	ci[3] = p1275_ptr2cell(virt);		/* Arg1: virt */
	ci[4] = p1275_size2cell(size);		/* Arg2: size */

	(void) p1275_cif_handler(&ci);
}
