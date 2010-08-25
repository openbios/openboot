/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: comp.c
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
/* @(#) comp.c 1.4@(#) */
/*
 * New simplified putcode(), adaptive block compress.
 */

#include <stdio.h>

#define HSIZE	18013		/* 91% occupancy */
#define BITS 14

typedef short		code_int;
typedef	unsigned char	char_type;
typedef long int	count_int;

#define INIT_BITS 9		/* initial number of bits/code */

static count_int	htab[HSIZE];
static unsigned short	codetab[HSIZE];

static char_type magic_header[] = { "\037\236" };	/* 1F 9E */

static int n_bits;			/* number of bits/code */
static int maxbits = BITS;		/* user settable max # bits/code */
static code_int maxcode;		/* maximum code, given n_bits */
static code_int maxmaxcode = 1 << BITS;	/* should NEVER generate this code */
static code_int hsize = HSIZE;		/* for dynamic table sizing */

#define MAXCODE(n_bits)	((1 << (n_bits)) - 1)

static code_int free_ent = 0;		/* first unused entry */

static long int in_count = 1;		/* length of input */
static long int bytes_out;		/* length of compressed output */

#define ROUNDOUT	4		/* XXX round for SPARC alignment */
static long int alloutbytes = 0;	/* num. of output bytes (w. header) */

/*
 * block compression parameters -- after all codes are used up,
 * and compression rate changes, start over.
 */
static long int ratio = 0;
#define CHECK_GAP 10000	/* ratio check interval */
static count_int checkpoint = CHECK_GAP;

/*
 * the next two codes should not be changed lightly, as they must not
 * lie within the contiguous general code space.
 */ 
#define FIRST	258	/* first free entry */
#define END	257	/* End of file marker */
#define	CLEAR	256	/* table clear output code */

static void build_hdr();
static void compress();
static void initout();
static void putcode();
static void endout();
static void cl_block();
static void cl_hash();

#ifndef NOMAIN
/*
 * compress stdin to stdout
 *
 * Algorithm:  use open addressing double hashing (no chaining) on the 
 * prefix code / next character combination.  We do a variant of Knuth's
 * algorithm D (vol. 3, sec. 6.4) along with G. Knott's relatively-prime
 * secondary probe.  Here, the modular division first probe gives way
 * to a faster exclusive-or manipulation.  Also do block compression with
 * an adaptive reset, whereby the code table is cleared when the compression
 * ratio decreases, but after the table fills.  The variable-length output
 * codes are re-sized at this point, and a special CLEAR code is generated
 * for the decompressor.
 */

int
main(argc,argv)
    int argc;
    char **argv;
{
    build_hdr();
    compress();
    return 0;
}
#else

static unsigned char *inbuf;
static unsigned char *outbuf;
static int putcount;
static int getcount;
static int srcsize;

#undef putchar
#undef getchar
#define putchar(x)	outbuf[putcount++] = (unsigned char) (x)
#define getchar()	((getcount < srcsize) ? inbuf[getcount++] : EOF )

int comp( src, size, dest )
    unsigned char *src;
    int size;
    unsigned char *dest;
{
    inbuf	= src;
    srcsize	= size;
    putcount	= 0;
    getcount	= 0;
    outbuf	= dest;

    build_hdr();
    compress();

    return alloutbytes;
}

#endif

static void build_hdr()
{
#ifdef newheader
    putstring("#!lzdecode ");
    putstring("E ");				/* Maxbits */
    putstring(argc < 2 ? "lz.out" : argv[1] );	/* File name */
    putstring("\n");
#else
    ++alloutbytes;
    putchar(magic_header[0]);

    ++alloutbytes;
    putchar(magic_header[1]);

    ++alloutbytes;
    putchar((char)(maxbits));
#endif
}

