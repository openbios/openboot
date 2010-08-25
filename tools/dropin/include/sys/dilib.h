/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: dilib.h
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
 * id: @(#)dilib.h 1.1 03/04/01
 * purpose: 
 * Copyright 2000, 2003 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */

#include <sys/types.h>
#include <sys/dropins.h>

#define	di_bail(x) printf("Error: "x" at %s:%d\n", __FILE__, __LINE__)

int32_t di_isdropin(obmd_t *di);

int32_t di_islevel2(obmd_t *di);

obmd_t *di_finddropin(char *name, obmd_t *di, int size, int verbose,
	int instance);

int32_t di_getdata(obmd_t *src, int verbose, dropin_data_t *data);

obmd_t *di_open_dropin(char *fname, int verbose);

obmd_t *di_create_dropin(
    char *name, uchar_t *data, int size,
    int level2, int compress, int verbose);

int32_t di_comp(uchar_t *src, int size, uchar_t *dest);

int32_t di_decomp(uchar_t *src, int size, uchar_t *dest);

caddr_t  extract_string(dropin_data_t *data);

/* for debugging */
int dump_di_info(obmd_t *di, int verbose, int data_only);
