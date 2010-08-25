/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_heartbeat.c
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

#pragma ident	"@(#)prom_heartbeat.c	1.1	00/07/22 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

/*
 * Provide 10 millisecond heartbeat for the PROM. A client that has taken over
 * the trap table and clock interrupts, but is not quite ready to take over the
 * function of polling the input-device for an abort sequence (L1/A or BREAK)
 * may use this function to instruct the PROM to poll the keyboard. If used,
 * this function should be called every 10 milliseconds.
 */
int
prom_heartbeat(int32_t msecs)
{
	cell_t ci[5];

	ci[0] = p1275_ptr2cell("SUNW,heartbeat");	/* Service name */
	ci[1] = (cell_t)1;				/* #argument cells */
	ci[2] = (cell_t)1;				/* #result cells */
	ci[3] = p1275_int2cell(msecs);			/* Arg1: msecs */
	ci[4] = (cell_t)0;				/* Prime the result */

	(void) p1275_cif_handler(&ci);

	return (p1275_cell2int(ci[4]));			/* Res1: abort-flag */
}
