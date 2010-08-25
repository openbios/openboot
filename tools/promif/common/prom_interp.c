/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_interp.c
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

#pragma ident	"@(#)prom_interp.c	1.1	00/07/22	SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

void
prom_interpret(char *string, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
    uintptr_t arg4, uintptr_t arg5)
{
	cell_t ci[9];

	/*
	 * We simply promote arguments treating them as unsigned integers;
	 * thus pointers will be properly promoted and negative signed
	 * integer value will not be properly promoted. Note that we
	 * also assume that the arguments are not to be sign extended.
	 *
	 * XXX: This is not fully capable via this interface.  Use
	 * p1275_cif_handler directly for all features.  Specifically,
	 * there's no catch_result and no result cells available via this
	 * interface. This interface is provided for compatibilty with
	 * existing code.
	 */

	ci[0] = p1275_ptr2cell("interpret");	/* Service name */
	ci[1] = (cell_t)6;			/* #argument cells */
	ci[2] = (cell_t)0;			/* #return cells */
	ci[3] = p1275_ptr2cell(string);		/* Arg1: Interpreted string */
	ci[4] = p1275_uintptr2cell(arg1);	/* Arg2: stack arg 1 */
	ci[5] = p1275_uintptr2cell(arg2);	/* Arg3: stack arg 2 */
	ci[6] = p1275_uintptr2cell(arg3);	/* Arg4: stack arg 3 */
	ci[7] = p1275_uintptr2cell(arg4);	/* Arg5: stack arg 4 */
	ci[8] = p1275_uintptr2cell(arg5);	/* Arg6: stack arg 5 */

	(void) p1275_cif_handler(&ci);
}
