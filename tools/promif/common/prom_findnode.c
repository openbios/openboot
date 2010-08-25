/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_findnode.c
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
 * id: @(#)prom_findnode.c 1.1 03/04/01
 * purpose: 
 * Copyright 2000-2003 Sun Microsystems, Inc. All Rights Reserved
 * Use is subject to license terms.
 */

#include <sys/promif.h>
#include <sys/promimpl.h>

#pragma ident	"@(#)prom_findnode.c	1.1	00/08/07 SMI"

dnode_t
prom_findnode_bydevtype(dnode_t node, char *type)
{
	dnode_t id;

	if (prom_devicetype(node, type))
		return (node);

	for (node = prom_childnode(node); node; node = prom_nextnode(node)) {
		if ((id = prom_findnode_bydevtype(node, type)) != (dnode_t)0)
			return (id);
	}

	return ((dnode_t)0);
}

dnode_t
prom_findnode_byname(dnode_t node, char *name)
{
	dnode_t id;

	if (prom_nodename(node, name))
		return (node);

	for (node = prom_childnode(node); node; node = prom_nextnode(node)) {
		if ((id = prom_findnode_byname(node, name)) != (dnode_t)0)
			return (id);
	}

	return ((dnode_t)0);
}
