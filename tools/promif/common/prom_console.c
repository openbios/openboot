/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_console.c
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

#pragma ident	"@(#)prom_console.c	1.1	00/08/07 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

/*
 * Return ihandle of stdin
 */
ihandle_t
prom_stdin_ihandle(void)
{
	static ihandle_t istdin = 0;
	static char *name = "stdin";

	if (istdin)
		return (istdin);

	if (prom_getproplen(prom_chosennode(), name) != sizeof (ihandle_t)) {
		return (istdin = (ihandle_t)-1);
	}

	(void) prom_getprop(prom_chosennode(), name, (caddr_t)(&istdin));
	istdin = prom_decode_int(istdin);

	return (istdin);
}

/*
 * Return ihandle of stdout
 */
ihandle_t
prom_stdout_ihandle(void)
{
	static ihandle_t istdout = 0;
	static char *name = "stdout";

	if (istdout)
		return (istdout);

	if (prom_getproplen(prom_chosennode(), name) != sizeof (ihandle_t))  {
		return (istdout = (ihandle_t)-1);
	}

	(void) prom_getprop(prom_chosennode(), name, (caddr_t)(&istdout));
	istdout = prom_decode_int(istdout);
	return (istdout);
}

uchar_t
prom_getchar(void)
{
	int32_t c;

	while ((c = prom_mayget()) == -1)
		;
	return ((uchar_t)c);
}

int
prom_mayget(void)
{
	uint32_t rv;
	char c;

	rv = prom_read(prom_stdin_ihandle(), &c, 1);
	return (rv == 1 ? (int)c : -1);
}

void
prom_putchar(char c)
{
	while (prom_mayput(c) == -1)
		;
}

int
prom_mayput(char c)
{
	/*
	 * prom_write returns the number of bytes that were written
	 */
	if (prom_write(prom_stdout_ihandle(), &c, 1) > 0)
		return (0);
	else
		return (-1);
}
