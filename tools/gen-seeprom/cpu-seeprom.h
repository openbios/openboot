/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: cpu-seeprom.h
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
 * id: @(#)cpu-seeprom.h 1.4 05/11/15
 * purpose:
 * copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

#define	MAXSPEEDLIST		100
#define	MAX_SAFARI_SPEED	200
#define	CPU_DEFAULT_MAGIC	0x4846
/*
 * Assigned id magics:
 * Excalibur/Lneck/LW2+:	0x4846, 4847
 * Fiesta (Jalapeno)		0x4130
 * Gemini 			0x4131
 * Serrano			0x4132
 * Niagara			0x4231
 */
#define	FIESTA_MAX_MEMC		8

struct ecache_entry {
	unsigned short		cpu_max;
	unsigned short		cpu_min;
	unsigned long long	ecache_cfg[2];
	struct ecache_entry	*next;
};

struct speed_entry {
	unsigned short		speed_hi;
	unsigned short		speed_lo;
	unsigned short		ratio;
	struct speed_entry	*next;
};

struct fiesta_memc_entry {
	unsigned short		bus_hi;
	unsigned short		bus_lo;
	unsigned short		entry_id;
	unsigned short		ratio;
	unsigned short		memclk;
	unsigned long long	mcr[3];
	struct fiesta_memc_entry	*next;
};
