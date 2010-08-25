/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_mapin.c
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
 * id: @(#)prom_mapin.c 1.5 00/08/08
 * purpose:
 * copyright: Copyright 1995-2000, 2003 Sun Microsystems, Inc.
 * All Rights Reserved
 * Use is subject to license terms.
 */

#include <sys/promif.h>
#include <sys/promimpl.h>

void *
prom_mapin(ihandle_t instance, uint_t *adrs, uint_t adr_cells, uint_t size)
{
	cell_t ci[10];
	uint_t retval, num_args, result_cell, i;

	num_args = adr_cells + 3;
	result_cell = num_args + 3;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)num_args;		/* #argument cells */
	ci[2] = (cell_t)2;			/* #result cells */
	ci[3] = p1275_ptr2cell("map-in");	/* Arg1: method name */
	ci[4] = p1275_ihandle2cell(instance);	/* Arg2: dev-node ihandle */
	ci[5] = p1275_int2cell(size);		/* Arg3: size */

	for (i = 0; i < adr_cells; i++) {
		ci[i + 6] = p1275_int2cell(adrs[i]);
	}

	retval = p1275_cif_handler(&ci);

	if (retval != 0)
		return ((void *)-1);
	if (ci[result_cell] != 0)		/* Res1: Catch result */
		return ((void *)-1);

	return ((void *)ci[result_cell + 1]);	/* Res2: virt addr */

}
