/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: sys-seeprom.h
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
 * id: @(#)sys-seeprom.h 1.2 01/09/04
 * purpose:
 * copyright: Copyright 2000-2001 Sun Microsystems, Inc.  All Rights Reserved
 */

struct mem_table_entry {
	int			memc;
	unsigned char		*memtable_ptr;
	int			len;
	struct mem_table_entry	*next;
};

struct timing {
	char			*name;
	unsigned short		size;
};

struct timing timing_parameters[] = {
	{ "speed_max",		1 },
	{ "speed_min",		1 },
	{ "wrdly",		1 },
	{ "wrhld",		1 },
	{ "cds_skew",		3 },
	{ "addr_max",		3 },
	{ "addr_min",		3 },
	{ "ctl_buf_max",	3 },
	{ "ctl_buf_min",	3 },
	{ "clk_max",		3 },
	{ "clk_min",		3 },
	{ "ds_max",		3 },
	{ "ds_min",		3 },
	{ "sd_max",		3 },
	{ "sd_min",		3 },
	{ "cds_setup",		3 },
	{ "cds_hold",		3 },
	{ NULL,			0 },
};

#define	TIMING_ENTRY_SIZE	(1*4)+(3*13)

struct timing_table_entry {
	unsigned char			timing_data[TIMING_ENTRY_SIZE];
	struct timing_table_entry	*next;
};
