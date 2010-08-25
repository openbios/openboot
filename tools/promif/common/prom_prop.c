/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_prop.c
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

#pragma ident	"@(#)prom_prop.c	1.1	00/08/07 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

int
prom_getproplen(phandle_t nodeid, caddr_t name)
{
	cell_t ci[6];

	ci[0] = p1275_ptr2cell("getproplen");	/* Service name */
	ci[1] = (cell_t)2;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #return cells */
	ci[3] = p1275_phandle2cell(nodeid);	/* Arg1: package */
	ci[4] = p1275_ptr2cell(name);		/* Arg2: Property name */
	ci[5] = (cell_t)-1;			/* Res1: Prime result */

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2int(ci[5]));		/* Res1: Property length */
}

int
prom_getprop(phandle_t nodeid, caddr_t name, caddr_t buf)
{
	int32_t len, rv;
	cell_t ci[8];

	/*
	 * This function assumes the buffer is large enough to
	 * hold the result, so we pass in the length of the
	 * property as the length of the buffer.
	 *
	 * Note that we ignore the "length" result of the service.
	 */

	if ((len = prom_getproplen(nodeid, name)) <= 0)
		return (len);

	ci[0] = p1275_ptr2cell("getprop");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)0;			/* #result cells */
	ci[3] = p1275_phandle2cell(nodeid);	/* Arg1: package */
	ci[4] = p1275_ptr2cell(name);		/* Arg2: property name */
	ci[5] = p1275_ptr2cell(buf);		/* Arg3: buffer address */
	ci[6] = len;				/* Arg4: buf len (assumed) */

	rv = p1275_cif_handler(&ci);

	if (rv != 0)
		return (-1);
	return (len);				/* Return known length */
}

int
prom_bounded_getprop(phandle_t nodeid, caddr_t name, caddr_t buf,
	int32_t buflen)
{
	cell_t ci[8];

	ci[0] = p1275_ptr2cell("getprop");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_phandle2cell(nodeid); /* Arg1: package */
	ci[4] = p1275_ptr2cell(name);		/* Arg2: property name */
	ci[5] = p1275_ptr2cell(buf);		/* Arg3: buffer address */
	ci[6] = p1275_int2cell(buflen);		/* Arg4: buffer length */
	ci[7] = (cell_t)-1;			/* Res1: Prime result */

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2int(ci[7]));		/* Res1: Returned length */
}

int
prom_nextprop(phandle_t nodeid, caddr_t previous, caddr_t next)
{
	cell_t ci[7];

	(void) prom_strcpy(next, "");	/* Prime result, in case call fails */

	ci[0] = p1275_ptr2cell("nextprop");	/* Service name */
	ci[1] = (cell_t)3;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_phandle2cell(nodeid); /* Arg1: phandle */
	ci[4] = p1275_ptr2cell(previous);	/* Arg2: addr of prev name */
	ci[5] = p1275_ptr2cell(next);		/* Arg3: addr of 32 byte buf */
	ci[6] = -1;

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2int(ci[6]));
}

int
prom_setprop(phandle_t nodeid, caddr_t name, caddr_t buf, int32_t buflen)
{
	cell_t ci[8];

	ci[0] = p1275_ptr2cell("setprop");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_phandle2cell(nodeid);	/* Arg1: phandle */
	ci[4] = p1275_ptr2cell(name);		/* Arg2: property name */
	ci[5] = p1275_ptr2cell(buf);		/* Arg3: New value ptr */
	ci[6] = p1275_int2cell(buflen);		/* Arg4: New value len */
	ci[7] = (cell_t)-1;			/* Res1: Prime result */

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2int(ci[7]));		/* Res1: Actual new size */
}

/*
 * prom_decode_composite_string:
 *
 * Returns successive strings in a composite string property.
 * A composite string property is a buffer containing one or more
 * NULL terminated strings contained within the length of the buffer.
 *
 * Always call with the base address and length of the property buffer.
 * On the first call, call with prev == 0, call successively
 * with prev set to the last value returned from this function
 * until the routine returns zero which means no more string values.
 */
char *
prom_decode_composite_string(void *buf, size_t buflen, char *prev)
{
	if ((buf == 0) || (buflen == 0) || ((int)buflen == -1))
		return ((char *)0);

	if (prev == 0)
		return ((char *)buf);

	prev += prom_strlen(prev) + 1;
	if (prev >= ((char *)buf + buflen))
		return ((char *)0);
	return (prev);
}
