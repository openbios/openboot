/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: wrapper.h
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
 * @(#)wrapper.h 1.1 01/05/18
 * Copyright 2001 Sun Microsystems, Inc.  All Rights Reserved
 */

#ifndef	_WRAPPER_H_
#define	_WRAPPER_H_

#define	DEF_FPATH ".:/usr/lib:/usr/local/lib/forth"
#define	DEF_PATH  ".:/usr/bin:/usr/local/bin"
#define	DEF_EXE "forth.dic"		/* Default Forth image file */
#ifndef DEF_DICT
#define	DEF_DICT  (256*1024L)		/* Default dictionary growth space */
#endif /* DEF_DICT */

#define	DICT_ORIGIN_ALIGNMENT	(0x8000)
#define	DICT_SIZE_ALIGNMENT	(0x100)
#define	DICT_HEADER_SIZE	(0x20)

#define	ROUNDUP(n, alignment)  \
	((unsigned long)n + (alignment-1) & ~(alignment-1))

typedef struct HEADER_T {
	uint32_t h_magic;
	uint32_t h_tlen;
	uint32_t h_dlen;
	uint32_t h_blen;
	uint32_t h_slen;
	uint32_t h_entry;
	uint32_t h_trlen;
	uint32_t h_drlen;
} header_t;

typedef struct INCLUDE_FILE_T {
	struct INCLUDE_FILE_T *next;
	char	*name;
	int	linenum;
	FILE	*fd;
} include_file_t;

typedef long *fstackp;

#define	PUSH(m, s)	*(--s) = (long)(m)
#define	POP(s)		*(s++)

char *expand_name(char *name);
char *sccs_name(char *name);
int isobsolete(char *name);
char *sccs_get(char *name);

int t_init(void);
int t_rows(void);
int t_cols(void);
void t_op(int);

#endif
