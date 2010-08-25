/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_string.c
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

#pragma ident	"@(#)prom_string.c	1.1	00/08/07 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

/*
 * a version of string copy that is bounded
 */
char *
prom_strncpy(register char *s1, register char *s2, size_t n)
{
	register char *os1 = s1;

	n++;
	while (--n != 0 && (*s1++ = *s2++) != '\0')
		;
	if (n != 0)
		while (--n != 0)
			*s1++ = '\0';
	return (os1);
}

void *
prom_memccpy(register caddr_t s1, register caddr_t s2, int32_t c, size_t n)
{
	n++;
	while (--n != 0 && (*s1++ = *s2++) != (uchar_t)c)
		;
	if (n == 0)
		return (NULL);
	return ((void *)s1);
}

/*
 * and one that knows no bounds
 */
char *
prom_strcpy(register char *s1, register char *s2)
{
	register char *os1;

	os1 = s1;
	while (*s1++ = *s2++)
		;
	return (os1);
}

void *
prom_memcpy(register caddr_t s1, register caddr_t s2, size_t n)
{
	register caddr_t os1;

	os1 = s1;
	while (n--)
		*s1++ = *s2++;
	return ((void *)os1);
}

/*
 * a copy of string compare that is bounded
 */
int
prom_strncmp(register char *s1, register char *s2, register size_t n)
{
	n++;
	if (s1 == s2)
		return (0);
	while (--n != 0 && *s1 == *s2++)
		if (*s1++ == '\0')
			return (0);
	return ((n == 0) ? 0: (*s1 - s2[-1]));
}

/*
 * and one that knows no bounds
 */
int
prom_strcmp(register char *s1, register char *s2)
{
	while (*s1 == *s2++)
		if (*s1++ == '\0')
			return (0);
	return (*s1 - *--s2);
}

int
prom_memcmp(register caddr_t s1, register caddr_t s2, size_t n)
{
	while (*s1 == *s2++)
		if (n-- == 0)
			return (0);
	return (*s1 - *--s2);
}

/*
 * finds the length of a succession of non-NULL chars
 */
int
prom_strlen(register char *s)
{
	register int32_t n = 0;

	while (*s++)
		n++;

	return (n);
}

/*
 * return the ptr in sp at which the character c last
 * appears; 0 if not found
 */
char *
prom_strrchr(register char *sp, register int32_t c)
{
	register char *r;

	for (r = (char *)0; *sp != (char)0; ++sp)
		if (*sp == c)
			r = sp;
	return (r);
}

/*
 * Concatenate string s2 to string s1
 */
char *
prom_strcat(register char *s1, register char *s2)
{
	char *os1 = s1;

	while ((*s1) != ((char)0))
		s1++;		/* find the end of string s1 */

	while (*s1++ = *s2++)	/* Concatenate s2 */
		;
	return (os1);
}

/*
 * Return the ptr in sp at which the character c first
 * appears; NULL if not found
 */
char *
prom_strchr(register const char *sp, register int32_t c)
{
	do {
		if (*sp == (char)c)
			return ((char *)sp);
	} while (*sp++);
	return (NULL);
}

void *
prom_memchr(register caddr_t sp, register int32_t c, register size_t n)
{
	do {
		if (*sp == (char)c)
			return ((void *)sp);
	} while (n--);
	return (NULL);

}

/*
 * strstr() locates the first occurrence in the string s1 of
 * the sequence of characters (excluding the terminating null
 * character) in the string s2. strstr() returns a pointer
 * to the located string, or a null pointer if the string is
 * not found. If s2 is "", the function returns s1.
 */
char *
prom_strstr(register char *s1, register char *s2)
{
	register char *p = s1;
	register int32_t len = prom_strlen(s2);

	if ((s2 == NULL) || (*s2 == '\0'))
		return ((char *)s1);

	for (; (p = (char *)prom_strchr(p, *s2)) != 0; p++) {
		if (prom_strncmp(p, s2, len) == 0) {
			return (p);
		}
	}
	return (NULL);
}

void *
prom_memset(register caddr_t s, register int c, register size_t n)
{
	register void *os = s;

	while (n--)
		*s++ = (uchar_t)c;
	return ((void *)os);
}
