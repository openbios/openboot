/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: termcap.c
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
 * termcap.c 2.5 01/05/18
 * Copyright 1985-1990 Bradley Forthware
 * Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved
 */

/*
 * Interface to the Unix "termcap" facility for use by Forthmacs running
 * under the C wrapper program.
 * Operations:
 *
 * int t_init()		Called once to initialize things.  Returns 0 if
 *			okay, nonzero if an error occurred.
 *
 * t_op(op)		"Generic" no-arguments terminal operation.  Op is
 *			a number between 0 and 12, corresponding to an
 *			operation in the "opnames" table.
 *
 * t_move(col, row)	Move the cursor to the indicated postion. (0 origin)
 *
 * int t_rows()		The number of rows (lines) on the terminal screen
 *
 * int t_cols()		The number of columns on the terminal screen
 */

#include <stdio.h>
#include <stdlib.h>

#ifdef SYS5
#include <curses.h>
#include <term.h>
#endif SYS5

char *opnames[] = {
	"",		/* 0 left */
	"nd",	/* 1 right */
	"up",	/* 2 up */
	"do",	/* 3 down */
	"ic",	/* 4 insert char */
	"dc",	/* 5 delete char */
	"ce",	/* 6 clear rest of line */
	"cd",	/* 7 clear rest of screen */
	"al",	/* 8 insert line */
	"dl",	/* 9 delete line */
	"cl",	/* 10 clear screen */
	"so",	/* 11 start stand-out mode */
	"se",	/* 12 end stand-out mode */
	"cm",	/* 13 move cursor */
};
char *opstrings[14];

#define	TCAPSLEN 315

extern char *tgoto();
char tcapbuf[TCAPSLEN];

char PC;

#define	PUTC ((int (*)(char))putchar)

static void
putstring(char *str)
{
	char c;

	while (c = *str++)
		PUTC(c);
	fflush(stdout);
}

static int t_inited;
static int nrows = 24;
static int ncols = 80;

void
t_op(int op)
{
	tputs(opstrings[op], 1, PUTC);
}

void
t_move(int col, int row)
{
	tputs(tgoto(opstrings[13], col, row), 1, PUTC);
}

int
t_rows(void)
{
	return (nrows);
}

int
t_cols(void)
{
	return (ncols);
}

int
t_init(void)
{
	char *getenv();
	char *t, *p, *tgetstr();
	char tcbuf[1024];
	char *tv_stype;
	int  i, num;

	if (t_inited)
		return (0);

	if ((tv_stype = getenv("TERM")) == 0) {
		putstring("Environment variable TERM not defined!\n");
		return (-1);
	}

	if ((tgetent(tcbuf, tv_stype)) != 1) {
		putstring("Unknown terminal type ");
		putstring(tv_stype);
		putstring("\n");
		if ((tgetent(tcbuf, "dumb")) != 1)	/* Default to "dumb" */
			return (-2);
	}

	p = tcapbuf;
	t = tgetstr("pc", &p);
	if (t)
		PC = *t;

	/* Entry 0 (left) is a special case */
	i = 0;
	if (tgetflag("bs")) {
		opstrings[0] = "\b";
		i = 1;
	}

	for (; i <= 13; i++) {
		t = tgetstr(opnames[i], &p);
		opstrings[i] = t ? t : "";
	}

	/* Unfortunately, the tty driver may turn the lf into crlf. Sigh. */
	if (*opstrings[3] == '\0')
		opstrings[3] = "\12";

	if ((num = tgetnum("li")) != -1)
		nrows = num - 1;
	if ((num = tgetnum("co")) != -1)
		ncols = num;

	if (p >= &tcapbuf[TCAPSLEN]) {
		putstring("Terminal description too big!\n");
		return (-3);
	}

	t_inited = 1;
	return (0);
}
