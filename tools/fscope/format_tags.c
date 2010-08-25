/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: format_tags.c
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
 * @(#)format_tags.c 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "fscope.h"

typedef struct TAG_T {
	char *name;
	char *file;
	int line;
	struct TAG_T *next;
} tag_t;

void
xref_tag_init(extract_t *info)
{
	info->private = malloc(128 * sizeof (tag_t));
	memset(info->private, 0, 128 * sizeof (tag_t));
}

void
xref_tag_fini(extract_t *info)
{
	int i;
	tag_t *this_tag, *next;
	tag_t **tags = info->private;

	for (i = 0; i < 128; i++) {
		this_tag = tags[i];
		while (this_tag) {
			next = this_tag->next;
			fprintf(info->outfd, "%s\t%s\t%d\n",
			    this_tag->name,
			    this_tag->file,
			    this_tag->line);
			free(this_tag->file);
			free(this_tag);
			this_tag = next;
		}
	}
	free(info->private);
	info->private = NULL;
}

void
xref_tag_format(extract_t *info, xref_t *cref)
{
	tag_t **all_tags = info->private;
	tag_t *ipt, *new, *prev;

	new = malloc(sizeof (tag_t));
	new->name = cref->name;
	new->file = strdup(expand_filename(info, cref));
	new->line = cref->linenum;
	new->next = NULL;
	ipt = all_tags[(unsigned int)cref->name[0]];
	prev = NULL;
	while ((ipt != NULL) && (strcmp(new->name, ipt->name) > 0)) {
		prev = ipt;
		ipt = ipt->next;
	}
	if (prev == NULL) {
		new->next = all_tags[(unsigned int)cref->name[0]];
		all_tags[(unsigned int)cref->name[0]] = new;
	} else {
		new->next = prev->next;
		prev->next = new;
	}
}

void
xref_etag_format(extract_t *info, xref_t *cref)
{
	fprintf(stderr, "etags, not yet implemented, sorry\n");
	exit(1);
}
