/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_io.c
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

#pragma ident	"@(#)prom_io.c	1.1	00/08/07 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

/*
 *  Returns 0 on error. Otherwise returns a handle.
 */
ihandle_t
prom_open(char *path)
{
	cell_t ci[5];

	ci[0] = p1275_ptr2cell("open");		/* Service name */
	ci[1] = (cell_t)1;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ptr2cell(path);		/* Arg1: Pathname */
	ci[4] = (cell_t)0;			/* Res1: Prime result */

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2ihandle(ci[4]));	/* Res1: ihandle */
}

int
prom_seek(ihandle_t fd, u_longlong_t offset)
{
	cell_t ci[7];

	ci[0] = p1275_ptr2cell("seek");		/* Service name */
	ci[1] = (cell_t)3;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ihandle2cell(fd);		/* Arg1: ihandle */
	ci[4] = p1275_ull2cell_high(offset);	/* Arg2: pos.hi */
	ci[5] = p1275_ull2cell_low(offset);	/* Arg3: pos.lo */
	ci[6] = (cell_t)-1;			/* Res1: Prime result */

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2int(ci[6]));		/* Res1: actual */
}

uint32_t
prom_read(ihandle_t fd, caddr_t buf, uint32_t len)
{
	cell_t ci[7];

	ci[0] = p1275_ptr2cell("read");		/* Service name */
	ci[1] = (cell_t)3;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ihandle2cell(fd);		/* Arg1: ihandle */
	ci[4] = p1275_ptr2cell(buf);		/* Arg2: buffer address */
	ci[5] = p1275_uint2cell(len);		/* Arg3: buffer length */
	ci[6] = (cell_t)-1;			/* Res1: Prime result */

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2uint(ci[6]));	/* Res1: actual length */
}

uint32_t
prom_write(ihandle_t fd, caddr_t buf, uint32_t len)
{
	cell_t ci[7];

	ci[0] = p1275_ptr2cell("write");	/* Service name */
	ci[1] = (cell_t)3;			/* #argument cells */
	ci[2] = (cell_t)1;			/* #result cells */
	ci[3] = p1275_ihandle2cell(fd);		/* Arg1: ihandle */
	ci[4] = p1275_ptr2cell(buf);		/* Arg2: buffer address */
	ci[5] = p1275_uint2cell(len);		/* Arg3: buffer length */
	ci[6] = (cell_t)-1;			/* Res1: Prime result */

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2uint(ci[6]));	/* Res1: actual length */
}

int
prom_close(ihandle_t fd)
{
	cell_t ci[4];

	ci[0] = p1275_ptr2cell("close");	/* Service name */
	ci[1] = (cell_t)1;			/* #argument cells */
	ci[2] = (cell_t)0;			/* #result cells */
	ci[3] = p1275_ihandle2cell(fd);		/* Arg1: ihandle */

	(void) p1275_cif_handler(&ci);

	return (0);
}
