/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: defines.c
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
 * @(#)defines.c 1.3 03/08/20
 * Copyright 2001-2003 Sun Microsystems, Inc.  All Rights Reserved
 * Copyright Use is subject to license terms.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "defines.h"

static define_t *symbol_root = NULL;

/* find a symbol by name and return a pointer to it or NULL if not found */
static define_t *
find_symbol(char *name)
{
	define_t *found = NULL;
	define_t *ptr = symbol_root;

	while (ptr != NULL) {
		if (strcmp(ptr->name, name) == 0) {
			found = ptr;
			break;
		}
		ptr = ptr->next;
	}
	return (found);
}

/*
 * define a symbol, the data part follows the optional '=' sign.
 * the type is just used to track where the symbol was defined - on the
 * command line or by upload from the forth engine.
 */
void
define_symbol(char *name, int type)
{
	char *sname, *tname;
	char *valuep;
	define_t *new;

	tname = strdup(name);
	valuep = strchr(tname, '=');
	if (valuep != NULL) {
		*valuep = 0;
		valuep = strdup(valuep+1);
		name = strdup(tname);
		free(tname);
	} else {
		name = strdup(name);
	}
	new = find_symbol(name);
	if (new != NULL) {
		if ((new->type != FORTH_UNDEF) && (new->type != CMD_UNDEF)) {
			fprintf(stderr, "Warning redefining %s\n", name);
		}
		if (new->value != NULL) {
			free(new->value);
		}
		new->value = valuep;
		new->type = type;
		free(name);
	} else {
		new = malloc(sizeof (define_t));
		new->name = name;
		new->next = symbol_root;
		new->prev = NULL;
		new->value = valuep;
		new->type = type;
		if (symbol_root != NULL) {
			symbol_root->prev = new;
		}
		symbol_root = new;
	}
}

/*
 * 'un'def a symbol, type tracks where the 'undef' was executed from
 * either the command line or the forth engine.
 */
void
undef_symbol(char *name, int type)
{
	define_t *which, *prev, *next;

	which = find_symbol(name);
	if (which != NULL) {
#if 0
		prev = which->prev;
		next = which->next;
		if (prev != NULL) {
			prev->next = which->next;
		} else {
			symbol_root = next;
		}
		next->prev = which->prev;
		if (which->value != NULL) {
			free(which->value);
		}
		free(which);
#endif
		which->type = type;
	} else {
		define_symbol(name, type);
	}
}

/* return true/false to test for a symbol existence */
int
symbol_defined(char *name)
{
	define_t *found;

	found = find_symbol(name);

	return ((found != NULL) &&
	    (found->type != FORTH_UNDEF) &&
	    (found->type != CMD_UNDEF));
}

/* return a pointer to a symbols data, return NULL if there is none. */
char *
extract_symbol(char *name)
{
	char *valuep = NULL;
	define_t *which;

	which = find_symbol(name);
	if (which != NULL) {
		valuep = which->value;
	}
	return (valuep);
}

/* a debug routine to show a symbol, its data and where is was defined */
static void
show_symbol(define_t *ptr)
{
	char *value;
	char *type;

	switch (ptr->type) {
	case CMD_DEFINE:
		type = "[cmd line, defined]";
		break;

	case CMD_UNDEF:
		type = "[cmd line, undef]";
		break;

	case FORTH_DEFINE:
		type = "[Forth defined]";
		break;

	case FORTH_UNDEF:
		type = "[Forth undefined]";
		break;
	default:
		type = "[invalid define type]";
		break;
	}
	if (ptr->value == NULL) {
		value = "[Boolean]";
	} else {
		value = ptr->value;
	}
	fprintf(stderr, "%-20.20s %-20.20s %s\n", ptr->name, type, value);
}

/*
 * release all resources used by symbols, optionally printing the information
 * about the symbol use - called when the wrapper exits.
 */
void
finish_symbols(int show)
{
	define_t *ptr = symbol_root;

	if (show) {
		fprintf(stderr, "%-20.20s %-20.20s %s\n",
		    "Symbols", "location", "type/value");
	}
	while (ptr != NULL) {
		define_t *next = ptr->next;
		if (show) {
			show_symbol(ptr);
		} else {
			if (ptr->value != NULL) {
				free(ptr->value);
			}
			free(ptr->name);
			free(ptr);
		}
		ptr = next;
	}
	if (!show) {
		symbol_root = NULL;
	}
}
