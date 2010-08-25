/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: finddropin.c
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
 * id: @(#)finddropin.c 1.1 03/04/01
 * purpose: 
 * copyright: Copyright 2000, 2003 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

#include <sys/dilib.h>
#include <strings.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

caddr_t
extract_string(dropin_data_t *data)
{
	int32_t len = data->size+1;
	static char str[0x80];

	if (len > 0x80) {
		return (NULL);
	}
	memset(str, 0, len);
	strncpy(str, (caddr_t)data->data, data->size);
	return (strdup(str));
}

static uchar_t *
do_lempel_ziv(uchar_t *src, int32_t len, int32_t dlen, int32_t verbose)
{
	uchar_t *data, *dbuf;
	int32_t nlen = 0;

	dbuf = (uchar_t *)malloc(dlen);
	if (dbuf == NULL) {
		di_bail("Malloc Failed");
		return (0);
	}
	nlen = di_decomp(src, len, dbuf);
	if (verbose > 0) {
		printf("Decompress: %d/%d bytes, [%d], ratio %2.2f:1\n",
		    len, dlen, nlen, (((float)dlen)/((float)len)));
	}
	data = (uchar_t *)malloc(dlen);
	if (data == NULL) {
		di_bail("Malloc Failed");
		return (0);
	}
	memcpy(data, dbuf, dlen);
	free(dbuf);
	return (data);
}

int32_t
di_getdata(obmd_t *src, int32_t verbose, dropin_data_t *rdata)
{
	uint32_t *dptr = (uint32_t *)((caddr_t)src + OBMD_HDR);
	uchar_t *data = (uchar_t *)dptr;
	int32_t  dlen = src->size;
	compresshdr *chdr = (compresshdr *) dptr;

	if ((chdr->magic == COMP_MAGIC) && (src->size == chdr->comp_size)) {
		int32_t clen = chdr->comp_size;
		int32_t type = chdr->type;
		dlen = chdr->decomp_size;

		switch (type) {
		case COMP_MAGIC:
			if (verbose > 0) {
				printf("[COMP: %x,%x]\n", clen, dlen);
			}
			data = do_lempel_ziv(data+sizeof (compresshdr),
			    clen, dlen, (verbose-1));
			dptr = (uint32_t *)data;
			break;

		default:
			printf("Unknown compression type: %d\n", type);
			break;
		}
	}

	rdata->data = data;
	rdata->size = dlen;
	if (dptr[0] == OBME_MAGIC) {
		rdata->data += sizeof (obme_t);
		rdata->size -= sizeof (obme_t);
	}
	return (0);
}

int32_t
di_isdropin(obmd_t *src)
{
	return (strncmp((caddr_t)src, "OBMD", 4) == 0);
}

int32_t
di_islevel2(obmd_t *src)
{
	uchar_t *bdata = ((uchar_t *)src)+OBMD_HDR;
	int32_t *data = (int32_t *)bdata;
	return (di_isdropin(src) && (data[0] == OBME_MAGIC));
}

static obmd_t *
di_iterate(caddr_t name, obmd_t *src, int32_t size, int32_t verbose,
	int32_t instance)
{
	int32_t dlen, bytes = 0;
	int32_t num_found = 1;
	obmd_t *found = NULL;
	uchar_t *next;


	if (verbose > 0) {
		printf("di_iterate: '%s'\n", name);
	}
	/*
	 * Iterate through the chunk looking for dropins
	 */
	while ((found == NULL) && (bytes < size) && (num_found <= instance)) {
		next = (uchar_t *)src;
		while (*next == 1) {
			next++;
			bytes++;
		}
		src = (obmd_t *)next;
		if (!di_isdropin(src)) break;
		if (verbose > 0) {
			printf("..di: '%s' [%d]\n", src->name, src->size);
			printf("instance = %i\n", instance);
		}
		if (strcmp(name, src->name) == 0) {
			if (instance == num_found)
				found = src;
			else {
				num_found++;
				dlen = src->size + OBMD_HDR;
				next += dlen;
				bytes += dlen;
				src = (obmd_t *)next;
			}
		} else {
			dlen = src->size + OBMD_HDR;
			next += dlen;
			bytes += dlen;
			src = (obmd_t *)next;
		}
	}
	return (found);
}

obmd_t *
di_finddropin(caddr_t name, obmd_t *src, int32_t filesize,
	int32_t verbose, int32_t instance)
{
	caddr_t dir;
	obmd_t *data = NULL;
	caddr_t container;
	caddr_t slash;
	uchar_t *shift;
	uchar_t *next;
	dropin_data_t dropin_data;
	int32_t i = 0;
	int32_t size = filesize;



	shift = (uchar_t *)src;
	while (*shift == 1) {
		if (verbose > 0) printf("x");
		shift++;
	}
	src = (obmd_t *)shift;
	if (*name == '/') {
		name++;
		di_getdata(src, (verbose-1), &dropin_data);
		src = (obmd_t *)dropin_data.data;
		size = dropin_data.size;
	}
	if (*name == 0) {
		if (verbose > 0) {
			printf("<empty filename>\n");
		}
		return (NULL);
	}
	if (!di_isdropin(src)) {
		if (verbose > 0) {
			printf("<Not a dropin>\n");
		}
		return (NULL);
	}
	if (size <= 0) {
		if (verbose > 0) {
			printf("<no more bytes>\n");
		}
		return (NULL);
	}
	container = strdup(name);
	dir = slash = strchr(container, '/');
	if (slash) {
		*slash = 0;
		dir = slash+1;
	}
	if (verbose > 0) {
		printf("Path: %s [%x]\n", name, size);
	}

	next = (uchar_t *)src;
	while ((++i <= instance) && (src != NULL)) {
		data = di_iterate(container, src, filesize, (verbose-1), 1);
		next += (src->size + OBMD_HDR);
		src = (obmd_t *)next;
	}

	if (data != NULL) {
		obmd_t *new;
		int32_t new_size;
		/*
		 * we found it
		 */
		if (verbose > 0) {
			printf("Dropin: '%s', [%d]\n", data->name, data->size);
		}
		if (dir) {
			di_getdata(data, (verbose-1), &dropin_data);
			new = (obmd_t *)dropin_data.data;
			new_size = dropin_data.size;
			if (verbose > 0) {
				printf("Descending into: %s [%d]\n",
				    data->name, data->size);
			}
			data = di_finddropin(dir, new, new_size,
							(verbose-1), 1);
		}
	}
	return (data);
}
