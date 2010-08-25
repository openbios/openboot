/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: gen-seeprom.h
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
 * id: @(#)gen-seeprom.h 1.8 05/11/15
 * purpose:
 * copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

#define	CPU	0
#define	SYS	1
#define	ENV	2
#define	MEM	3
#define	CPU_RW	4

#define	EXCALIBUR 	1
#define	FIESTA   	2
#define	GMFIESTA   	3
#define	SERRANO   	4

#define	NO_ERROR	0
#define	ERROR		1
#define	UNKNOWN		2

#define	NUM	0
#define	STRING	1

#define	MAXLINE 512
#define	MAXNAMESIZE 32

struct fixed_seeprom {
	char			*name;
	unsigned short		size;
	unsigned short		type;
	unsigned long long	value;
	void			(*notify)(void *);
};

typedef struct {
	char			name[MAXNAMESIZE];
	int			pos;
	int			size;
} data_reg;

#define	SET_FUNC_ENTRY(dyn, check, write, dump, reg) \
	{ dyn, check, write, dump, reg},

struct unique_functions {
	int			(*dynamic_func)(char *parameter, char *line);
	int			(*check_func)(void);
	void			(*write_func)(unsigned char **ptr);
	void			(*dump_func)(void);
	int			(*reg_func)(char *s1, data_reg **reg);
};
