/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: search.c
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
 * @(#)search.c 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Copyright Use is subject to license terms.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <regexpr.h>

#include "fscope.h"

void
free_searchlist(search_t *list)
{
	search_t *next;

	while (list != NULL) {
		next = list->next;
		free(list);
		list = next;
	}
}

search_t *
new_search_t(void)
{
	search_t *new;

	new = malloc(sizeof (search_t));
	new->private = NULL;
	new->notify = NULL;
	new->next = NULL;
	new->prev = NULL;
	new->xref = NULL;
	return (new);
}

static search_t *
regexp_search(extract_t *info, search_t *root, int restrict)
{
	search_t *new;
	xref_t *cref;
	char *regexpbuf;
	int i;
	char *symbol;
	int rlen;

	symbol = info->symbol;
	regexpbuf = compile(symbol, NULL, NULL);
	if (regexpbuf == NULL) {
		printf("Regexp error: %d\n", regerrno);
		return (NULL);
	}
	for (i = 0; i < 128; i++) {
		cref = info->state->all_refs[i];
		while (cref != NULL) {
			int match;
			if (cref->flags & restrict) {
				match = step(cref->name, regexpbuf);
			} else {
				match = 0;
			}
			if (match) {
				new = new_search_t();
				new->xref = cref;
				new->next = root;
				root = new;
			}
			cref = cref->next_def;
		}
	}
	free(regexpbuf);
	return (root);
}

static search_t *
exact_search(extract_t *info, search_t *root, int restrict)
{
	search_t *new;
	xref_t *cref;
	char *symbol;

	symbol = info->symbol;
	cref = info->state->all_refs[(unsigned int)symbol[0]];
	while (cref != NULL) {
		if ((cref->flags & restrict) &&
		    (strcmp(symbol, cref->name) == 0)) {
			new = new_search_t();
			new->xref = cref;
			new->next = root;
			root = new;
		}
		cref = cref->next_def;
	}
	return (root);
}

search_t *
build_searchlist(extract_t *info, search_t *root, int restrict)
{
	if (info->flags & FLAG_REGEXP) {
		return (regexp_search(info, root, restrict));
	}
	return (exact_search(info, root, restrict));
}

search_t *
search_list(extract_t *info, int prune, search_t *list,
    int (match)(extract_t *info, search_t *item))
{
	search_t *root = NULL;
	search_t *new, *next, *prev;
	search_t *newlist = NULL;
	int hit;

	prev = NULL;
	newlist = list;
	while (newlist != NULL) {
		next = newlist->next;
		hit = match(info, newlist);
		if (prune) {
			if (!hit) {
				/* prune it away */
				if (prev != NULL) {
					prev->next = next;
				} else {
					list = next;
				}
				if (newlist->notify != NULL) {
					newlist->notify(newlist, 1);
				}
				free(newlist);
			} else {
				prev = newlist;
			}
		} else {
			if (hit) {
				new = new_search_t();
				if (newlist->notify != NULL) {
					new->private =
					    newlist->notify(newlist, 0);
				} else {
					new->private = newlist->private;
				}
				new->xref = newlist->xref;
				new->next = root;
				root = new;
			}
			prev = newlist;
		}
		newlist = next;
	}
	if (prune)
		return (list);
	return (root);
}

void
iterate_list(extract_t *info, search_t *list,
    void (fn)(extract_t *info, search_t *item))
{
	while (list != NULL) {
		fn(info, list);
		list = list->next;
	}
}
