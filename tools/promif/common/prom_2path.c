/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_2path.c
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

#pragma ident	"@(#)prom_2path.c	1.1	00/07/22 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

static int32_t handle2path(char *svc, uint32_t handle, char *buf, uint32_t len);

int
prom_ihandle_to_path(ihandle_t instance, char *buf, uint32_t len)
{
	return (handle2path("instance-to-path", (uint32_t)instance, buf, len));
}

int
prom_phandle_to_path(phandle_t package, char *buf, uint32_t len)
{
	return (handle2path("package-to-path", (uint32_t)package, buf, len));
}

static int
handle2path(char *service, uint32_t handle, char *buf, uint32_t len)
{
	cell_t ci[7];
	int32_t rv;

	ci[0] = p1275_ptr2cell(service);	/* Service name */
	ci[1] = 3;				/* #argument cells */
	ci[2] = 1;				/* #return cells */
	ci[3] = p1275_uint2cell(handle);	/* Arg1: ihandle/phandle */
	ci[4] = p1275_ptr2cell(buf);		/* Arg2: Result buffer */
	ci[5] = p1275_uint2cell(len);		/* Arg3: Buffer len */
	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (-1);
	return (p1275_cell2int(ci[6]));		/* Res1: Actual length */
}
