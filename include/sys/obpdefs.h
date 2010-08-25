/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: obpdefs.h
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

#ifndef	_SYS_OBPDEFS_H
#define	_SYS_OBPDEFS_H

#pragma ident	"@(#)obpdefs.h	1.1	03/04/01	SMI"

#ifdef	__cplusplus
extern "C" {
#endif

#include <sys/types.h>

typedef	uint32_t 	ihandle_t;
typedef	uint32_t	phandle_t;
typedef	phandle_t	dnode_t;

/*
 * Device type matching
 */
#define	OBP_NONODE	((dnode_t)0)
#define	OBP_BADNODE	((dnode_t)-1)

/*
 * Property defines
 */
#define	OBP_NAME		"name"
#define	OBP_DEVICETYPE		"device_type"

/*
 * Max size of a path component and a property name (not value)
 * These are standard definitions.
 */
#define	OBP_MAXDRVNAME		32	/* defined in P1275 */
#define	OBP_MAXPROPNAME		32	/* defined in P1275 */

/*
 * Max pathname length is a platform-dependent parameter.
 */
#define	OBP_MAXPATHLEN		256	/* Platform dependent */

/*
 * fake and cached file descriptors for ioctl requests
 */
#define	OPENPROM_FD	999999
ihandle_t	FLASHPROM_FD;

/*
 * Flashprom ioctl requests (see flash-update/flash/flashprom/flashprom.h)
 */
#define	FIOC            ('F'<<8)
#define	PROMGETDEFAULT  (FIOC | 1)
#define	_PGI            (FIOC | 18)
#define	_PGO            (FIOC | 20)

#ifdef	__cplusplus
}
#endif

#endif	/* _SYS_OBPDEFS_H */