static void compress() {
    register long fcode;
    register code_int i = 0;
    register int c;
    register code_int ent;
    register int disp;
    register code_int hsize_reg;
    register int hshift;

    initout();

    maxcode = MAXCODE(n_bits = INIT_BITS);
    free_ent = FIRST;

    hshift = 0;
    for ( fcode = (long) hsize;  fcode < 65536L; fcode *= 2L )
    	hshift++;
    hshift = 8 - hshift;		/* set hash code range bound */

    hsize_reg = hsize;
    cl_hash( (count_int) hsize_reg);	/* clear hash table */

    ent = getchar ();

    while ( (c = getchar()) != EOF ) {
	in_count++;
	fcode = (long) (((long) c << maxbits) + ent);
 	i = ((c << hshift) ^ ent);	/* xor hashing */

	if ( htab[i] == fcode ) {
	    ent = codetab[i];
	    continue;
	} else if ( (long)htab[i] < 0 )	/* empty slot */
	    goto nomatch;
 	disp = hsize_reg - i;		/* secondary hash (after G. Knott) */
	if ( i == 0 )
	    disp = 1;
probe:
	if ( (i -= disp) < 0 )
	    i += hsize_reg;

	if ( htab[i] == fcode ) {
	    ent = codetab[i];
	    continue;
	}
	if ( (long)htab[i] > 0 ) 
	    goto probe;
nomatch:
	putcode ( (code_int) ent );
	ent = c;
	/*
	 * If the next entry is going to be too big for the code size,
	 * then increase it, if possible.
	 */
	if ( free_ent > maxcode )
	{
	    n_bits++;
	    if ( n_bits == maxbits )
		maxcode = maxmaxcode;
	    else
		maxcode = MAXCODE(n_bits);
	}
	if ( free_ent < maxmaxcode ) {
 	    codetab[i] = free_ent++;	/* code -> hashtable */
	    htab[i] = fcode;
	}
	else if ( (count_int)in_count >= checkpoint)
	    cl_block ();
    }
    /*
     * Put out the final code and the End of File marker.
     */
    putcode( (code_int)ent );
    putcode( (code_int)END );
    endout();

    return;
}

/*****************************************************************
 * TAG( putcode )
 *
 * Output the given code.
 * Inputs:
 * 	code:	A n_bits-bit integer.
 *		Assumes that n_bits =< (long)wordsize - 1.
 * Outputs:
 * 	Outputs code to the file.
 * Assumptions:
 *	Chars are 8 bits long.
 */

static oldcode = 0;
static offset = 0;

static void initout()
{
    offset = 0;
    oldcode = 0;
    ratio = 0;
    in_count = 1;
    bytes_out = 0;		/* Header doesn't count */
    checkpoint = CHECK_GAP;
}

static void putcode( code )
    code_int  code;
{
    register long r_code;
    register int r_off = offset;

    r_code = (code << offset) + oldcode;
    r_off += n_bits;
    do {
	putchar( r_code & 0xff );
	++alloutbytes;
	bytes_out++;
	r_code = r_code >> 8;
	r_off -= 8;
    } while (r_off >= 8);
    oldcode = r_code;
    offset = r_off;
}

static void endout()
{
    if (offset)
    {
	++alloutbytes;
	putchar(oldcode);
    }

    {
	int i;

	i = alloutbytes % ROUNDOUT;
	if (i != 0)
		while (i-- > 0)
		{
			++alloutbytes;
			putchar(0);
		}
    }

    oldcode = 0;
    offset = 0;
}

static void cl_block ()		/* table clear for block compress */
{
    register long int rat;

    checkpoint = in_count + CHECK_GAP;

    if(in_count > 0x007fffff) {	/* shift will overflow */
	rat = bytes_out >> 8;
	if(rat == 0) {		/* Don't divide by zero */
	    rat = 0x7fffffff;
	} else {
	    rat = in_count / rat;
	}
    } else {
	rat = (in_count << 8) / bytes_out;	/* 8 fractional bits */
    }
    if ( rat > ratio ) {
	ratio = rat;
    } else {
	ratio = 0;
 	cl_hash ( (count_int) hsize );
	free_ent = FIRST;
/*	clear_flg = 1;*/
	putcode ( (code_int) CLEAR );
	maxcode = MAXCODE (n_bits = INIT_BITS);
    }
}

static void cl_hash(hsize)		/* reset code table */
	register count_int hsize;
{
	register count_int *htab_p = htab+hsize;
	register long i;
	register long m1 = -1;

	i = hsize - 16;
 	do {				/* might use Sys V memset(3) here */
		*(htab_p-16) = m1;
		*(htab_p-15) = m1;
		*(htab_p-14) = m1;
		*(htab_p-13) = m1;
		*(htab_p-12) = m1;
		*(htab_p-11) = m1;
		*(htab_p-10) = m1;
		*(htab_p-9) = m1;
		*(htab_p-8) = m1;
		*(htab_p-7) = m1;
		*(htab_p-6) = m1;
		*(htab_p-5) = m1;
		*(htab_p-4) = m1;
		*(htab_p-3) = m1;
		*(htab_p-2) = m1;
		*(htab_p-1) = m1;
		htab_p -= 16;
	} while ((i -= 16) >= 0);

    	for ( i += 16; i > 0; i-- )
		*--htab_p = m1;
}


