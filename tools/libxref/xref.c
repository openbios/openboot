/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: xref.c
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
 * @(#)xref.c 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "xref.h"

xref_state_t *
xref_create_state(void)
{
	xref_state_t *new;
	new = malloc(sizeof (xref_state_t));
	memset(new, 0, sizeof (xref_state_t));
	return (new);
}

xref_file_t *
xref_create_file_reference(char *name)
{
	size_t bytes = 128 * sizeof (xref_t *);
	xref_file_t *newf;

	newf = malloc(sizeof (xref_file_t));
	newf->name = strdup(name);
	newf->defs = malloc(bytes);
	memset(newf->defs, 0, bytes);
	return (newf);
}

void
xref_add_definition(xref_t **where, xref_t *new)
{
	unsigned int index;
	index = new->name[0];

	new->next_def = where[index];
	where[index] = new;
}

/*
 * when a new routine is defined call this..
 */
xref_t *
xref_create_reference(char *name, int line, xref_state_t *state)
{
	xref_t *new;

	new = malloc(sizeof (xref_t));
	new->name = strdup(name);
	new->file = state->current_file;
	new->linenum = line;
	new->flags = 0;
	new->calls.size = MIN_REF;
	new->calls.insert = 0;
	new->calls.ptr = malloc(sizeof (xref_t *) * new->calls.size);
	new->called_by.size = MIN_REF;
	new->called_by.insert = 0;
	new->called_by.ptr = malloc(sizeof (xref_t *) * new->called_by.size);
	new->next_def = NULL;

	if (state->current_file == NULL) {
		fprintf(stderr, "%s:%d: Current file == NULL!!\n",
		    __FILE__, __LINE__);
	}
	xref_add_definition(state->current_file->defs, new);
	xref_add_definition(state->all_refs, new);
	return (new);
}

void
xref_add_reference_to_buffer(ref_t *where, xref_t *fn)
{
	xref_t **newbuf, **oldbuf;

	if (where->insert < where->size) {
		where->ptr[where->insert++] = fn;
	} else {
		int bytes;

		/*
		 * we need to grow the reference buffer.
		 */
		bytes = (where->size + MIN_REF) * sizeof (xref_t *);
		newbuf = malloc(bytes);
		memset(newbuf, 0, bytes);
		oldbuf = where->ptr;
		memcpy(newbuf, oldbuf, (where->size*sizeof (xref_t *)));
		free(oldbuf);
		where->ptr = newbuf;
		where->size += MIN_REF;
		where->ptr[where->insert++] = fn;
	}
}

void
xref_free_state(xref_state_t *state)
{
}
