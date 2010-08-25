/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: fscope.h
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
 * @(#)fscope.h 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */

#ifndef	_FSCOPE_H_
#define	_FSCOPE_H_

#include "xref.h"

#define	ASSERT(x, y)	\
if (x); else fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, y)

#define	TYPE_LIMIT	1
#define	TYPE_CALLS	2
#define	TYPE_CALLERS	3
#define	TYPE_DEFINE	4
#define	TYPE_INTERACT	5
#define	TYPE_STRING	6
#define	TYPE_TEXT	7
#define	TYPE_DIRECTED	8

#define	FLAG_ABS_PATH	1
#define	FLAG_REGEXP	2
#define	FLAG_VERBOSE	4

typedef struct EXTRACT_T extract_t;

typedef struct OUTPUT_MODE_T {
	char	*name;
	void	(*init)(extract_t *info);
	void	(*update)(extract_t *info, xref_t *cref);
	void	(*fini)(extract_t *info);
} output_mode_t;

/*
 * private is for the list user to set,
 * notify is there so that a pruned list element can notify a user of the
 * private pointer about a dispose or copy operation.
 */
typedef struct SEARCH_T {
	xref_t *xref;
	void *private;
	void *(*notify)(struct SEARCH_T *this, int dispose);
	struct SEARCH_T *next;
	struct SEARCH_T *prev;
} search_t;

struct EXTRACT_T {
	int lo, hi;		/* limit matching */
	int type;		/* non interactive control flag */
	int flags;		/* search types */
	char *root_buf;		/* path construction */
	char *root;		/* root replacement string */
	char *symbol;		/* regexp/symbol to search for */
	char *indexfile;	/* index file name */
	char *outputfile;	/* output file name */
	void *private;		/* private pointer for callers use */
	FILE *outfd;		/* output file descriptor */
	xref_state_t *state;	/* xref state */
	output_mode_t *extract;	/* current extract mode */
};

void xref_grep_format(extract_t *info, xref_t *cref);
char *expand_filename(extract_t *info, xref_t *cref);

void xref_tag_init(extract_t *info);
void xref_tag_fini(extract_t *info);
void xref_tag_format(extract_t *info, xref_t *cref);
void xref_etag_format(extract_t *info, xref_t *cref);
void xref_interactive_mode(extract_t *info);

search_t *new_search_t(void);

void free_searchlist(search_t *list);
search_t *build_searchlist(extract_t *info, search_t *root, int restrict);
search_t *search_list(extract_t *info, int prune, search_t *list,
    int (match)(extract_t *info, search_t *item));
void iterate_list(extract_t *info, search_t *list,
    void (fn)(extract_t *info, search_t *item));

#endif
