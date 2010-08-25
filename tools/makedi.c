/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: makedi.c
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
 * id: @(#)makedi.c 1.12 06/02/16
 * purpose:
 * copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
 * copyright: Use is subject to license terms.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/dropins.h>

#define	MAX_DI		(4*1048*1024)

static int compress = 0;
static int verbose = 0;
static int list = 0;
static int group_mode = 0;

static uchar_t *prom;

int comp(unsigned char *src, int size, unsigned char *dest);

static void
usage(char *name)
{
	char *msg =
	    "%s: [-c] [-v] input1 name1 .. inputn namen\n"
	    "   -g   : group mode using src,dropin-name pairs\n"
	    "   -a   : create level2 using existing dropins\n"
	    "   -c   : compress dropins\n"
	    "   -v   : verbose mode\n"
	    "   -t   : list targets\n"
	    "   -s   : list sources\n"
	    "   -d   : list dependancies\n"
	    "   -o   : create a dropin from data\n"
	    "   -O   : overwrite any existing header\n"
	    "\n"
	    "for compress mode, each input will produce a file input.di\n"
	    "group mode changes the format of the args a little\n"
	    "-g <output> name input0 name0 .. intputn namen\n"
	    "-a <output> name input0 input1 .. inputn\n"
	    "-o <output> <srcfile> <diname>\n";

	fprintf(stderr, msg, name);
	exit(1);
}

static int
make_dropin(char *name, unsigned char *prom, unsigned char *buffer, int size)
{
	int crc, i, clen, dlen, compressed;
	unsigned char *pptr;
	obmd_t *di = (obmd_t *)prom;
	unsigned char *dataptr = prom+OBMD_HDR;

	memset((void *) prom, 0, OBMD_HDR);
	compressed = compress;
	if (compress) {
		compresshdr *chdr = (compresshdr *) dataptr;
		/* The magic number is always COMP */
		chdr->magic		= COMP_MAGIC;
		/*
		 * This is the compression type
		 * currently COMP for compress
		 */
		chdr->type		= COMP_MAGIC;
		chdr->decomp_size	= size;

		clen = comp(buffer, size, dataptr+sizeof (compresshdr));

		/* Now adjust the data size */
		clen += sizeof (compresshdr);
		chdr->comp_size = clen;

		if (clen >= size) {
			/*
			 * Compression didn't help this and in fact
			 * has added some bytes, so we undo the compression.
			 */
			compressed = 0;
			clen = size;
			memcpy((void *) dataptr, (void *) buffer, size);
		}
	} else {
		clen = size;
		memcpy((void *) dataptr, (void *) buffer, size);
	}

	strncpy(di->magic, "OBMD", 4);
	di->size  = clen;
	di->res0  = 0;
	di->res1  = 0;
	di->chksum = 0;
	if (strlen(name) > 15) {
		fprintf(stderr, "Error: dropin name > 15 characters\n");
		fprintf(stderr, "Error: -> %s\n", name);
		exit(1);
	}
	memset(di->name, 0, 16);
	strncpy(di->name, name, 15);
	crc = checksum((ushort_t *)di, clen+OBMD_HDR);
	di->chksum = crc;

	if (verbose) {
		printf(" Name: %s size = %lx", di->name, di->size);
		if (compressed)
			printf(" (-%d%%)", ((size-clen)*100)/size);
		printf(" checksum = %x ", di->chksum);
	}
	dlen = OBMD_HDR+clen;
	pptr = prom+dlen;
	if (dlen&3) {
		if (verbose) printf("(+%d)", (dlen&3));

		for (i = (3-(dlen&3)); i >= 0; i--, dlen++) *(pptr+i) = 1;
	}
	if (verbose) printf("\n");
	return (dlen);
}

char *
make_dropin_name(char *name)
{
	static char outname[40];
	char *dot;

	dot = strrchr(name, '/');
	if (dot)
		strcpy(outname, dot+1);
	else
		strcpy(outname, name);
	dot = strrchr(outname, '.');
	if (dot) *dot = 0;
	strcat(outname, ".di");
	return (outname);
}


void
write_dropin(char *argv[], char *name, unsigned char *prom, int dlen)
{
	int ofd;

	ofd = open(name, O_CREAT|O_TRUNC|O_RDWR, 0666);
	if (ofd < 0) {
		fprintf(stderr, "%s: Can't open output file %s\n",
		    argv[0], name);
		exit(1);
	} else {
		if (dlen > MAX_DI) {
			fprintf(stderr, "%s: Output %s exceeds %d bytes\n",
				argv[0], name, MAX_DI);
			exit(1);
		}
		if (write(ofd, prom, dlen) != dlen) {
			fprintf(stderr, "%s: Short write on %s\n",
				argv[0], name);
			exit(1);
		}
		close(ofd);
	}
}

/*
 * makedi [-c] <source> <dropin-name> [<source> <dropin-name>]
 */

void
main(int argc, char **argv)
{
	int ifd, ofd;
	int i;
	int pad = 512;
	struct stat statbuf;
	int c;
	char *group_name;
	char *group_file, *outfile = NULL;
	uchar_t *holding, *insert_pt;
	extern char *optarg;
	extern int optind;
	obmd_t *di;
	int arg_step = 2;
	int append_mode = 0;
	int overwrite = 0;
	int diupdate = 1;

	while ((c = getopt(argc, argv, "acCOvstdgGo:")) != EOF)
		switch (c) {
		case 'a':
			append_mode = 1;
			arg_step = 1;
			break;

		case 's':
			list = 's';
			break;

		case 't':
			list = 't';
			break;

		case 'd':
			list = 'd';
			break;

		case 'v':
			verbose++;
			break;

		case 'c':
			group_mode = 0;
			compress = 1;
			break;

		case 'C':
			group_mode = 0;
			compress = 0;
			break;

		case 'O':
			overwrite = 1;
			break;

		case 'g':
			compress = 0;
			group_mode = 1;
			break;

		case 'o':
			outfile = optarg;
			diupdate = 0;
			break;

		default:
			usage(argv[0]);
		}

	if (list) compress = 0, verbose = 0;
	if (append_mode) {
		if (list) list = 'd';
	}

	insert_pt = prom = (uchar_t *)malloc(MAX_DI);
	if (prom == NULL) {
		fprintf(stderr, "Malloc failed for dropin image\n");
		exit(1);
	}

	holding = (uchar_t *)malloc(MAX_DI);
	if (holding == NULL) {
		fprintf(stderr, "Malloc failed for holding buffer\n");
		exit(1);
	}

	/* Fill with FF */
	memset((void *) prom, 0xff, MAX_DI);
	if (group_mode || append_mode) {
		if (argv[optind] == NULL) {
			fprintf(stderr, "%s: Missing group name\n", argv[0]);
			exit(1);
		}
		group_file = strdup(make_dropin_name(argv[optind]));
		group_name = argv[optind+1];
		if (argv[optind+1] == NULL) {
			fprintf(stderr, "%s: Missing dropin name for %s\n",
			    argv[0], argv[optind]);
			exit(1);
		}
		optind += 2;
		/*
		 * reserve space for the dropin header and marker
		 */
		insert_pt += sizeof (obme_t);
	}

	di = (obmd_t *)holding;
	for (i = optind; i < argc; i += arg_step) {
		int dlen, len, tmp;
		char *outname;

		if ((!append_mode) && (argv[i+1] == NULL)) {
			fprintf(stderr, "%s: Missing dropin name for %s\n",
			    argv[0], argv[i]);
			exit(1);
		}

		if (outfile == NULL) {
		    outname = make_dropin_name(argv[i]);
		} else {
		    outname = outfile;
		}

		if (list) {
			switch (list) {
			case 't':
				if (group_mode) {
					static int once = 0;
					if (!once++)
						printf("%s ", group_file);
				} else {
					printf("%s ", outname);
				}
				break;

			case 's':
				printf("%s ", argv[i]);
				break;

			case 'd':
				if (group_mode || append_mode)
					printf("%s: %s\n",
					    group_file, argv[i]);
				else
					printf("%s: %s\n", outname, argv[i]);
				break;
			}
			continue;
		}

		if (verbose > 1) printf("Loading: %s\n", argv[i]);
		ifd = open(argv[i], O_RDONLY);
		if (ifd < 0) {
			fprintf(stderr,
			    "%s: Can't open input file %s\n",
			    argv[0], argv[i]);
			exit(1);
		}
		fstat(ifd, &statbuf);
		len = statbuf.st_size;
		if (len > MAX_DI) {
			fprintf(stderr, "%s: Input %s exceeds %d bytes\n",
				argv[0], argv[i], MAX_DI);
			exit(1);
		}
		memset((void *) holding, 0xff, MAX_DI);
		tmp = read(ifd, holding, len);
		if (tmp != len) {
			fprintf(stderr, "%s: Short read on %s\n",
				argv[0], argv[i]);
			exit(1);
		}
		close(ifd);
		if (verbose) {
			if (group_mode || append_mode)
				printf("Including: %s,", argv[i]);
			else
				printf("Writing: %s,", outname);
		}

		if (diupdate && (strncmp(di->magic, "OBMD", 4) == 0)) {
			unsigned int *dataptr;

			dataptr = (uint_t *)((uchar_t *)di + sizeof (obmd_t));

			if ((dataptr[0] == COMP_MAGIC) &&
			    (dataptr[1] == di->size)) {
				/*
				 * We can do nothing with dropins that are
				 * already compressed
				 */
				dlen = len;
				if (verbose) {
					printf(" Name: %s size = %lx (COMP)",
					    di->name, di->size);
					printf(" checksum = %x\n", di->chksum);
				}
				if ((group_mode) || (append_mode)) {
					memcpy((void *) insert_pt,
						(void *) holding, len);
				}
			} else {
				char *diname;

				/*
				 * Strip the dropin header off to leave the
				 * raw data and then compress it
				 */
				len -= OBMD_HDR;
				if (append_mode)
					diname = strdup(di->name);
				else
					diname = argv[i+1];
				memcpy((void *) holding,
				    (void *) (holding+OBMD_HDR),
				    len);
				dlen = make_dropin(diname,
				    insert_pt, holding, len);
			}
		} else {
			if (append_mode) {
				fprintf(stderr,
				    "%s: append_mode requires you to provide"
				    " a dropin list (%s)\n",
				    argv[0], argv[optind]);
				exit(1);
			} else {
				if (overwrite) {
					dlen = make_dropin(argv[i+1],
					    insert_pt, (holding + OBMD_HDR),
					    (len - OBMD_HDR));
				} else {
					dlen = make_dropin(argv[i+1],
					    insert_pt, holding, len);
				}
			}
		}

		if (group_mode || append_mode) {
			insert_pt += (dlen + 3) & ~3;
		} else {
			write_dropin(argv, outname, prom, dlen);
		}
	}
	if (group_mode || append_mode) {
		int flen;
		char *outname;
		int bytes;

		bytes = insert_pt - prom;
		if (bytes&3) {
			for (i = (4-(bytes&3)); i > 0; i--, bytes++)
				*insert_pt++ = 1;
		}
		for (i = 4; i > 0; i--, bytes++) *insert_pt++ = 0xff;
		if (verbose) printf("Writing: %s,", group_file);
		strncpy((char *)prom, "OBME", 4);
		memcpy((void *)holding, (void *)prom, bytes);
		flen = make_dropin(group_name, prom, holding, bytes);
		write_dropin(argv, group_file, prom, flen);
	}
	free(holding);
	free(prom);
	exit(0);
}
