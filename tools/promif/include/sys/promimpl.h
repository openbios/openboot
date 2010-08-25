/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: promimpl.h
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
 * Copyright (c) 2000, 2003 Sun Microsystems, Inc. All rights reserved.
 * Use is subject to license terms.
 */

#ifndef	_SYS_PROMIMPL_H
#define	_SYS_PROMIMPL_H

#pragma ident	"@(#)promimpl.h	1.1	03/04/01 SMI"

#include <sys/types.h>
#include <sys/prom_isa.h>
#include <sys/prom_plat.h>

#ifdef	__cplusplus
extern "C" {
#endif

/*
 * IEEE 1275 Routines defined by each platform using IEEE 1275:
 */
extern	void		*p1275_cif_init(void *);
extern	int		p1275_cif_call(void *);

/*
 *  flashprom map-in function
 */

extern void *flashprom_mapin(ihandle_t ihandle, uint_t a, uint_t b,
	uint_t size);

/*
 * Client program name used to print out "panic" level messages.
 */
extern	char		promif_clntname[];

/*
 *  defualt lookup table for unix->obp path translations
 */

/*
 * Private utility routines.
 */
extern	char		*prom_strcpy(char *s1, char *s2);
extern	char		*prom_strncpy(char *s1, char *s2, size_t n);
extern	int		prom_strcmp(char *s1, char *s2);
extern	int		prom_strncmp(char *s1, char *s2, size_t n);
extern	int		prom_strlen(char *s);
extern	char		*prom_strrchr(char *s, int c);
extern	char		*prom_strcat(char *s1, char *s2);
extern	char		*prom_strchr(const char *s, int c);
extern	char		*prom_strstr(char *s1, char *s2);

extern void		*prom_memccpy(caddr_t s1, caddr_t s2, int c, size_t n);
extern void		*prom_memchr(caddr_t s, int c, size_t n);
extern int		prom_memcmp(caddr_t s1, caddr_t s2, size_t n);
extern void		*prom_memcpy(caddr_t s1, caddr_t s2, size_t n);
extern void		*prom_memset(caddr_t s, int c, size_t n);

#ifdef	__cplusplus
}
#endif

#endif /* !_SYS_PROMIMPL_H */
