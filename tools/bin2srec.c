/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: bin2srec.c
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
#pragma ident	"@(#)bin2srec.c	1.1	02/12/18 SMI"
/* purpose: Convert a binary file to a file containing S-records.
/* copyright: Copyright 2002 Sun Microsystems, Inc. All rights reserved */
/* copyright: Use is subject to license terms. */

#include <sys/types.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <ctype.h>
#include <sys/sysmacros.h>
#include <sys/stat.h>
#include <sys/fs/udf_volume.h>

#define SREC_LINESZ		76
#define SREC_1STCHAR_OFF	10
#define LINESZ			32

#define KSIZE			1024

int do_sumcheck = 0;
int sumcheck = 0;

usage(char **argv) {
	printf("usage: %s -i <input_file> -o <output_file>\n"
 		"	[-f <fill to K-bytes>] [-p <fill byte pattern for -f>] "
		"[-s]\n", argv[0]);
	exit(-1);
}

char srecln[SREC_LINESZ+2];

/***************************************************************************
 *
 * build_line(uchar_t *ubp, int linesz, int addr)
 *
 * Build one S-record line in the "srecln" buffer.
 *
 * Input:
 *	uchar_t *ubp		= the current binary file pointer
 *	int linesz		= the # of bytes to convert (<=32)
 *	int addr		= the address to use in the S-record
 * Output:
 *	int			= the string length of the S-record line
 *
 ***************************************************************************/
build_line(uchar_t *ubp, int linesz, int addr)
{
	int i, j, checksum;
	uchar_t invert_checksum, ulnsz = (linesz+4); /* line + 4 byte header */

	/*
	 * Checksum includes line size (byte0) plus 3 bytes of address
	 * (bytes 1-3) + each data byte.
	 */
	checksum = (linesz+4) + ((addr >> 16) & 0xff) +
			((addr >> 8) & 0xff) + (addr & 0xff);

	memset(srecln, 0, SREC_LINESZ+2);
	sprintf(srecln, "S2%02x%06x", ulnsz, addr);

	/*
	 * Convert the line of binary to ASCII.
	 */
	for (i = 0, j = SREC_1STCHAR_OFF; i < linesz; i++) {
		sprintf(&srecln[j], "%02x", ubp[i]);
		checksum += ubp[i];
		sumcheck += ubp[i];
		j += 2;
	}
	invert_checksum = ~checksum;
	sprintf((char *)&srecln[j], "%02x\n", invert_checksum);

	for (i = 0; i < strlen(srecln); i++) {
		uchar_t val = toupper((int)srecln[i]);

		srecln[i] = val;
	}

	return(strlen(srecln));
}

/***************************************************************************
 *
 * The purpose of this utility is to build a S-record file from a binary file.
 *
 * Inputs:
 *	-i <binary filename>
 *	-o <S-record output filename>
 *	[-f <fill to K-bytes>]		= Fill to upto this K-byte limit 
 *	[-p <fill byte pattern>]	= Fill byte for -f (default=0)
 *	[-s]		= Display Prom-Burner sumcheck, sum of all data bytes.
 *
 * Output:
 *
 ***************************************************************************/

main(argc, argv)
char **argv;
{
	int ifd, ofd;
	int bx, ifilesz;
	int address;
	char *bp;
	struct stat stat;
	char *ifilename = NULL;
	char *ofilename = NULL;
	int opt;
	int i, j, x, wrtsz;
	extern  int     getopt();
        extern  int     optind;
        extern  char    *optarg;
	int kfill = 0;
	uchar_t kfill_pat = 0;

	while ((opt = getopt(argc, argv, "iosvfp" )) != EOF) {
                switch (opt) {
                case 'i': 
                        ifilename = argv[optind++];
                        break;
                case 'o': 
                        ofilename = argv[optind++];
                        break;
                case 'f': 
                        kfill = strtol(argv[optind++], 0 , 0);
			kfill *= KSIZE;
                        break;
                case 'p': 
                        kfill_pat = strtol(argv[optind++], 0 , 0);
                        break;
                case 's': 
                        do_sumcheck = 1;
                        break;
                default:
                    fprintf(stderr, "Illegal command: '%c'.\n", opt);
                    usage(argv);

		}
	}
	if ((!ifilename) || (!ofilename)) usage(argv);

	/*
	 * open the binary file.
	 */
	if ((ifd = open(ifilename, O_RDONLY)) < 0) {
		perror("open");
		exit(-1);
	}
	if (fstat(ifd, &stat) == -1) {
                perror("fstat");
		exit(-1);
        }
        ifilesz = stat.st_size;		/* size of binary file */
	if (!ifilesz) {
		fprintf(stderr, "binary file: No data!\n");
		exit(-1);
        }
	/*
	 * Check for kfill > ifilesz.  If not, clear kfill and continue
	 * to use ifilesz.  Otherwise, malloc up to the KB limit and
	 * pre-set with the fill pattern.  The binary file will read into
	 * beginning of the buffer with the fill pattern upto the KB limit.
	 */
	if (kfill <= ifilesz) {
		kfill = 0;
		bp = (char *)malloc(ifilesz);
	} else {
		bp = (char *)malloc(kfill);
		memset(bp, kfill_pat, kfill);
	}
	if (!bp) {
		fprintf(stderr, "malloc: no space!\n");
		exit(-1);
	}

	bx = read(ifd, bp, ifilesz);	/* read in binary file */
	close(ifd);
	if (bx != ifilesz) {
		perror("binary file read");
		fprintf(stderr, "binary file: size %d, only read %d\n",
			ifilesz, bx);
		exit(-1);
	}
	if (kfill) { 	/* If kfill, switch to the KB limit. */
		ifilesz = kfill;
	}
	/*
	 * Create the SREC output file.
	 */
	if ((ofd = open(ofilename, O_RDWR | O_CREAT, 0777)) < 0) {
		perror("open output file");
		exit(-1);
	}
	if (ftruncate(ofd, 0)) {
		perror("ftruncate");
		exit(-1);
	}
	/*
	 * Build the S-Record file from the binary file one line at a time
	 */
	strcpy(srecln, "S204000000FB\n");	/* start of S-record file */
	bx = write(ofd, srecln, strlen(srecln));
	if (bx != strlen(srecln)) {
		perror("write S-record header");
		exit(-1);
	}
	for (i = 0, j = LINESZ; i < ifilesz; i += LINESZ, j += LINESZ) {
		j = (j > ifilesz) ? ifilesz : j;
		x = j - i;
		if (!x) break;
		wrtsz = build_line((uchar_t *)&bp[i], x, i);

		bx = write(ofd, srecln, wrtsz);
		if (bx != wrtsz) {
			perror("S-record file write");
			fprintf(stderr, "size %d, only read %d\n", wrtsz, bx);
			exit(-1);
		}
	}
	strcpy(srecln, "S804000000FB\n");	/* end of S-record file */
	bx = write(ofd, srecln, strlen(srecln));
	if (bx != strlen(srecln)) {
		perror("write S-record tail");
		exit(-1);
	}
	close(ofd);
	if (do_sumcheck) printf("Total PROM SumCheck:  %08x\n", sumcheck);
	exit(0);
}
