/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_boot.c
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

#pragma ident	"@(#)prom_boot.c	1.1	00/07/22 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

char *
prom_bootargs(void)
{
	int32_t length;
	dnode_t node;
	static char *name = "bootargs";
	static char bootargs[OBP_MAXPATHLEN];

	if (bootargs[0] != (char)0)
		return (bootargs);

	node = prom_chosennode();
	length = prom_getproplen(node, name);

	if ((length == -1) || (length == 0))
		return (NULL);

	if (length > OBP_MAXPATHLEN)
		length = OBP_MAXPATHLEN - 1;	/* Null terminator */

	(void) prom_bounded_getprop(node, name, bootargs, length);

	return (bootargs);
}

char *
prom_bootpath(void)
{
	static char bootpath[OBP_MAXPATHLEN];
	int32_t length;
	dnode_t node;
	static char *name = "bootpath";

	if (bootpath[0] != (char)0)
		return (bootpath);

	node = prom_chosennode();
	length = prom_getproplen(node, name);

	if ((length == -1) || (length == 0))
		return (NULL);

	if (length > OBP_MAXPATHLEN)
		length = OBP_MAXPATHLEN - 1;	/* Null terminator */

	(void) prom_bounded_getprop(node, name, bootpath, length);

	return (bootpath);
}
