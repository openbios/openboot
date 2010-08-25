/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_isa.h
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
 * Copyright (c) 2000, 2003 Sun Microsystems, Inc. All rights reserved.
 * Use is subject to license terms.
 */

#ifndef	_SYS_PROM_ISA_H
#define	_SYS_PROM_ISA_H

#pragma ident	"@(#)prom_isa.h	1.1	00/08/07	SMI"

#include <sys/obpdefs.h>

/*
 * This file contains external ISA-specific promif interface definitions.
 *
 * This version of the file contains definitions for both a 32-bit client
 * program or a 64-bit client program calling the 64-bit cell-sized SPARC
 * v9 firmware client interface handler.
 *
 * On SPARC v9 machines, a 32-bit client program must provide
 * a function to manage the conversion of the 32-bit stack to
 * a 64-bit stack, before calling the firmware's client interface
 * handler.
 */

#ifdef	__cplusplus
extern "C" {
#endif

typedef	unsigned long long cell_t;

#define	p1275_ptr2cell(p)	((cell_t)((uintptr_t)((void *)(p))))
#define	p1275_int2cell(i)	((cell_t)((int)(i)))
#define	p1275_uint2cell(u)	((cell_t)((unsigned int)(u)))
#define	p1275_size2cell(u)	((cell_t)((size_t)(u)))
#define	p1275_phandle2cell(ph)	((cell_t)((unsigned int)((phandle_t)(ph))))
#define	p1275_dnode2cell(d)	((cell_t)((unsigned int)((dnode_t)(d))))
#define	p1275_ihandle2cell(ih)	((cell_t)((unsigned int)((ihandle_t)(ih))))
#define	p1275_ull2cell_high(ll)	(0LL)
#define	p1275_ull2cell_low(ll)	((cell_t)(ll))
#define	p1275_uintptr2cell(i)	((cell_t)((uintptr_t)(i)))

#define	p1275_cell2ptr(p)	((void *)((cell_t)(p)))
#define	p1275_cell2int(i)	((int)((cell_t)(i)))
#define	p1275_cell2uint(u)	((unsigned int)((cell_t)(u)))
#define	p1275_cell2size(u)	((size_t)((cell_t)(u)))
#define	p1275_cell2phandle(ph)	((phandle_t)((cell_t)(ph)))
#define	p1275_cell2dnode(d)	((dnode_t)((cell_t)(d)))
#define	p1275_cell2ihandle(ih)	((ihandle_t)((cell_t)(ih)))
#define	p1275_cells2ull(h, l)	((unsigned long long)(cell_t)(l))
#define	p1275_cell2uintptr(i)	((uintptr_t)((cell_t)(i)))

/*
 * Define default cif handlers.
 */
#define	p1275_cif_init			p1275_sparc_cif_init
#define	p1275_cif_handler		p1275_sparc_cif_handler

extern void	*p1275_sparc_cif_init(void *);
extern int	p1275_cif_handler(void *);

/*
 * ISA dependent utility functions/macros
 */
#define	prom_decode_int(v)		(v)

#ifdef	__cplusplus
}
#endif

#endif /* _SYS_PROM_ISA_H */
