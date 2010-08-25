/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_sparc.c
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
 * Copyright (c) 2000-2003 Sun Microsystems, Inc. All Rights Reserved
 * Use is subject to license terms.
 */

#pragma ident	"@(#)prom_sparc.c	1.1	00/08/07 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

/*
 * P1275 Client Interface Functions defined for SPARC.
 * This file belongs in a platform dependent area.
 */

/*
 * Pointer to a verified (non NULL) client interface structure
 */
int32_t (*cif_handler)(void *);

void *
p1275_sparc_cif_init(void *cookie)
{
	cif_handler = (int32_t (*)(void *))cookie;
	return ((void *)cookie);
}


/*
 * This code is appropriate for 32 bit client programs calling the
 * 64 bit cell-sized client interface handler.  On SPARC V9 machines,
 * the client program must manage the conversion of the 32 bit stack
 * to a 64 bit stack itself. Thus, the client program must provide
 * this function. (client_handler).
 */
int
p1275_sparc_cif_handler(void *p)
{
	int32_t rv;

	if (cif_handler == NULL)
		return (-1);

	rv = client_handler((void *)cif_handler, p);
	return (rv);
}
