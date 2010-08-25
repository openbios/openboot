/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: xref.h
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
 * @(#)xref.h 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */

#ifndef	_XREF_H_
#define	_XREF_H_

#define	MIN_REF		20

#define	XREF_DEFINITION	1
#define	XREF_FORWARD	2
#define	XREF_HIDDEN	4
#define	XREF_STRING	8

typedef struct REF_T {
	struct XREF_T **ptr;
	int	insert;
	int	size;
} ref_t;

typedef struct XREF_T {
	char	*name;
	int	linenum;
	int	flags;
	int	id;
	ref_t	calls;
	ref_t	called_by;
	struct XREF_FILE_T *file;	/* where it is defined */
	struct XREF_T *next_def;	/* ptr to next entry in symbol hash */
} xref_t;

/*
 * the prev struct is for pushing and poping file references
 * not a doubly linked list
 */
typedef struct XREF_FILE_T {
	char	*name;
	int	id;
	struct XREF_FILE_T *next;
	struct XREF_FILE_T *prev_file;
	xref_t	**defs;
} xref_file_t;

/* used by the meta compiler, so that forward defs are referenced properly */
#define	XREF_STATE_FWD_DEF	1

typedef struct XREF_STATE_T {
	xref_file_t	*sources; 	/* sources unordered */
	xref_file_t	**file_cache;	/* source files by id */
	xref_file_t	*current_file;
	xref_t		*all_refs[128];	/* 128 entry root hash table */
	xref_t		**xref_cache;   /* definitions by id */
	xref_t		*current_def;
	int		flags;
} xref_state_t;

xref_t *xref_find_symbol(xref_t **where, char *name, xref_t **prev, int ign);
xref_t *xref_create_reference(char *name, int line, xref_state_t *state);

void xref_free_state(xref_state_t *state);
void xref_save_file(char *filename, xref_state_t *state);
void xref_add_definition(xref_t **where, xref_t *new);
void xref_add_reference_to_buffer(ref_t *where, xref_t *fn);

xref_state_t *xref_load_file(char *filename, int verbose);
xref_state_t *xref_create_state(void);

xref_file_t *xref_create_file_reference(char *name);
char *xref_extract_pathname(char *srcpath);

#endif
