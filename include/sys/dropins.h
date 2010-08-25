/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: dropins.h
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
 * id: @(#)dropins.h 1.4 03/04/01
 * purpose: 
 * copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved
 */

#ifndef	_DROPINS_H_
#define	_DROPINS_H_

#define	ROUNDUP_A(n, alignment)  \
	(((unsigned int)(n) + (alignment-1)) & ~(alignment-1))

#define	ROUNDUP(n)	ROUNDUP_A((n), 4)
#define	OBMD_HDR	sizeof (obmd_t)

#define	OBMD_MAGIC	0x4f424d44	/* OBMD */
#define	OBME_MAGIC	0x4f424d45	/* OBME */
#define	COMP_MAGIC	0x434f4d50	/* COMP */

typedef struct COMPRESSHDR {
	unsigned int	magic;
	unsigned int	comp_size;
	unsigned int	type;
	unsigned int	decomp_size;
} compresshdr;

/*
 * a level 1 dropin header
 */
typedef struct OBMD {
	char magic[4];
	int  size;
	short res0;
	ushort_t chksum;
	int res1;
	char name[16];
} obmd_t;

typedef struct DROPIN_DATA {
	uchar_t *data;
	int size;
} dropin_data_t;

/*
 * a level 2 header. really a 'directory' of level 1's
 */
typedef struct OBME {
	char magic[4];
} obme_t;

#endif
