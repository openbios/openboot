/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: fscope.c
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
 * @(#)fscope.c 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <regexpr.h>

#include "fscope.h"

static char *help_msg =
"fscope -f <index-file> [flags]\n"
"   Flags:\n"
"     -f <file>   :  source index file, (default is fscope.idx)\n"
"     -m <mode>   :  is the data format written to <output> or stdout\n"
"     -o <output> :  spacify the target for a extract (-e) operation\n"
"     -t <text>   :  extract any reference matching <text>\n"
"     -s <text>   :  extract only string references matching <text>\n"
"     -d <symbol> :  extract definitions matching <symbol>\n"
"     -c <symbol> :  extract the caller information for <symbol>\n"
"     -C <symbol> :  extract the symbols called by <symbol>\n"
"     -l <value>  :  extract symbols with refcounts less than <value>\n"
"     -g <value>  :  extract symbols with refcounts greater than <value>\n"
"     -a          :  extract all symbols in <mode> format\n"
"     -e          :  expand path using getenv()\n"
"     -r          :  use regexp to do symbol matching\n"
"     -R <root>   :  replace symbolic ${..} with <root>\n"
"     -i          :  interactive mode\n"
"     -v          :  verbose mode\n"
"     -O <file>   :  write current index file as <file>\n";

static void
extract_noop(extract_t *info)
{
	/* do nothing */
}

output_mode_t outputmodes[] = {
	{ "grep", 	extract_noop, xref_grep_format, extract_noop },
	{ "tag",	xref_tag_init, xref_tag_format, xref_tag_fini },
	{ "etag",	xref_tag_init, xref_etag_format, xref_tag_fini },
	{ NULL,		NULL }
};

static void
usage(void)
{
	output_mode_t *mptr = outputmodes;

	printf(help_msg);
	printf("\nSupported <modes> for -m are: ");
	while (mptr->name != NULL) {
		if (mptr->name[0] != '!') {
			printf("%s ", mptr->name);
		}
		mptr++;
	}
	printf("\n");
}

char *
expand_filename(extract_t *info, xref_t *cref)
{
	char *file = cref->file->name;

	if (info->flags & FLAG_ABS_PATH) {
		char *bp;
		char *bp_env = "${BP}";
		char *base;
		if (info->root_buf != NULL) {
			free(info->root_buf);
			info->root_buf = NULL;
		}
		bp = strstr(file, bp_env);
		if (bp == NULL) {
			bp = file;
		} else {
			bp += strlen(bp_env);
		}
		if (info->root == NULL) {
			base = getenv("BP");
			if (base == NULL) {
				base = "";
			}
		} else {
			base = info->root;
		}
		file = info->root_buf = malloc(strlen(base) + strlen(bp) + 1);
		sprintf(file, "%s%s", base, bp);
	}
	return (file);
}

static output_mode_t *
select_output_mode(char *type)
{
	output_mode_t *mptr = outputmodes;
	output_mode_t *found = NULL;

	while (mptr->name != NULL) {
		if (strcmp(mptr->name, type) == 0) {
			found = mptr;
			break;
		}
		mptr++;
	}
	return (found);
}

static int
limit_item(extract_t *info, search_t *item)
{
	xref_t *cref = item->xref;

	if ((cref->called_by.insert < info->lo) &&
	    (cref->called_by.insert > info->hi))
		return (1);

	return (0);
}

static void
extract_item(extract_t *info, search_t *item)
{
	info->extract->update(info, item->xref);
}

static void
dump_refs(extract_t *info, xref_t *cref, ref_t *rref)
{
	int j;
	for (j = 0; j < rref->insert; j++) {
		info->extract->update(info, rref->ptr[j]);
	}
}

static void
dump_callers(extract_t *info, search_t *item)
{
	xref_t *cref;

	cref = item->xref;
	dump_refs(info, cref, &cref->called_by);
}

static void
dump_calls(extract_t *info, search_t *item)
{
	xref_t *cref;

	cref = item->xref;
	dump_refs(info, cref, &cref->calls);
}

int
main(int argc, char *argv[])
{
	extern char *optarg;
	extern int optind;
	int c;
	extract_t info;
	search_t *list = NULL;
	char *options = "hf:m:d:c:C:o:il:g:as:erR:t:v";
	info.lo = -1;
	info.hi = -1;
	info.flags = 0;
	info.symbol = NULL;
	info.state = NULL;
	info.indexfile = NULL;
	info.outputfile = NULL;
	info.private = NULL;
	info.root = NULL;

	info.extract = select_output_mode("grep");
	while ((c = getopt(argc, argv, options)) != EOF)
		switch (c) {

		case 'h':
			usage();
			exit(1);
			break;

		case 'm':
			info.extract = select_output_mode(optarg);
			if (info.extract == NULL) {
				fprintf(stderr,
				    "Unsupported extract mode: %s\n",
				    optarg);
				usage();
				exit(1);
			}
			break;

		case 'f':
			info.indexfile = optarg;
			break;

		case 'd':
			info.symbol = optarg;
			info.type = TYPE_DEFINE;
			break;

		case 's':
			info.symbol = optarg;
			info.type = TYPE_STRING;
			break;

		case 't':
			info.symbol = optarg;
			info.type = TYPE_TEXT;
			break;

		case 'c':
			info.symbol = optarg;
			info.type = TYPE_CALLERS;
			break;

		case 'C':
			info.symbol = optarg;
			info.type = TYPE_CALLS;
			break;

		case 'o':
			info.outputfile = optarg;
			break;

		case 'r':
			info.flags |= FLAG_REGEXP;
			break;

		case 'i':
			info.type = TYPE_INTERACT;
			info.extract = select_output_mode("!interact");
			break;

		case 'l':
			info.type = TYPE_LIMIT;
			info.lo = atoi(optarg);
			break;

		case 'g':
			info.type = TYPE_LIMIT;
			info.hi = atoi(optarg);
			break;

		case 'a':
			info.type = TYPE_LIMIT;
			info.hi = -1;
			info.lo = 100000;
			break;

		case 'R':
			info.flags |= FLAG_ABS_PATH;
			info.root = optarg;
			break;

		case 'e':
			info.flags |= FLAG_ABS_PATH;
			info.root = NULL;
			break;

		case 'v':
			info.flags |= FLAG_VERBOSE;
			break;

		default:
			break;
		}

	if (info.indexfile == NULL) {
		info.indexfile = "fscope.idx";
	}
	info.state = xref_load_file(info.indexfile,
	    (info.flags & FLAG_VERBOSE));
	if (info.state == NULL) {
		fprintf(stderr, "%s: failed to load\n", info.indexfile);
		exit(1);
	}
	if (info.type == TYPE_INTERACT) {
		xref_interactive_mode(&info);
	} else {
		if (info.outputfile == NULL) {
			info.outfd = stdout;
		} else {
			info.outfd = fopen(info.outputfile, "w");
			if (info.outfd == NULL) {
				fprintf(stderr, "Can create outputfile: %s\n",
				    info.outputfile);
				exit(1);
			}
		}
		info.extract->init(&info);
		switch (info.type) {
		case TYPE_LIMIT:
			if (info.symbol == NULL) {
				info.symbol = ".*";
				info.flags |= FLAG_REGEXP;
			}
			list = build_searchlist(&info, NULL, XREF_DEFINITION);
			list = search_list(&info, 1, list, limit_item);
			iterate_list(&info, list, extract_item);
			break;

		case TYPE_CALLS:
			list = build_searchlist(&info, NULL, XREF_DEFINITION);
			iterate_list(&info, list, dump_calls);
			break;

		case TYPE_CALLERS:
			list = build_searchlist(&info, NULL, XREF_DEFINITION);
			iterate_list(&info, list, dump_callers);
			break;

		case TYPE_DEFINE:
			list = build_searchlist(&info, NULL, XREF_DEFINITION);
			iterate_list(&info, list, extract_item);
			break;

		case TYPE_STRING:
			list = build_searchlist(&info, NULL, XREF_STRING);
			iterate_list(&info, list, extract_item);
			break;

		case TYPE_TEXT:
			list = build_searchlist(&info, NULL,
			    (XREF_STRING | XREF_DEFINITION));
			iterate_list(&info, list, extract_item);
			break;

		default:
			break;
		}
		if (list != NULL) {
			free_searchlist(list);
			list = NULL;
		}
		info.extract->fini(&info);
		if (info.outputfile != NULL) {
			fclose(info.outfd);
		}
	}
	xref_free_state(info.state);
	return (0);
}
