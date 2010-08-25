/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_file.c
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

#pragma ident	"@(#)prom_file.c	1.1	01/04/19 SMI"

#include <sys/promif.h>
#include <sys/promimpl.h>

#define	BLOCKSIZE	0x1000

typedef struct DEBLOCK_T {
	long	start;
	long	blocksize;
	uchar_t	buffer[BLOCKSIZE];
} deblock_t;

typedef struct FILE_T {
	ihandle_t	ihandle;
	long	size;
	long	currentpos;
	deblock_t	deblock;
} FILE;

#define	_FILEDEFED
#include <stdio.h>


/*
 * this counts on the fact that the standalone program was boot disked rather
 * than boot netted.  (ufs-file-system package is already loaded)
 * By the way, isn't ufs-file-system redundant?
 */

void *
loadfile(ihandle_t instance, uint32_t addr)
{
	cell_t ci[8];
	int32_t retval;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)3;			/* #argument cells */
	ci[2] = (cell_t)2;			/* #result cells */
	ci[3] = p1275_ptr2cell("load");		/* Arg1: method name */
	ci[4] = p1275_ihandle2cell(instance);	/* Arg2:SA1:dev-node ihandle */
	ci[5] = p1275_int2cell(addr);		/* Arg3: SA2: load-addr */

	retval = p1275_cif_handler(&ci);

	if (retval != 0)
		return ((void *)-1);
	if (ci[6] != 0)				/* Res1: Catch result */
		return ((void *)-1);

	return ((void *)ci[7]);			/* Res2: virt addr */
}

long
filesize(ihandle_t instance)
{
	cell_t ci[8];
	int32_t retval;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)2;			/* #argument cells */
	ci[2] = (cell_t)3;			/* #result cells */
	ci[3] = p1275_ptr2cell("size");		/* Arg1: method name */
	ci[4] = p1275_ihandle2cell(instance);	/* Arg2:SA1:dev-node ihandle */

	retval = p1275_cif_handler(&ci);

	if (retval != 0)
		return (-1);
	if (ci[5] != 0)				/* Res1: Catch result */
		return (-1);
						/* Res2: Don't care */

	return ((long)ci[7]);			/* Res3: file size */
}

long
fileseek(ihandle_t instance, int32_t offset)
{
	/*
	 * Note that the order of the args passed in (after the ihandle)
	 * is being reversed so that when they are popped onto the forth
	 * stack they will be in the correct order for seeking
	 * ( offset whence -- error? )
	 */

	cell_t ci[9];
	int32_t retval;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)2;			/* #result cells */
	ci[3] = p1275_ptr2cell("seek");		/* Arg1: method name */
	ci[4] = p1275_ihandle2cell(instance);	/* Arg2:SA1:dev-node ihandle */
	ci[5] = p1275_int2cell(0);		/* Arg3: SA3: whence */
	ci[6] = p1275_int2cell(offset);		/* Arg4: SA2: offset */

	retval = p1275_cif_handler(&ci);

	if (retval != 0)
		return (-1);
	if (ci[7] != 0)				/* Res1: Catch result */
		return (-1);

	return (ci[8]);				/* Res2: error? */
}

int32_t
fileread(ihandle_t instance, uchar_t *addr, int32_t len)
{
	/*
	 * Note that the order of the args passed in (after the ihandle)
	 * is being reversed so that when they are popped onto the forth
	 * stack they will be in the correct order for reading
	 * ( addr len -- act-len )
	 */

	cell_t ci[9];
	int32_t retval;

	ci[0] = p1275_ptr2cell("call-method");	/* Service name */
	ci[1] = (cell_t)4;			/* #argument cells */
	ci[2] = (cell_t)2;			/* #result cells */
	ci[3] = p1275_ptr2cell("read");		/* Arg1: method name */
	ci[4] = p1275_ihandle2cell(instance);	/* Arg2:SA1:dev-node ihandle */
	ci[5] = p1275_int2cell(len);		/* Arg3: SA3: length */
	ci[6] = p1275_int2cell(addr);		/* Arg4: SA2: addr */

	retval = p1275_cif_handler(&ci);

	if (retval != 0)
		return (-1);
	if (ci[7] != 0)				/* Res1: Catch result */
		return (-1);

	return (ci[8]);				/* Res2: actual len */
}

/* it's always read/write */
FILE *
fopen(char const *filename, char const *mode)
{
	static FILE thisfile;
	ihandle_t ihandle;

	char ext_filename[100];
	prom_strcpy(ext_filename, "disk:,");
	filename = "|platform|platforms.di";
	prom_strcat(ext_filename, (caddr_t)filename);

	if ((ihandle = prom_open(ext_filename)) == NULL)
		return (NULL);

	prom_printf("thisfile %x\n", thisfile);
	prom_printf("ihandle %x\n", ihandle);

	thisfile.size = filesize(ihandle);
	thisfile.currentpos = 0;
	thisfile.ihandle = ihandle;
	thisfile.deblock.start = -1;	/* nothing read */

	printf("filesize = %i\n", thisfile.size);

	return (&thisfile);
}

int32_t
fclose(FILE *stream)
{
	return (prom_close(stream->ihandle));
}

int32_t
fseek(FILE *stream, long offset, int32_t whence)
{
	switch (whence) {
	case SEEK_SET:
		stream->currentpos = 0 + offset;
		break;
	case SEEK_CUR:
		stream->currentpos += offset;
		break;
	case SEEK_END:
		/* Unix allows going off the end of a stream! */
		stream->currentpos = stream->size + offset;
		break;
	default:
		return (-1);
	}
	return (fileseek(stream->ihandle, stream->currentpos));
}

long
ftell(FILE *stream)
{
	return (stream->currentpos);
}

int32_t
min(int32_t a, int32_t b)
{
	if (a < b)
		return (a);
	else
		return (b);
}


int32_t
fgetc(FILE *stream)
{
	/* I should buffer this */

	long file_end = stream->size;
	long position = stream->currentpos;
	long size = min((stream->size - position), BLOCKSIZE);
	uchar_t *buffer = stream->deblock.buffer;

	if (position >= file_end)
		return (EOF);

	if ((position < stream->deblock.start) ||
	    (position >= stream->deblock.start + stream->deblock.blocksize) ||
	    (stream->deblock.start == -1)) {
		stream->deblock.start = position;
		stream->deblock.blocksize = size;
		if ((fileread(stream->ihandle, buffer, size)) != size)
			return (-1);
	}

	return ((int32_t)buffer[stream->currentpos++ - stream->deblock.start]);

}
