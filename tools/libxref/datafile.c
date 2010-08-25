/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: datafile.c
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
 * @(#)datafile.c 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Copyright Use is subject to license terms.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "xref.h"

static void
write_4bytes(int n, FILE *fd)
{
	fwrite(&n, 1, 4, fd);
}

static int
read_4bytes(FILE *fd)
{
	uint32_t ival;
	fread(&ival, 1, 4, fd);
	return (ival);
}

#ifdef LOAD_DEBUG
#define	LPRINTF(x)	printf x
#else
#define	LPRINTF(x)
#endif

static xref_t *
load_symbol_from_file(xref_state_t *state, int *sindex, int n, FILE *fd)
{
	xref_t *sym;
	char tag[4];
	int j, fid, bytes;
	int *calls_ptr = NULL;
	int *called_ptr = NULL;
	xref_t *new;
	xref_file_t *file;

	LPRINTF(("Loading symbol: %d ", n));
	sym = state->xref_cache[n];
	if (sym != NULL) {
		LPRINTF((" [cached] %x\n", sym));
		return (sym);
	}
	LPRINTF((" from file\n"));

	new = malloc(sizeof (xref_t));
	memset(new, 0, sizeof (xref_t));

	fseek(fd, sindex[n], 0);
	fread(tag, 1, 3, fd);
	if (strncmp(tag, "SYM", 3) != 0) {
		printf("Corrupted xref data file\n");
		return (NULL);
	}

	new->id = read_4bytes(fd);
	new->flags = read_4bytes(fd);

	/* we have the name */
	bytes = fgetc(fd);
	new->name = malloc(bytes + 1);
	fread(new->name, 1, bytes, fd);
	new->name[bytes] = 0;
	LPRINTF(("....name: %s\n", new->name));

	/* get the file it was defined in */
	fid = read_4bytes(fd);
	new->file = file = state->file_cache[fid];
	new->linenum = read_4bytes(fd);

	LPRINTF(("....File(%d) : %s:%d\n", fid, file->name, new->linenum));
	xref_add_definition(file->defs, new);

	/* prepare the data structures for the call refs */
	new->calls.insert = read_4bytes(fd);
	new->called_by.insert = read_4bytes(fd);
	new->calls.size = new->calls.insert;
	new->called_by.size = new->called_by.insert + 10;

	if (new->calls.size) {
		new->calls.ptr = malloc(new->calls.size * sizeof (xref_t *));
	}

	LPRINTF(("....Calls: %d\n", new->calls.insert));

	bytes = new->calls.insert * sizeof (int);
	if (bytes) {
		calls_ptr = malloc(bytes);
		fread(calls_ptr, 1, bytes, fd);
	}

	/* prepare the data structures for the called_by refs */
	bytes = new->called_by.size * sizeof (xref_t);
	new->called_by.ptr = malloc(bytes);

	LPRINTF(("....Called by: %d\n", new->called_by.insert));
	bytes = new->called_by.insert * sizeof (int);
	if (bytes) {
		called_ptr = malloc(bytes);
		fread(called_ptr, 1, bytes, fd);
	}

	state->xref_cache[new->id] = new;
	xref_add_definition(state->all_refs, new);
	for (j = 0; j < new->calls.insert; j++) {
		new->calls.ptr[j] = load_symbol_from_file(state,
		    sindex, calls_ptr[j], fd);
	}

	for (j = 0; j < new->called_by.insert; j++) {
		new->called_by.ptr[j] = load_symbol_from_file(state,
		    sindex, called_ptr[j], fd);
	}
#ifdef LOAD_DEBUG
	printf(": %s(%d) ", new->name, new->id);
	for (j = 0; j < new->calls.insert; j++) {
		printf("%s(%d) ", new->calls.ptr[j]->name,
		    new->calls.ptr[j]->id);
	}
	printf(";\n");
#endif
	if (calls_ptr != NULL)
		free(calls_ptr);
	if (called_ptr != NULL)
		free(called_ptr);
	return (new);
}

xref_state_t *
xref_load_file(char *filename, int verbose)
{
	int fid = 0;
	int sid = 0;
	int i, rebuild;
	FILE *fd;
	int *index, *findex, *sindex, bytes;
	xref_file_t *newf;
	xref_state_t *state;

	state = xref_create_state();

	fd = fopen(filename, "rb");
	if (fd == NULL) {
		printf("failed to open Xref data file %s\n", filename);
		return (NULL);
	}

	rebuild = read_4bytes(fd);
	fid = read_4bytes(fd);
	sid = read_4bytes(fd);

	if (verbose) {
		printf("loading xref data file %s, %d files, %d refs\n",
		    filename, fid, sid);
	}

	fseek(fd, 0, 0);
	bytes = sizeof (int) * (fid + sid + 3);
	index = malloc(bytes);
	memset(index, 0, bytes);
	fread(index, 1, bytes, fd);

	/* We have the index */
	findex = &index[3];
	sindex = &index[fid+3];

	state->file_cache = malloc(sizeof (xref_file_t *)*fid);
	memset(state->file_cache, 0, sizeof (xref_file_t *) * fid);

	state->xref_cache = malloc(sizeof (xref_t *) * sid);
	memset(state->xref_cache, 0, sizeof (xref_t *) * sid);

	i = 0;
	while (fid--) {
		int len;
		char nameptr[256];

		fseek(fd, findex[i], 0);
		len = fgetc(fd);
		fread(nameptr, 1, len, fd);
		nameptr[len] = 0;
		newf = xref_create_file_reference(nameptr);
#if 0
		printf("File: %d: %s\n", i, nameptr);
#endif
		newf->next = state->sources;
		state->sources = newf;
		state->file_cache[i] = newf;
		i++;
	}
	/*
	 * Now weve loaded the file names and created the file->sym
	 * structures fill in the references.
	 */
	i = 0;
	while (sid--) {
		xref_t *sym;
		sym = load_symbol_from_file(state, sindex, i++, fd);
	}

	fclose(fd);
	return (state);
}

void
xref_save_file(char *filename, xref_state_t *state)
{
	xref_file_t *fptr = state->sources;
	xref_t *rptr;
	int fid = 0;
	int wid = 0;
	int i;
	FILE *fd;
	int *index, *findex, *sindex, bytes;

	/* allocate a unique file ID */
	while (fptr != NULL) {
		fptr->id = fid++;
		fptr = fptr->next;
	}

	/* Allocate a unique symbol ID */
	for (i = 0; i < 128; i++) {
		rptr = state->all_refs[i];
		while (rptr != NULL) {
			rptr->id = wid++;
			rptr = rptr->next_def;
		}
	}

	/* Now write the binary file */
	fd = fopen(filename, "wb");
	if (fd == NULL) {
		printf("failed to open Xref database %s\n", filename);
		return;
	}

	bytes =  sizeof (int) * (wid + fid + 3);
	index = malloc(bytes);
	memset(index, 0, bytes);
	index[0] = 0;
	index[1] = fid;
	index[2] = wid;
	findex = &index[3];
	sindex = &index[fid+3];
	fseek(fd, bytes, 0);	/* skip the index */
	fptr = state->sources;
	while (fptr != NULL) {
		int len = strlen(fptr->name);

		findex[fptr->id] = ftell(fd);
		fputc(len, fd);
		fputs(fptr->name, fd);
		fptr = fptr->next;
	}
	for (i = 0; i < 128; i++) {
		int len;
		int j;
		xref_t *cptr;
		rptr = state->all_refs[i];
		while (rptr != NULL) {
#if 0
			printf("Saving: %s (%d)\n", rptr->name, rptr->id);
#endif
			len = strlen(rptr->name);
			sindex[rptr->id] = ftell(fd);
			fputs("SYM", fd);
			write_4bytes(rptr->id, fd);
			write_4bytes(rptr->flags, fd);
			fputc(len, fd);
			fputs(rptr->name, fd);
			write_4bytes(rptr->file->id, fd);
			write_4bytes(rptr->linenum, fd);
			write_4bytes(rptr->calls.insert, fd);
			write_4bytes(rptr->called_by.insert, fd);
			for (j = 0; j < rptr->calls.insert; j++) {
				cptr = rptr->calls.ptr[j];
				write_4bytes(cptr->id, fd);
			}
			for (j = 0; j < rptr->called_by.insert; j++) {
				cptr = rptr->called_by.ptr[j];
				write_4bytes(cptr->id, fd);
			}
			rptr = rptr->next_def;
		}
	}
	fseek(fd, 0, 0);
	fwrite(index, 1, bytes, fd);
	fclose(fd);
}
