/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: elf2bin.c
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
 * id: @(#)elf2bin.c 1.1 96/06/18
 * purpose: 
 * copyright: Copyright 1996 Sun Microsystems, Inc.  All Rights Reserved
*/

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <libelf.h>

int debug = 0;

char *sh_types[SHT_NUM] = {
    "SHT_NULL",
    "SHT_PROGBITS",
    "SHT_SYMTAB",
    "SHT_STRTAB",
    "SHT_RELA",
    "SHT_HASH",
    "SHT_DYNAMIC",
    "SHT_NOTE",
    "SHT_NOBITS",
    "SHT_REL",
    "SHT_SHLIB",
    "SHT_DYNSYM"
};


char *sh_flags[] = {
    "",			/* 0 */
    "SHF_WRITE",	/* 1 */
    "SHF_ALLOC",	/* 2 */
    0,			/* 3 */
    "SHF_EXECINSTR"	/* 4 */
};


int
main(int argc, char **argv)
{
    int ifd, ofd;

    if (argc != 3 ) usage();

    if ((ifd = open(argv[1], O_RDWR)) == -1) {
	perror("elf2bin: Can't open input file ");
	fprintf(stderr, "%s\n", argv[1]);
	exit(-1);
    }

    if ((ofd = open(argv[2], O_CREAT|O_TRUNC|O_WRONLY, 0666)) == -1) {
	perror("elf2bin: Can't open output file ");
	fprintf(stderr, "%s\n", argv[2]);
	close(ifd);
	exit(-2);

    }

    return elf2bin(ifd, ofd);

}

int
elf2bin(int ifd, int ofd)
{
    Elf *elf, *arf;
    Elf_Cmd cmd;

    if (elf_version(EV_CURRENT) == EV_NONE) {
	    /* library out of date */
	    /* recover from error */
    }
    cmd = ELF_C_READ;
    arf = elf_begin(ifd, cmd, (Elf *)0);
    elf_fill(0);
    while ((elf = elf_begin(ifd, cmd, arf)) != 0) {
	Elf32_Ehdr *ehdr;
	if ((ehdr = elf32_getehdr(elf)) != 0) {
	    /* process the file ... */
	    unsigned int size = 0;
	    unsigned int base = 0;
	    Elf_Scn *scn = 0;

	    while ((scn = elf_nextscn(elf, scn)) != 0) {
		/* process section */
		Elf32_Shdr *shdr;
		Elf_Data *data = 0;

		shdr = elf32_getshdr(scn);

		if (debug) dump_shdr(shdr);

		    if ((data = elf_getdata(scn, data)) == 0 ||
			data->d_size == 0) {
			/* error or no data */
		    } else {
			if (debug) dump_data(data);

			if (base == 0) base = shdr->sh_addr;

			if ((shdr->sh_type == SHT_PROGBITS) &&
			    ((shdr->sh_flags & SHF_ALLOC) == SHF_ALLOC)) {
			    /* interesting section ... */
			    if (base + size != shdr->sh_addr) {
				unsigned int pad = shdr->sh_addr - base - size;
				if (pad > 0x1000) {
				    base = shdr->sh_addr;
				    size = 0;
				} else {
				    while (pad) {
					long b = 0;
					write(ofd, &b, sizeof(long));
					pad -= sizeof(long);
				    }
				}
			    }
			    if (write(ofd, data->d_buf, data->d_size) !=
				data->d_size) {
				close(ifd);
				close(ofd);
				return(1);
			    } else {
				size += data->d_size;
			    }
			}
		    }
	    }

	}
	cmd = elf_next(elf);
	elf_end(elf);
    }
    elf_end(arf);
    close(ofd);
    close(ifd);
    return(0);
}

dump_shdr(Elf32_Shdr *shdr)
{
    printf("sh_name = 0x%x\n", shdr->sh_name);
    printf("sh_type = 0x%x %s\n",
	   shdr->sh_type,
	   sh_types[shdr->sh_type]
	);
    printf("sh_flags = 0x%x %s %s %s\n",
	   shdr->sh_flags,
	   sh_flags[shdr->sh_flags & SHF_WRITE],
	   sh_flags[shdr->sh_flags & SHF_ALLOC],
	   sh_flags[shdr->sh_flags & SHF_EXECINSTR]
	);
    printf("sh_addr 0x%x\n", shdr->sh_addr);
    printf("sh_offset 0x%x\n", shdr->sh_offset);
    printf("sh_size 0x%x\n", shdr->sh_size);
    printf("sh_link 0x%x\n", shdr->sh_link);
    printf("sh_info 0x%x\n", shdr->sh_info);
    printf("sh_addralign 0x%x\n", shdr->sh_addralign);
    printf("sh_entsize 0x%x\n", shdr->sh_entsize);

}

dump_data(Elf_Data *data)
{
    printf("\td_buf 0x%x\n", data->d_buf);
    printf("\td_type 0x%x\n", data->d_type);
    printf("\td_size 0x%x\n", data->d_size);
    printf("\td_off 0x%x\n", data->d_off);
    printf("\td_align 0x%x\n", data->d_align);
    printf("\td_version 0x%x\n", data->d_version);
    printf("\n");
}

int
usage()
{
    fprintf(stderr, "Usage: elf2bin forth.prom forth.bin\n");
    exit(-3);
}
