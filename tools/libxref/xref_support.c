/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: xref_support.c
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
 * @(#)xref_support.c 1.2 03/08/20
 * Copyright 2001-2003 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "xref_support.h"

#define	ASSERT(x, y)	\
if (x); else fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, y)

/*
 * The public statefull part of  the cross referencer lives here
 */
static xref_state_t *xref_state;
static int  xref_inited = 0;
static char *xref_file = NULL;
static int  xref_level = 0;

void
push_file_reference(xref_file_t *ref)
{
	ASSERT((ref != NULL), "Pushed a NULL file??\n");
	ref->prev_file = xref_state->current_file;
	xref_state->current_file = ref;
}

void
pop_file_reference(xref_file_t *ref)
{
	ASSERT((ref != NULL), "Popped a NULL file??\n");
	xref_state->current_file = ref->prev_file;
	ref->prev_file = NULL;
}

/*
 * We just touched a new file, so we need to create the reference structs for
 * it
 */
static void
add_file_reference(char *name)
{
	xref_file_t *newf;
	char *nfile;

	newf = xref_create_file_reference(xref_extract_pathname(name));
	newf->next = xref_state->sources;
	xref_state->sources = newf;
	push_file_reference(newf);
}

void
xref_init(char *filename, char *preload, int fwd)
{
	xref_file_t *newf;
	if (!xref_inited) {
		if (strcmp(filename, "-") == 0) {
			xref_file = NULL;
		} else {
			xref_file = strdup(filename);
		}
		if (preload == NULL) {
			xref_state = xref_create_state();
			if (fwd) {
				xref_state->flags |= XREF_STATE_FWD_DEF;
			}
			add_file_reference("Unknown-default");
		} else {
			xref_state = xref_load_file(preload, 0);
		}
	}
	xref_inited = 1;
}

void
xref_generate(int force)
{
	static int xref_done = 0;

	if (!force && (xref_done++))
		return;

	if (!xref_inited)
		return;

	xref_save_file(xref_file, xref_state);
}

void
xref_add_file_reference(char *name)
{
	if (!xref_inited)
		return;

	add_file_reference(name);
}

void
xref_remove_file_reference(void)
{
	if (!xref_inited)
		return;

	pop_file_reference(xref_state->current_file);
}

void
xref_add_symbol_reference(char *name, int line)
{
	xref_t *xref, *prev;
	xref_t *fn = xref_state->current_def;

	if (xref_state->current_def == NULL)
		return;

	xref = xref_find_symbol(xref_state->all_refs, name, &prev,
	    (XREF_HIDDEN | XREF_STRING));
	if (xref == NULL) {
		if (xref_state->flags & XREF_STATE_FWD_DEF) {
			xref = xref_create_reference(name, line, xref_state);
			xref->flags |= XREF_FORWARD;
			xref->flags |= XREF_DEFINITION;
		} else {
			return;
		}
	}
	xref_add_reference_to_buffer(&fn->calls, xref);
	xref_add_reference_to_buffer(&xref->called_by, fn);
}

void
xref_add_symbol_definition(char *name, int line)
{
	xref_t *xref, *prev;

	xref = xref_find_symbol(xref_state->all_refs, name, &prev,
	    (XREF_HIDDEN | XREF_STRING));

	if ((xref != NULL) &&
	    (xref->linenum == line) &&
	    (xref_state->current_file == xref->file)) {
		/*
		 * the metacompiler causes multiple 'definition' hits
		 * so we ignore the repetitiions.
		 */
#if 0
		printf("%s:%d:Still required?\n",
		    xref_state->current_file->name, line);
#endif
#if 1
		return;
#endif
	}
	xref_state->current_def = xref_create_reference(name,
	    line, xref_state);
	xref_state->current_def->flags |= XREF_DEFINITION;
}

void
xref_modify_symbol_definition(char *name, int reveal)
{
	xref_t *xref, *prev;

	/* this can happen because of bootstrapping!! */
	if (name == NULL)
		return;

	xref = xref_find_symbol(xref_state->all_refs, name, &prev,
	    XREF_STRING);

	if (xref == NULL) {
		fprintf(stderr, "%s called for %s (that did not exist)!\n",
		    (reveal ? "reveal" : "hide"), name);
		return;
	}
	if (reveal)
		xref->flags &= ~XREF_HIDDEN;
	else
		xref->flags |= XREF_HIDDEN;
}

/*
 * now the fun starts.. we need to break the string up into words
 * throwing away extra spaces and control chars and add each word to the
 * index, tagging each word with the XREF_STRING marker.
 */
void
xref_add_string(char *string, int len, int line)
{
	int index;
	char word[256];
	int wordlen;
	xref_t *xref;

	index = 0;
	wordlen = 0;
	while (index < len) {
		char c;

		c = string[index];
		if ((c <= ' ') || (c >= 127)) {
			if (wordlen) {
				word[wordlen] = 0;
				wordlen = 0;
				xref = xref_create_reference(word, line,
				    xref_state);
				xref->flags |= XREF_STRING;
			}
			index++;
			continue;
		}
		word[wordlen++] = c;
		index++;
	}
	if (wordlen) {
		word[wordlen] = 0;
		xref = xref_create_reference(word, line, xref_state);
		xref->flags |= XREF_STRING;
	}
}

void
xref_status(void)
{
	printf("Current File: '%s'\n",
	    (xref_state->current_file == NULL)?
	    "<NULL>" : xref_state->current_file->name);
	printf("Last Definition: '%s' (%d)\n",
	    ((xref_state->current_def == NULL)?
		"<NULL>" : xref_state->current_def->name),
	    ((xref_state->current_def == NULL)?
		0 : xref_state->current_def->called_by.insert));
}
