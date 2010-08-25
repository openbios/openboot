/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: promif.h
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

#ifndef	_SYS_PROMIF_H
#define	_SYS_PROMIF_H

#pragma ident	"@(#)promif.h	1.1	00/08/07 SMI"

#ifdef	__cplusplus
extern "C" {
#endif

#include <sys/types.h>
#include <sys/obpdefs.h>
#include <sys/va_list.h>

/*
 * Device tree and property group
 */
extern	dnode_t		prom_childnode(dnode_t nodeid);
extern	dnode_t		prom_nextnode(dnode_t nodeid);
extern	dnode_t		prom_parentnode(dnode_t nodeid);

extern	int		prom_getproplen(dnode_t nodeid, caddr_t name);
extern	int		prom_getprop(dnode_t nodeid, caddr_t name,
				caddr_t buf);
extern	int		prom_bounded_getprop(dnode_t nodeid, caddr_t name,
				caddr_t buf, int buflen);
extern	int		prom_nextprop(dnode_t nodeid, caddr_t previous,
				caddr_t next);
extern	int		prom_setprop(dnode_t nodeid, caddr_t name,
				caddr_t buf, int buflen);

extern	phandle_t	prom_getphandle(ihandle_t instance);
extern	int		prom_pathname(char *pathname);
extern	dnode_t		prom_finddevice(char *path);

extern	int		prom_ihandle_to_path(ihandle_t instance, char *buf,
				uint_t buflen);
extern	int		prom_phandle_to_path(phandle_t package, char *buf,
				uint_t buflen);

/*
 * Device I/O group
 */
extern  ihandle_t	prom_open(char *name);
extern  int		prom_close(ihandle_t fd);
extern  uint32_t	prom_read(ihandle_t fd, caddr_t buf, uint32_t len);
extern  uint32_t	prom_write(ihandle_t fd, caddr_t buf, uint32_t len);
extern	int		prom_seek(ihandle_t fd, u_longlong_t offset);

/*
 * Control transfer group
 */
extern	void		prom_enter_mon(void);
extern	void		prom_exit_to_mon(void);
extern	void		prom_reboot(char *bootstr);

/*
 * Resource allocation group
 */
extern	caddr_t		prom_malloc(caddr_t virt, size_t size, uint_t align);
extern	void		prom_free(caddr_t virt, size_t size);

/*
 * Console I/O group
 */
extern	uchar_t		prom_getchar(void);
extern	void		prom_putchar(char c);
extern	int		prom_mayget(void);
extern	int		prom_mayput(char c);

extern	void		prom_printf(const char *fmt, ...);
extern	void		prom_vprintf(const char *fmt, __va_list adx);
extern	char		*prom_sprintf(char *s, const char *fmt, ...);
extern	char		*prom_vsprintf(char *s, const char *fmt, __va_list adx);

/*
 * Standard system nodes
 */
extern	dnode_t		prom_aliasnode(void);
extern	dnode_t		prom_chosennode(void);
extern	dnode_t		prom_rootnode(void);

/*
 * Special device nodes
 */
extern	ihandle_t	prom_stdin_ihandle(void);
extern	ihandle_t	prom_stdout_ihandle(void);
extern	ihandle_t	prom_memory_ihandle(void);
extern	ihandle_t	prom_mmu_ihandle(void);

/*
 * Test for existance of a specific service or method
 */
extern	int		prom_test(char *service);
extern	int		prom_test_method(char *method, dnode_t node);

/*
 * Standard device node properties
 */
extern	int		prom_nodename(dnode_t id, char *name);
extern	int		prom_devicetype(dnode_t id, char *type);

/*
 * promif tree search routines
 */
extern	dnode_t		prom_findnode_byname(dnode_t node, char *name);
extern	dnode_t		prom_findnode_bydevtype(dnode_t node, char *type);

/*
 * User interface group
 */
extern	void		prom_interpret(char *str, uintptr_t arg1,
			    uintptr_t arg2, uintptr_t arg3, uintptr_t arg4,
			    uintptr_t arg5);
extern	void		*prom_set_callback(void *handler);
extern	void		prom_set_symbol_lookup(void *sym2val, void *val2sym);

/*
 * Promif support group
 */
extern	void		prom_init(char *progname, void *p1275cif_cookie);
extern	void		prom_panic(char *string);

/*
 * Miscellaneous
 */
extern	uint_t		prom_gettime(void);
extern	char		*prom_bootpath(void);
extern	char		*prom_bootargs(void);

/*
 * Utility functions
 */
extern	char		*prom_decode_composite_string(void *buf,
			    size_t buflen, char *prev);

#ifdef	__cplusplus
}
#endif

#endif /* _SYS_PROMIF_H */
