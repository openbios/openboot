/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_printf.c
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
 * Copyright (c) 2000-2003 Sun Microsystems, Inc.
 * All rights reserved.
 * Use is subject to license terms.
 */

#pragma ident	"@(#)prom_printf.c	1.1	00/08/07 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>
#include <sys/varargs.h>

static void _doprint(const char *, va_list, char **);
static void _printn(uint64_t, int, int, int, char **);

/*
 * Emit character functions...
 */

static void
_pput_flush(char *start, char *end)
{
	while (prom_write(prom_stdout_ihandle(), start, end - start) == -1)
		;
}

static void
_sput(char c, char **p)
{
	**p = c;
	*p += 1;
}

/*VARARGS1*/
void
prom_printf(const char *fmt, ...)
{
	va_list adx;

	va_start(adx, fmt);
	_doprint(fmt, adx, (char **)0);
	va_end(adx);
}

void
prom_vprintf(const char *fmt, va_list adx)
{
	_doprint(fmt, adx, (char **)0);
}

/*VARARGS2*/
char *
prom_sprintf(char *s, const char *fmt, ...)
{
	char *bp = s;
	va_list adx;

	va_start(adx, fmt);
	_doprint(fmt, adx, &bp);
	*bp++ = (char)0;
	va_end(adx);
	return (s);
}

char *
prom_vsprintf(char *s, const char *fmt, va_list adx)
{
	char *bp = s;

	_doprint(fmt, adx, &bp);
	*bp++ = (char)0;
	return (s);
}

static void
_doprint(const char *fmt, va_list adx, char **bp)
{
	int32_t b, c, i, pad, width, ells;
	char *s, *start;
	char localbuf[100], *lbp;
	int64_t l;
	uint64_t ul;

	if (bp == 0) {
		bp = &lbp;
		lbp = &localbuf[0];
	}
	start = *bp;
loop:
	width = 0;
	while ((c = *fmt++) != '%') {
		if (c == '\0')
			goto out;
		if (c == '\n') {
			_sput('\r', bp);
			_sput('\n', bp);
			if (start == localbuf) {
				_pput_flush(start, *bp);
				lbp = &localbuf[0];
			}
		} else
			_sput((char)c, bp);
		if (start == localbuf && (*bp - start > 80)) {
			_pput_flush(start, *bp);
			lbp = &localbuf[0];
		}
	}

	c = *fmt++;
	for (pad = ' '; c == '0'; c = *fmt++)
		pad = '0';

	for (width = 0; c >= '0' && c <= '9'; c = *fmt++)
		width = width * 10 + c - '0';

	for (ells = 0; c == 'l'; c = *fmt++)
		ells++;

	switch (c) {
	case 'i':
	case 'd':
	case 'D':
		b = 10;
		if (ells == 0)
			l = (int64_t)va_arg(adx, int);
		else if (ells == 1)
			l = (int64_t)va_arg(adx, int64_t);
		else
			l = (int64_t)va_arg(adx, int64_t);
		if (l < 0) {
			_sput('-', bp);
			width--;
			ul = -l;
		} else
			ul = l;
		goto number;

	case 'p':
		ells = 1;
		/*FALLTHROUGH*/
	case 'x':
	case 'X':
		b = 16;
		goto u_number;

	case 'u':
		b = 10;
		goto u_number;

	case 'o':
	case 'O':
		b = 8;
u_number:
		if (ells == 0)
			ul = (uint64_t)va_arg(adx, uint32_t);
		else if (ells == 1)
			ul = (uint64_t)va_arg(adx, uint64_t);
		else
			ul = (uint64_t)va_arg(adx, uint64_t);
number:
		_printn(ul, b, width, pad, bp);
		break;

	case 'c':
		b = va_arg(adx, int);
		for (i = 24; i >= 0; i -= 8)
			if ((c = ((b >> i) & 0x7f)) != 0) {
				if (c == '\n')
					_sput('\r', bp);
				_sput((char)c, bp);
			}
		break;

	case 's':
		s = va_arg(adx, char *);
		while ((c = *s++) != 0) {
			if (c == '\n')
				_sput('\r', bp);
			_sput((char)c, bp);
			if (start == localbuf && (*bp - start > 80)) {
				_pput_flush(start, *bp);
				lbp = &localbuf[0];
			}
		}
		break;

	case '%':
		_sput('%', bp);
		break;
	}
	if (start == localbuf && (*bp - start > 80)) {
		_pput_flush(start, *bp);
		lbp = &localbuf[0];
	}
	goto loop;
out:
	if (start == localbuf && (*bp - start > 0))
		_pput_flush(start, *bp);
}

/*
 * Printn prints a number n in base b.
 * We don't use recursion to avoid deep kernel stacks.
 */
static void
_printn(uint64_t n, int32_t b, int32_t width, int32_t pad, char **bp)
{
	char prbuf[40];
	char *cp;

	cp = prbuf;
	do {
		*cp++ = "0123456789abcdef"[n%b];
		n /= b;
		width--;
	} while (n);
	while (width-- > 0)
		*cp++ = (char)pad;
	do {
		_sput(*--cp, bp);
	} while (cp > prbuf);
}
