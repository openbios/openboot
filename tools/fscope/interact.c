/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: interact.c
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
 * @(#)interact.c 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Copyright Use is subject to license terms.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <curses.h>

#include "fscope.h"

typedef struct ISTRUCT_T {
	WINDOW *win;		/* main screen */
	int info_line;		/* line# for information text */
	int cmdnum;		/* command selected */
	int lmargin;		/* left margin of selected command */
	int col;		/* cursor position on cmd line */
	int line;		/* which line we are on */
	int error;		/* error status, status string contains msg */
	char *status;		/* status message */
	char *input_line;	/* input buffer, at least as wide as screen */
	int ipoint;		/* insertion point */
	int ilen;		/* current command length */
	int matches;		/* number of matches found */
	int start;		/* offset within matches */
	int tag_mode;		/* tag_mode status */
	int tagged;		/* number of things tagged */
	search_t *tags;		/* list of tagged matches */
	search_t *items[9];	/* the 1-9 items on the screen */
	search_t *list;		/* current match list */
	search_t *displaying;	/* where we are displaying in the above list */
} istruct_t;

#define	NUM_COMMANDS	(sizeof (commands) / sizeof (command_t))

typedef struct COMMAND_T {
	char *id;
	int cursor;
	int line;
	void (*finder)(extract_t *info, istruct_t *w);
} command_t;

#define	DEBUG
#define	CONTROL	-('A'-1) +

#ifdef DEBUG
#define	DEBUGL(y, x)	move(y, 0); clrtoeol(); printw x; refresh();
#else
#define	DEBUGL(y, x)
#endif

static void
free_tag(istruct_t *w, search_t *item)
{
	search_t *tag = item->private;
	search_t *next, *prev;

	if (tag == NULL)
		return;
	next = tag->next;
	prev = tag->prev;
	if (tag->next != NULL) {
		tag->next->prev = prev;
	}
	if (prev != NULL) {
		prev->next = next;
	} else {
		w->tags = tag->next;
	}
	free(tag);
	w->tagged--;
	item->private = NULL;
}

static void
tag_item(istruct_t *w, search_t *item)
{
	search_t *new;

	if (item->private == NULL) {
		new = new_search_t();
		new->xref = item->xref;
		new->next = w->tags;
		new->prev = NULL;
		new->private = item;
		if (w->tags != NULL) {
			w->tags->prev = new;
		}
		w->tags = new;
		w->tagged++;
		item->private = new;
	} else {
		free_tag(w, item);
		item->private = NULL;
	}
}

static void
cancel_tags(istruct_t *w)
{
	search_t *ptr, *next;

	w->tag_mode = 0;
	w->tagged = 0;
	ptr = w->tags;
	while (ptr) {
		next = ptr->next;
		free_tag(w, ptr->private);
		ptr = next;
	}
	w->tags = NULL;
}

static void
find_exact_definition(extract_t *info, istruct_t *w)
{
	search_t *list;

	info->symbol = w->input_line;
	info->flags &= ~FLAG_REGEXP;
	w->list = build_searchlist(info, NULL,
	    (XREF_DEFINITION | XREF_FORWARD));
}

static void
find_regexp_definition(extract_t *info, istruct_t *w)
{
	info->symbol = w->input_line;
	info->flags |= FLAG_REGEXP;
	w->list = build_searchlist(info, NULL,
	    (XREF_DEFINITION | XREF_FORWARD));
}

static void
find_file(extract_t *info, istruct_t *w)
{
	xref_file_t *fptr = info->state->sources;
	search_t *new, *list = NULL;
	xref_t *xref;

	info->symbol = w->input_line;

	while (fptr != NULL) {
		if (strstr(fptr->name, info->symbol) != NULL) {
			int i, j;

			xref = NULL;
			for (i = 0; ((i < 128) && (xref == NULL)); i++) {
				xref = fptr->defs[i];
			}
			new = new_search_t();
			new->xref = xref;
			new->next = list;
			list = new;
		}
		fptr = fptr->next;
	}
	w->list = list;
}

static void
find_callers_of(extract_t *info, istruct_t *w)
{
	search_t *list, *item;
	search_t *callers;
	int j;
	xref_t *xref;
	ref_t *rref;

	info->symbol = w->input_line;
	info->flags &= ~FLAG_REGEXP;
	if (w->tag_mode) {
		item = w->tags;
	} else {
		item = build_searchlist(info, NULL, XREF_DEFINITION);
		if (item == NULL) {
			return;
		}
		if (item->next != NULL) {
			w->status = "more than one defintion, "
			    "refine your search using a tag";
			w->error = 1;
			free_searchlist(item);
			w->list = NULL;
			return;
		}
	}
	ASSERT((item != NULL), "tagged with item NULL??");
	list = NULL;
	while (item != NULL) {
		xref = item->xref;
		rref = &xref->called_by;
		for (j = 0; j < rref->insert; j++) {
			callers = new_search_t();
			callers->xref = rref->ptr[j];
			callers->next = list;
			list = callers;
		}
		item = item->next;
	}
	if (w->tag_mode) {
		cancel_tags(w);
	} else {
		free_searchlist(item);
	}
	w->list = list;
}

static void
find_text_string(extract_t *info, istruct_t *w)
{
	search_t *list;

	info->symbol = w->input_line;
	info->flags |= FLAG_REGEXP;
	w->list = build_searchlist(info, NULL,
	    (XREF_STRING | XREF_DEFINITION));
}

command_t commands[] = {
	{ "Find definition:",		0, 0, find_exact_definition },
	{ "Find fuzzy definition:",	0, 1, find_regexp_definition },
	{ "Find callers of routine:",	0, 2, find_callers_of },
	{ "Find text string:",		0, 3, find_text_string },
	{ "Change text string:",	0, 4, NULL },
	{ "Change definition name:",	0, 5, NULL },
	{ "Find file:",			0, 6, find_file },
};

static void
draw_command(extract_t *info, istruct_t *w)
{
	static int computed_pos = 0;
	int i;
	command_t *cptr;

	if (!computed_pos) {
		for (i = 0; i < NUM_COMMANDS; i++) {
			cptr = &commands[i];
			if (cptr->cursor == 0) {
				cptr->cursor = strlen(cptr->id)+1;
				cptr->line += (LINES - NUM_COMMANDS);
			}
		}
		w->info_line = commands[0].line -1;
		computed_pos = 1;
	}
	move(commands[0].line, 0);
	clrtobot();

	for (i = 0; i < NUM_COMMANDS; i++) {
		cptr = &commands[i];
		mvprintw(cptr->line, 0, cptr->id);
	}
	w->col = commands[w->cmdnum].cursor;
	w->line = commands[w->cmdnum].line;
	w->lmargin = w->col;
	move(w->line, w->col);
	refresh();
}

static void
hit_counter(extract_t *info, search_t *item)
{
	int *iptr = info->private;
	(*iptr)++;
}

static char *
run_search(extract_t *info, istruct_t *w)
{
	if ((w->ilen == 0) && !w->tag_mode) {
		return ("Nothing to Do");
	}
	if (commands[w->cmdnum].finder != NULL) {
		w->matches = 0;
		w->start = 0;
		w->error = 0;
		commands[w->cmdnum].finder(info, w);
		if (w->error == 0) {
			info->private = &w->matches;
			w->displaying = w->list;
			iterate_list(info, w->list, hit_counter);
			if (w->matches == 0) {
				return ("Nothing Found");
			}
			return ("");
		}
		return (w->status);
	}
	return ("<unimplemented command>");
}

static void
match_mode(extract_t *info, istruct_t *w, int c)
{
	int i;
	search_t *this;
	search_t *selected;

redraw:
	selected = NULL;
	for (i = 0; i < 9; i++) {
		move(i, 0);
		clrtoeol();
		w->items[i] = NULL;
	}
	i = 0;
	this = w->displaying;
	while ((i < 9) && (this != NULL)) {
		w->items[i] = this;
		mvprintw(i, 0, " %d%c[%c%c%c] %s:%d .. %s ..\n",
		    ((i+1)%10),
		    ((this->private == NULL) ? ' ' : '>'),
		    ((this->xref->flags & XREF_FORWARD) ? 'F' : '.'),
		    ((this->xref->flags & XREF_DEFINITION) ? 'D' : '.'),
		    ((this->xref->flags & XREF_STRING) ? 'S' : '.'),
		    expand_filename(info, this->xref),
		    this->xref->linenum,
		    this->xref->name);
		this = this->next;
		i++;
	}
	refresh();
	if (c == 't') {
		if (w->tag_mode) {
			w->tag_mode = 0;
		} else {
			w->tag_mode = 1;
		}
		return;
	}
	if (c == ' ') {
		if (w->matches > 9) {
			if ((w->start + i) == w->matches) {
				w->start = 0;
				w->displaying = w->list;
			} else {
				w->displaying = this;
				w->start += i;
			}
		}
		c = 0;
		goto redraw;
	}
	if ((c > '0') && (c <= '9')) {
		selected = w->items[c-'1'];
		if (w->tag_mode) {
			tag_item(w, selected);
			c = 0;
			goto redraw;
		} else
			goto selected;
	}
	if (((c == '*') || (c == '&')) && (w->tag_mode)) {
		int i;
		search_t *this;
		for (i = 0; i < 9; i++) {
			this = w->items[i];
			if (this != NULL) {
				if (c == '&') {
					free_tag(w, this);
				} else {
					tag_item(w, this);
				}
			}
		}
		c = 0;
		goto redraw;
	}
	if ((c == 0x4)) {
		/* Control D */
		free_searchlist(w->list);
		w->list = NULL;
		w->displaying = NULL;
		w->start = 0;
		w->matches = 0;
		if (w->tagged == 0) {
			w->tag_mode = 0;
		}
		return;
	}
	if (c == 0x1b) {
		/* Escape. */
		cancel_tags(w);
		free_searchlist(w->list);
		w->list = NULL;
		w->displaying = NULL;
		w->start = 0;
		w->matches = 0;
		return;
	}
selected:
	if (selected && !w->tag_mode) {
		char *syscommand;
		int bytes;
		char *file;
		char *editor;

		editor = getenv("EDITOR");
		if (editor == NULL) {
			editor = "/bin/vi";
		}
		bytes = strlen(editor);
		file = expand_filename(info, selected->xref);
		bytes += strlen(file);
		bytes += 20;
		syscommand = malloc(bytes);
		snprintf(syscommand, bytes, "%s +%d %s",
		    editor, selected->xref->linenum,
		    file);
		endwin();
		system(syscommand);
		refresh();
		free(syscommand);
	}
}

static char *
select_mode(extract_t *info, istruct_t *w, int c)
{
	char *tstatus;

	tstatus = "";

	switch (c) {
	case CONTROL 'B':
	case KEY_LEFT:
		if (w->ipoint) {
			w->ipoint--;
			w->col--;
		}
		if (0) move(w->line, w->col);
		break;

	case CONTROL 'F':
	case KEY_RIGHT:
		if (w->ipoint < w->ilen) {
			w->ipoint++;
			w->col++;
		}
		if (0) move(w->line, w->col);
		break;

	case CONTROL 'P':
	case KEY_UP:
		if (w->cmdnum)
			w->cmdnum--;
		else
			w->cmdnum = NUM_COMMANDS-1;
		w->ipoint = 0;
		w->ilen = 0;
		draw_command(info, w);
		break;

	case CONTROL 'N':
	case CONTROL 'I':
	case KEY_DOWN:
		if (w->cmdnum < (NUM_COMMANDS-1))
			w->cmdnum++;
		else
			w->cmdnum = 0;
		w->ipoint = 0;
		w->ilen = 0;
		draw_command(info, w);
		break;

	case CONTROL 'M':
	case CONTROL 'J':
		w->status = run_search(info, w);
		if (w->matches) {
			match_mode(info, w, 0);
		}
		break;

	case CONTROL 'A':
		w->ipoint = 0;
		w->col = w->lmargin;
		if (0) move(w->line, w->col);
		break;

	case 127:
	case CONTROL 'H':
		if (w->ipoint > 0) {
			char *here = w->input_line + w->ipoint;
			memcpy(here-1, here, (w->ilen - w->ipoint)+1);
			w->ilen--;
			w->col--;
			w->ipoint--;
		}
		move(w->line, w->col);
		clrtoeol();
		mvprintw(w->line, w->lmargin, w->input_line);
		if (0) move(w->line, w->col);
		break;

	case CONTROL 'D':
		if (w->ipoint < w->ilen) {
			char *here = w->input_line + w->ipoint;
			memcpy(here, here+1, (w->ilen - w->ipoint));
			w->ilen--;
		}
		move(w->line, w->col);
		clrtoeol();
		mvprintw(w->line, w->lmargin, w->input_line);
		if (0) move(w->line, w->col);
		break;

	case CONTROL 'E':
		w->ipoint = w->ilen;
		w->col = w->lmargin + w->ilen;
		if (0) move(w->line, w->col);
		break;

	case CONTROL 'K':
		w->input_line[w->ipoint] = 0;
		clrtoeol();
		mvprintw(w->line, w->lmargin, w->input_line);
		if (0) move(w->line, w->col);
		break;

	case 0x1b:
		/* Escape, cancel all tags etc */
		cancel_tags(w);
		break;

	default:
		if ((c >= ' ') && (c <= 'z')) {
			mvprintw(w->line, w->col, "%c", c);
			if (w->col < (COLS-2)) {
				w->input_line[w->ipoint++] = c;
				w->col++;
			}
			if (w->ipoint > w->ilen) {
				w->input_line[w->ipoint] = 0;
				w->ilen = w->ipoint;
			}
		}
		break;
	}
	return (tstatus);
}

void
xref_interactive_mode(extract_t *info)
{
	istruct_t *w;
	int c;
	char *tstatus;
	char add_status[20];

	w = malloc(sizeof (istruct_t));
	memset(w, 0, sizeof (istruct_t));
	w->win = initscr();
	w->cmdnum = 0;
	clear();
	cbreak();
	noecho();
	keypad(w->win, 1);
	mvprintw(0, 0, "match window");
	refresh();

	draw_command(info, w);
	c = 0;
	w->ipoint = 0;
	w->ilen = 0;
	w->matches = 0;
	w->input_line = malloc(COLS);
	w->input_line[w->ipoint] = 0;
	w->status = "";
	w->tags = NULL;
	w->displaying = NULL;
	w->list = NULL;
	while (c != EOF) {
		move(w->info_line, 0);
		clrtoeol();
		add_status[0] = 0;
		if (w->tag_mode) {
			snprintf(add_status, sizeof (add_status),
			    "[Tagged:%d]", w->tagged);
		}
		if (w->matches) {
			int upper, rem;

			rem = w->matches - w->start;
			if (rem > 9) {
				upper = w->start + 9;
				rem -= 9;
			} else {
				upper = w->start + rem;
				rem = 0;
			}
			if (!rem) {
				mvprintw(w->info_line, 0,
				    "Status %s: displaying %d-%d"
				    " [press ESC to exit]",
				    add_status, (w->start+1), upper);
			} else {
				mvprintw(w->info_line, 0,
				    "Status %s: displaying %d-%d, %d more"
				    " [press SPACE for more, ESC to exit]",
				    add_status, (w->start+1), upper, rem);
			}
		} else {
			mvprintw(w->info_line, 0,
			    "Select %s mode: %s", add_status, w->status);
		}
		c = mvgetch(w->line, w->col);
		w->status = "";

		if (w->matches)
			match_mode(info, w, c);
		else
			tstatus = select_mode(info, w, c);
		refresh();
	}

	nocbreak();
	echo();
	keypad(w->win, 0);
}
