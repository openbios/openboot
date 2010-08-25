/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: decomp.c
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
#ifndef STANDALONE
#include <stdio.h>
#endif /* STANDALONE */

/*
 * @(#)decomp.c 1.6 03/04/01
 * Copyright 2000, 2003 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 * New simplified getcode() routine, adaptive block compress.
 */

/* marker for needed scope management of symbols in this file */
#define	PRIVATE

typedef unsigned char uchar_t;

#define	HSIZE		18013		/* 91% occupancy */
#define	BITS		14
#define	INIT_BITS	9		/* initial number of bits/code */

/*
 * Character output.
 */
PRIVATE unsigned char	*output;
PRIVATE unsigned char	*input;
PRIVATE int		data_count;

#ifdef STANDALONE
#define	putbyte(c)	*output++ = (c)
#else
#define	putbyte(c)	putchar((c))
#endif /* STANDALONE */
PRIVATE int getbyte();

#define	init_output(op)		output = (op)

#define	init_input(ip, size)	input = (ip), data_count = (size)
/*
 * Start of Uninitialized globals
 */
typedef short		code_int;
typedef	unsigned char	char_type;
typedef int		count_int;

PRIVATE char_type		tab_suffix[HSIZE];
PRIVATE unsigned short		tab_prefix[HSIZE];
PRIVATE char_type		de_stack[8000];

/*
 * End of uninitialized globals
 */

PRIVATE code_int		getcode();

#define	maxmaxcode ((code_int)1 << BITS) /* should NEVER generate this code */
#define	MAXCODE(n_bits)	((1 << (n_bits)) - 1)

/*
 * block compression parameters -- after all codes are used up,
 * and compression rate changes, start over.
 * These codes should not be changed lightly, as they must not
 * lie within the contiguous general code space.
 * The END marker is used because some file transfer programs are
 * prone to adding garbage bytes to the end of the file.
 */
#define	FIRST	258	/* first free entry */
#define	END	257	/* End of file marker */
#define	CLEAR	256	/* table clear output code */

static char_type magic_header[] = { "\037\236" };    /* 1F 9E */

/*
 * Don't initialize these explicitly because we want them in the
 * BSS segment for ROM/RAM systems.  It would probably be a good
 * idea to initialize them to 0 at run time (when decompress()
 * begins).
 */
static int	getcode_offset;
static int	getcode_oldcode;

/*
 * Decompress stdin to stdout.  This routine adapts to the codes in the
 * file building the "string" table on-the-fly; requiring no table to
 * be stored in the compressed file.  The tables used herein are shared
 * with those of the compress() routine.  See the definitions above.
 */

PRIVATE void
decompress(ip, insize, op)
    unsigned char *ip;
    int insize;
    unsigned char *op;
{
	register char_type	*stackp;
	register int		finchar;
	register code_int	code,
				oldcode,
				incode;
	register int		n_bits;		/* number of bits/code */
	code_int		maxcode;	/* max code, given n_bits */
	code_int		free_ent;	/* first unused entry */

	getcode_offset = 0;
	getcode_oldcode = 0;

	init_input(ip, insize);
	init_output(op);
	/* Check the magic number */
	if ((getbyte() != (magic_header[0] & 0xFF)) ||
	    (getbyte() != (magic_header[1] & 0xFF))) {

#if defined(DEBUG) && ! defined(STANDALONE)
		fprintf(stderr, "Bad MAGIC number\n");
		exit(1);
#endif /* DEBUG */
		*(short *)1 = 1;
	}
	if (getbyte() != BITS) {
#if defined(DEBUG) && ! defined(STANDALONE)
		fprintf(stderr, "Bad #bits\n");
#endif /* DEBUG */
		*(short *)1 = 2;
	}
	/*
	 * As above, initialize the first 256 entries in the table.
	 */
	maxcode = MAXCODE(n_bits = INIT_BITS);

	for (code = 255; code >= 0; code--) {
		tab_prefix[code] = 0;
		tab_suffix[code] = (char_type)code;
	}

	free_ent = FIRST;

	finchar = oldcode = getcode(n_bits);
	if (oldcode == -1 || oldcode == END)	/* EOF already? */
		*(short *)1 = 3;
	putbyte((char)finchar);	/* first code must be 8 bits = char */
	stackp = de_stack;

	while ((code = getcode(n_bits)) > (code_int)-1 && code != END) {

		if (code == CLEAR) {
			for (code = 255; code >= 0; code--)
				tab_prefix[code] = 0;
			maxcode = MAXCODE(n_bits = INIT_BITS);
			free_ent = FIRST - 1;
			if ((code = getcode(n_bits)) == -1)  /* EOF */
				break;
		}
		incode = code;

		/*
		 * Special case for KwKwK string.
		 */
		if (code >= free_ent) {
			*stackp++ = finchar;
			code = oldcode;
		}

		/*
		 * Generate output characters in reverse order
		 */
		while (code >= 256) {
			*stackp++ = tab_suffix[code];
			code = tab_prefix[code];
		}
		*stackp++ = finchar = tab_suffix[code];

		/*
		 * And put them out in forward order
		 */
		do
			putbyte(*--stackp);
		while (stackp > de_stack);

		/*
		 * Generate the new entry.
		 */
		if ((code = free_ent) < (code_int)maxmaxcode) {
			tab_prefix[code] = (unsigned short)oldcode;
			tab_suffix[code] = finchar;
			free_ent = code+1;
		}

		/*
		 * Remember previous code.
		 */
		oldcode = incode;

		/*
		 * If the next entry will be too big for the current code
		 * size, then we must increase the size.
		 */
		if (free_ent > maxcode) {
			n_bits++;
			if (n_bits == BITS)
				/* won't get any bigger now */
				maxcode = maxmaxcode;
			else
				maxcode = MAXCODE(n_bits);
		}
	}
}

/*
 * getcode
 * Read one code from the standard input.  If EOF, return -1.
 */

PRIVATE code_int rmask[] = {
	0x0000, 0x0001, 0x0003, 0x0007, 0x000f, 0x001f, 0x003f,
	0x007f, 0x00ff, 0x01ff, 0x03ff, 0x07ff, 0x0fff, 0x1fff,
	0x3fff, 0x7fff, (code_int)0xffff
};

PRIVATE code_int
getcode(bits)
	register int	bits;
{
	register int	r_off = getcode_offset;
	register int	code = getcode_oldcode;
	register int	c;

	do {
		if ((c = getbyte()) == -1)
			return (-1);
		code += c << r_off;
		r_off += 8;
	} while (r_off < bits);

	getcode_oldcode = code >> bits;
	getcode_offset = r_off - bits;
#if defined(DEBUG) && ! defined(STANDALONE)
	fprintf(stderr, "[%x]\n", code & rmask[bits]);
#endif /* DEBUG */
	return (code & rmask[bits]);
}

PRIVATE int
getbyte()
{
#ifndef STANDALONE
	int c;
	c = getchar();
#ifdef DEBUG
	fprintf(stderr, "%2x ", c);
#endif /* DEBUG */
	if (c == EOF) c = -1;
	return (c);
#else
	if (--data_count < 0)
		return (-1);
	return ((int)*input++);
#endif /* STANDALONE */
}

#ifndef STANDALONE
main(void)
{
	decompress(0, 0, 0);
	return (0);
}
#endif /* STANDALONE */

#ifdef DROPIN_LIB
int
decomp(uchar_t *src, int size, uchar_t *dest)
{
	decompress(src, size, dest);
	return (output - dest);
}
#endif /* DROPIN_LIB */
