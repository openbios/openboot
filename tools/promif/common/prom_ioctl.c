/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_ioctl.c
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
 * Copyright (c) 2001-2003 Sun Microsystems, Inc.
 * All rights reserved.
 * Use is subject to license terms.
 */

#pragma ident	"@(#)prom_ioctl.c	1.1	01/04/19 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>
#include <sys/openpromio.h>
#include <sys/mman.h>

static phandle_t oprom_dev_phandle;
static phandle_t flash_dev_phandle;
typedef struct openpromio openpromio_t;

int32_t
ioctl(int32_t fildes, int32_t request, void *arg)
{
	phandle_t flash_phandle;
	phandle_t opt_phandle;

	/*
	 * Currently only supports /dev/openprom and /dev/flashprom
	 */
	if (fildes == NULL) {
		prom_printf("Null file descriptor\n");
		return (-1);
	} else if (fildes == OPENPROM_FD) {

	openpromio_t *op_struct = (openpromio_t *)arg;

	switch (request) {
	case OPROMGETOPT:
		opt_phandle = prom_finddevice("/options");
		op_struct->oprom_size = prom_getprop(opt_phandle,
		    op_struct->opio_u.b, op_struct->opio_u.b);
		break;

	case OPROMGETPROP:
		op_struct->oprom_size = prom_getprop(oprom_dev_phandle,
		    op_struct->opio_u.b, op_struct->opio_u.b);
		break;

	case OPROMNXTOPT:
		opt_phandle = prom_finddevice("/options");
		op_struct->oprom_size = prom_nextprop(opt_phandle,
		    op_struct->opio_u.b, op_struct->opio_u.b);
		break;

	case OPROMNXTPROP:
		op_struct->oprom_size = prom_nextprop(oprom_dev_phandle,
		    op_struct->opio_u.b, op_struct->opio_u.b);
		break;

	case OPROMGETPROPLEN:
		op_struct->opio_u.i = prom_getproplen(oprom_dev_phandle,
		    op_struct->opio_u.b);
		break;

	case OPROMCHILD:
		op_struct->opio_u.i = prom_childnode(op_struct->opio_u.i);
		oprom_dev_phandle = op_struct->opio_u.i;
		break;

	case OPROMNEXT:
		op_struct->opio_u.i = prom_nextnode(op_struct->opio_u.i);
		oprom_dev_phandle = op_struct->opio_u.i;
		break;

	case OPROMGETVERSION:
		flash_phandle = prom_finddevice("/flashprom");
		op_struct->oprom_size = prom_getprop(flash_phandle, "version",
		    op_struct->opio_u.b);
		break;

	default:
		printf("Unrecognized stream request %u\n", request);
		return (-1);

	} } else if (fildes == FLASHPROM_FD) {	/* OPENPROM_FD and switch */

	int32_t protection;
	uchar_t *gpio_va;

	switch (request) {
	case _PGI:
		protection = (PROT_READ | PROT_WRITE);
		gpio_va = (uchar_t *)mmap((caddr_t)0, 1,
		    protection, MAP_SHARED, fildes, (1<< 28));
		if (gpio_va == MAP_FAILED) {
			printf("ERROR: Unable to map in flashprom gpio\n");
			return (-1);
		}
		*gpio_va = *(uchar_t *)arg;
		break;

	case _PGO:
		protection = PROT_READ;
		gpio_va = (uchar_t *)mmap((caddr_t)0, 1,
		    protection, MAP_SHARED, fildes, (1<< 28));
		if (gpio_va == MAP_FAILED) {
			printf("ERROR: Unable to map in flashprom gpio\n");
			return (-1);
		}
		*(uchar_t *)arg = *gpio_va;
		break;

	default:
		printf("Unrecognized stream request %u\n", request);
		return (-1);

	} } else {				/* FLASHPROM_FD and switch */
		prom_printf("Unknown file stream type\n");
		return (-1);
	}

	return (0);

}
