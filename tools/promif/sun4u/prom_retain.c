/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_retain.c
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

#pragma ident	"@(#)prom_retain.c	1.1	00/07/22 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

/*
 * Allocate retained physical memory
 * Returns 0: Success; Non-zero: failure.
 * Returns *phys_hi, *phys_lo only if successful.
 */
int
prom_retain(char *id, size_t size, uint32_t align, u_longlong_t *physaddr)
{
	cell_t ci[11];
	int32_t rv;
	ihandle_t imemory = prom_memory_ihandle();

	if ((imemory == (ihandle_t)-1))
		return (-1);

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)5;			/* #argument cells */
	ci[2] = (cell_t)3;			/* #result cells */
	ci[3] = p1275_ptr2cell("SUNW,retain");	/* Arg1: Method name */
	ci[4] = p1275_ihandle2cell(imemory);	/* Arg2: memory ihandle */
	ci[5] = p1275_uint2cell(align);		/* Arg2: SA1: align */
	ci[6] = p1275_size2cell(size);		/* Arg3: SA2: size */
	ci[7] = p1275_ptr2cell(id);		/* Arg4: SA3: id name */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (rv);		/* Service "call-method" failed */
	if (ci[8] != 0)			/* Res1: catch-result */
		return (-1);		/* Method "SUNW,retain" failed */

	*physaddr = p1275_cells2ull(ci[9], ci[10]);
					/* Res3: base.hi, Res4: base.lo */
	return (0);
}
