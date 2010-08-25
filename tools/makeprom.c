/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: makeprom.c
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
 * id: @(#)makeprom.c 1.18 03/04/01
 * purpose: 
 * Copyright 1994-2001, 2003 Sun Microsystems, Inc. All Rights Reserved
 * Use is subject to license terms.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/dropins.h>
#define	PROM_SIZE	(8*1024*1024)

static unsigned long header[] = {
    0x01030107,
    0,
    0, 0, 0, 0, 0, 0
};

static int verbose = 0;
static int aout   = 0;
static int verify = 0;
static int force  = 0;
static int nopad  = 0;
static int usecrc = 0;
static int recurselevel = 0;
static int standalone = 0;
static uchar_t *prom;
static uchar_t *holding;

static void
usage(char *name)
{
	char *msg =
	    "%s: <flags> [-o output] input1 .. inputn\n"
	    "   -p <pad>    : pad input1 to <pad>Kb boundary\n"
	    "   -c          : Append CRC at end, assumes -p\n"
	    "   -a          : add a.out header\n"
	    "   -f          : (Force) Fix checksum\n"
	    "   -s          : create output files for standalone utility\n"
	    "   -v          : verbose mode\n"
	    "   -d          : descend into level2 dropins\n"
	    "   -n          : disable default pad to 512KB\n"
	    "   -o <output> : output filename\n";
	fprintf(stderr, msg, name);
	exit(1);
}

static void
show_dropin_info(int level, obmd_t *obmdp)
{
	int ctype = 0;
	unsigned int *dptr = (unsigned int *) ((char *)obmdp + OBMD_HDR);

	level = (level+1) * 2;
	while (level--) putchar(' ');
	printf("Name: %s size = %lx", obmdp->name, obmdp->size);

	if ((dptr[0] == COMP_MAGIC) && (obmdp->size == dptr[1]))
		ctype = dptr[2];

	switch (ctype) {
	case COMP_MAGIC:
		{
			char type[5];
			unsigned int len = dptr[3];

			strncpy(type, (char *)&dptr[2], 4);
			type[4] = 0;

			printf(", %s, len %x", type, len);
		}
		break;
	default:
		break;
	}
	printf(" checksum = %x", obmdp->chksum);
}

static int
is_dropin(char *ptr)
{
	return ((strncmp(ptr, "OBMD", 4) == 0) ||
	    (strncmp(ptr, "OBME", 4) == 0));
}

static int
do_dropin(int level, obmd_t *obmdp, int size)
{
	int rewrite = 0;
	int ndropins = 0;
	obmd_t *prev = obmdp;
	char *start = (char *)obmdp;
	int total = 0;

retry:
	while (is_dropin((char *)obmdp)) {
		int crc;
		unsigned int *dptr = (unsigned int *) ((char *)obmdp+OBMD_HDR);
		ndropins++;

		if (verbose) show_dropin_info(level, obmdp);

		crc = checksum((ushort_t *)obmdp, obmdp->size+OBMD_HDR);

		if ((obmdp->chksum != 0) && (!force)) {
			if (crc != 0xffff) {
				if (!verbose) show_dropin_info(level, obmdp);
				printf(", Bad checksum: %s (%x != %x)\n",
				    (verbose ? "" : obmdp->name),
				    obmdp->chksum, crc);
				if (!verify) exit(1);
			} else {
				if (verify && verbose)
					printf(", checksum OK");
				if (verbose) printf("\n");
			}
		} else {
			if (verbose) printf("\n    ");
			if (obmdp->chksum != 0) {
				if (verbose) printf("Forcing");
			} else {
				if (verbose) printf("Generating");
			}

			if (verbose) printf(" checksum of %s", obmdp->name);

			rewrite++;
			obmdp->chksum = 0;
			obmdp->chksum = checksum((ushort_t *)obmdp,
			    obmdp->size+OBMD_HDR);
			if (verbose) {
				if (force || verify) {
					printf(", checksum = %x",
					    obmdp->chksum);
				}
				printf("\n");
			}
		}

		if ((recurselevel > level) && (dptr[0] == OBME_MAGIC)) {
			/*
			 * A level 2 dropin..
			 */
			do_dropin(level+1, (obmd_t *)(dptr+1), 0);
			return;
		}
#if 0
		if (strncmp(obmdp->name, "OBP", 3) == 0) {
			obmdp->chksum = 0;
			rewrite++;
		}
#endif

		prev = obmdp;
		obmdp = (obmd_t *)(((uchar_t *)obmdp) +
		    ROUNDUP(obmdp->size)+OBMD_HDR);
		if (!is_dropin((char *)obmdp)) {
			char *try = (char *)obmdp - 16;
			int slide, fixed;

			fixed = 0;
			for (slide = 0; slide < 32; slide++, try++)
				if (is_dropin(try)) {
					fixed = 1;
					break;
				}
			if (fixed) {
				rewrite++;
				prev->size += slide-16;
				prev->chksum = 0;
				prev->chksum = checksum((ushort_t *)prev,
				    prev->size + OBMD_HDR);
				if (verbose) {
					printf("Fixing %s length (%d)\n",
					    prev->name, slide-16);
					printf("Fixing %s checksum (%x)\n",
					    prev->name, prev->chksum);
				}

				if (slide > 19) {
					fprintf(stderr, "%s%s\n\n",
					    "ERROR: Need to adjust forward by",
					    " more than 3 bytes!");
					exit(1);
				}

				obmdp = (obmd_t *)try;
			}
		}
		total = ((char *)obmdp) - start;
		obmdp = (obmd_t *)ROUNDUP(obmdp);
	}
	if ((verify) && (total < size)) {
	    char *here;

	    /* Scan forward looking for more headers.. */
	    here = (char *)ROUNDUP((char *)obmdp);
	    while (((here-start) < size) && (!is_dropin(here)))
		here += 4;

	    obmdp = (obmd_t *)here;
	    if ((here-start) < size) {
		if (verbose) printf("Skipping to: %x\n", here-start);
		    goto retry;
	    }
	}

	if ((force) && (ndropins == 1) && ((size-OBMD_HDR) != prev->size)) {
		if (verbose)
			printf("Fixing %s size (actual %lx, should be %x)\n",
			    prev->name, prev->size, (size-OBMD_HDR));
		rewrite++;
		prev->size = size-OBMD_HDR;
		prev->chksum = 0;
		prev->chksum = checksum((ushort_t *)prev,
		    prev->size+OBMD_HDR);
	}
	return (rewrite && !verify);
}

void
main(int argc, char **argv)
{
	void open_failure();
	int ifd;
	int i;
	int nfiles = 0;
	int pad = 512;
	struct stat statbuf;
	int c;
	uchar_t *insert_ptr;
	extern char *optarg;
	extern int optind;
	char *ofile = NULL;

	/* assume verify */
	verify = 1;

	while ((c = getopt(argc, argv, "asdnvfcp:o:")) != EOF)
		switch (c) {
		case 'a':
			verify = 0;
			aout = 1;
			break;

		case 'f':
			verify = 0;
			force = 1;
			break;

		case 'v':
			verbose++;
			break;

		case 'd':
			recurselevel++;
			break;

		case 'n':
			verify = 0;
			nopad = 1;
			break;

		case 'o':
			verify = 0;
			ofile = optarg;
			break;

		case 'p':
			verify = 0;
			pad = atoi(optarg);
			if ((pad == 0) || (pad > 1024)) {
				fprintf(stderr, "Bad pad size: %dKb\n", pad);
				exit(1);
			}
			break;

		case 'c':
			usecrc = 1;
			if (nopad) {
				fprintf(stderr,
				    "-c and -n cannot be used together\n");
				exit(1);
			}
			break;

		case 's':
			standalone = 1;
			break;

		default:
			usage(argv[0]);
		}

	if ((ofile == NULL) && (!verify)) {
		fprintf(stderr, "%s: Missing output filename\n", argv[0]);
		usage(argv[0]);
	}

	pad *= 1024;
	prom = (uchar_t *)malloc(PROM_SIZE);
	if (prom == NULL) {
		fprintf(stderr, "Malloc failed for prom image\n");
		exit(1);
	}

	holding = (uchar_t *)malloc(PROM_SIZE);
	if (holding == NULL) {
		fprintf(stderr, "Malloc failed for holding buffer\n");
		exit(1);
	}

	/* Fill with FF */
	memset((void *)prom, 0xff, pad*2);

	insert_ptr = prom;

	for (i = optind; i < argc; i++) {
		int rlen;

		if (verbose)
			printf("Scanning: %s @ %x\n", argv[i],
			    (insert_ptr-prom));
		nfiles++;
		ifd = open(argv[i], O_RDONLY);
		if (ifd == -1) {
			fprintf(stderr, "%s: Can't open input file %s\n",
			    argv[0], argv[i]);
			exit(1);
		}
		fstat(ifd, &statbuf);
		if ((statbuf.st_size > pad) && (!verify)) {
			fprintf(stderr, "%s: Individual file too large"
			    " for current pad size\n", argv[0]);
			exit(1);
		}
		memset((void *)holding, 0xff, pad);
		rlen = read(ifd, holding, statbuf.st_size);
		if (rlen != statbuf.st_size) {
			printf("Short read: %d \n", rlen);
			exit(1);
		}
		memcpy((void *)insert_ptr, (void *)holding, statbuf.st_size);
		if (do_dropin(0, (obmd_t *)holding, statbuf.st_size)) {
			memcpy((void *)insert_ptr, (void *)holding,
			    statbuf.st_size);
		}
		close(ifd);
		if (nopad)
			insert_ptr += ROUNDUP(statbuf.st_size);
		else {
			/* If we pad we only pad the first file. */
			insert_ptr += pad;
			nopad = 1;
		}
	}

	if (!verify) {
		if (usecrc) {
			int mypad = pad;
			uint32_t crc;
			uint32_t *cptr = (uint32_t *)prom;

			if (nfiles > 1) mypad = pad*2;
			crc = crc32(mypad-sizeof (int32_t), prom, -1);
			if (verbose) printf("Computed CRC32 %x\n", crc);
			cptr[(mypad/sizeof (uint32_t))-1] = crc;
			insert_ptr = prom+mypad;
		}
		if (!standalone) {
			int ofd = open(ofile, (O_CREAT|O_RDWR|O_TRUNC), 0666);
			if (ofd == -1) {
				open_failure(argv[0], ofile);
				exit(1);
			}
			if (aout) {
				if (verbose) printf("Writing A.OUT header\n");
				header[1] = (insert_ptr-prom);
				write(ofd, header, 0x20);
			} else {
				if (verbose) printf("Writing binary file\n");
			}
			write(ofd, prom, (insert_ptr-prom));
			close(ofd);
		} else {
			/*
			 * Create two files for standalone flash utility. Names
			 * will be <output>.openboot.bin and <output>.post.bin
			 */
			char buff[400];
			int ofd, d;

			if (aout)
				printf("\nIgnoring the -a flag since the "
				    "-s flag was also set.\n");

			for (d = 0; d < 2; d++) {
				(void) strcpy(buff, ofile);
				if (d == 0)
					(void) strcat(buff, ".openboot.bin");
				else
					(void) strcat(buff, ".post.bin");

				ofd = open(buff,
					(O_CREAT|O_RDWR|O_TRUNC), 0666);
				if (ofd == -1)
					open_failure(argv[0], ofile);
				printf("Writing binary file %s.\n", buff);
				if (d == 0)
					write(ofd, prom, pad);
				else
					write(ofd, (prom+pad), pad);
				close(ofd);
			}
		}
	}
	free(holding);
	free(prom);
	exit(0);
}

void
open_failure(char *progname, char *ofilename)
{
	fprintf(stderr, "%s: open %s for writing failed.\n",
	    progname, ofilename);
	exit(1);
}
