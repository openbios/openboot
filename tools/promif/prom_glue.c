/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prom_glue.c
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
 * id: @(#)prom_glue.c 1.1 03/04/01
 * purpose: 
 * Copyright 1994-2001, 2003 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */

#include <sys/promif.h>
#include <sys/promimpl.h>
#include <sys/obpdefs.h>
#include <sys/varargs.h>

caddr_t strstr(caddr_t s1, caddr_t s2);

/*
 *    flash update functions
 */

ihandle_t
get_parent_ihandle(ihandle_t child_ihandle)
{
	char parent_name[OBP_MAXPATHLEN];
	phandle_t  child_phandle, parent_phandle;

	child_phandle = prom_getphandle(child_ihandle);
	parent_phandle = prom_parentnode(child_phandle);
	prom_phandle_to_path(parent_phandle, parent_name, OBP_MAXPATHLEN);

	return (prom_open(parent_name));
}

void *
mmap(void *addr, size_t len, int32_t prot, uint32_t flags,
	ihandle_t fildes, int32_t off)
{
	ihandle_t dev_ihandle, parent_ihandle;
	phandle_t dev_phandle, parent_phandle;
	void *rp;
	static char reg_prop[100], dev_name[100], bus_type[100];
	uint32_t *reg_ptr;
	uint_t adr_cells, size_cells;

	dev_ihandle = fildes;
	dev_phandle = prom_getphandle(dev_ihandle);
	prom_getprop(dev_phandle, "reg", reg_prop);
	reg_ptr = (uint32_t *)reg_prop;

	parent_ihandle = get_parent_ihandle(dev_ihandle);
	parent_phandle = prom_getphandle(parent_ihandle);

	prom_getprop(parent_phandle, "#address-cells", (caddr_t)&adr_cells);
	prom_getprop(parent_phandle, "#size-cells", (caddr_t)&size_cells);

	prom_getprop(dev_phandle, "name", dev_name);
	prom_getprop(parent_phandle, "device_type", bus_type);

	/*
	 * Flashprom devices need special handling of offset arg
	 * as specified by the /dev/flashprom driver
	 */

	if ((strcmp(dev_name, "flashprom") == 0)) {
		if (off != NULL) {
			reg_ptr += ((off >> 28) & 0xf)
			    * (adr_cells + size_cells);
			off = (off & 0xfffffff);
			*(reg_ptr + 1) += off;
		}
		rp = (void *)prom_mapin(parent_ihandle, reg_ptr,
		    adr_cells, len);

		return ((void *)((int32_t)rp & 0xffffffff));
	}

	/*
	 * PCI addresses are relocatable so use assigned-addresses
	 */

	if ((strcmp(bus_type, "pci") == 0)) {
		prom_getprop(dev_phandle, "assigned-addresses", reg_prop);
	}

	reg_ptr += (off * (adr_cells + size_cells));
	rp = (void *)prom_mapin(parent_ihandle, reg_ptr, adr_cells, len);

	return ((void *)((int32_t)rp & 0xffffffff));
}

int32_t
munmap(void *addr, size_t len)
{
	/* nice and platform neutral */
	return (0);
}

uint32_t
sleep(uint32_t sleeptime)
{
	uint32_t initial, current;
	initial = prom_gettime();
	current = prom_gettime();
	/* prom_gettime returns milliseconds */
	while (((current - initial) / 1000) < sleeptime)
		current = prom_gettime();
	return (0);
}

/*
 * Signal handling
 */

int32_t
sigignore(int signal)
{
	/* OBP ignore's all interrupts while running the client program */
	return (0);
}


/*
 * Device I/O group
 */
ihandle_t
open(caddr_t name, int32_t oflag, ...)
{
	ihandle_t fildes;

	if ((strcmp(name, "/dev/openprom")) == 0)
		/*
		 * openprom is a special case.  Return a special FD
		 * to fake out ioctl calls
		 */
		return (OPENPROM_FD);

	fildes = prom_open(name);
	if (strstr(name, "flashprom"))
		FLASHPROM_FD = fildes;
	return (fildes);
}

uint32_t
close(ihandle_t fd)
{
	uint32_t result;

	if (fd == OPENPROM_FD)
		/* openprom never was given a "real" FD */
		return (0);

	result = prom_close(fd);
	if (fd == FLASHPROM_FD)
		FLASHPROM_FD = NULL;
	return (result);
}

uint32_t
read(ihandle_t fd, caddr_t buf, uint32_t len)
{
	return (prom_read(fd, buf, len));
}

uint32_t
write(ihandle_t fd, caddr_t buf, uint32_t len)
{
	return (prom_write(fd, buf, len));
}

uint32_t
seek(ihandle_t fd, u_longlong_t offset)
{
	return (prom_seek(fd, offset));
}

/*
 * Control transfer group
 */


/*  The exit argument isn't used  */
void
exit(int32_t level)
{
	prom_exit_to_mon();
}

/*
 * Resource allocation group
 */

void *
malloc(size_t size)
{
	caddr_t virt;
	/* virt is never used because align(arg 2) = 1 */
	return ((void *)prom_malloc(virt, size, 1));
}


/* This function is pretty much a noop in OBP (right now) */
void
free(caddr_t virt, size_t size)
{
	size = 0;
	prom_free(virt, size);
}

/*
 * Console I/O group
 */

uchar_t
getchar(void)
{
	char c;
	c = prom_getchar();
	/* echo to stdout like unix */
	switch (c) {
	case 13:
		prom_printf("\n");
		c = 10;
		break;
	case 127:
		prom_printf("\b");
		break;
	default:
		prom_printf("%c", c);
		break;
	}
	return (c);
}

void
putchar(char c)
{
	prom_putchar(c);
}

int32_t
mayget(void)
{
	return (prom_mayget());
}

int32_t
mayput(char c)
{
	return (prom_mayput(c));
}

/*  the actual printf command returns an int   */
void
printf(const caddr_t fmt, ...)
{
	__va_list adx;
	va_start(adx, fmt);
	prom_vprintf(fmt, adx);
	va_end(adx);
}

void
vprintf(const caddr_t fmt, __va_list adx)
{
	prom_vprintf(fmt, adx);
}

caddr_t
sprintf(caddr_t s, const caddr_t fmt, ...)
{
	__va_list adx;
	va_start(adx, fmt);
	prom_vsprintf(s, fmt, adx);
	va_end(adx);
	return (s);
}

caddr_t
vsprintf(caddr_t s, const caddr_t fmt, __va_list adx)
{
	prom_vsprintf(s, fmt, adx);
}

/*
 *  Utility routines (proimpl.h)
 */

caddr_t
strcpy(caddr_t s1, caddr_t s2)
{
	return (prom_strcpy(s1, s2));
}

caddr_t
strdup(caddr_t s1)
{
	caddr_t s2;
	s2 = (caddr_t)malloc(strlen(s1) + 1);
	strcpy(s2, s1);
	return (s2);
}

caddr_t
strncpy(caddr_t s1, caddr_t s2, size_t n)
{
	return (prom_strncpy(s1, s2, n));
}

int32_t
strcmp(caddr_t s1, caddr_t s2)
{
	return (prom_strcmp(s1, s2));
}

int32_t
strncmp(caddr_t s1, caddr_t s2, size_t n)
{
	return (prom_strncmp(s1, s2, n));
}

int32_t
strlen(caddr_t s)
{
	return (prom_strlen(s));
}

caddr_t
strrchr(caddr_t s, int32_t c)
{
	return (prom_strrchr(s, c));
}

caddr_t
strcat(caddr_t s1, caddr_t s2)
{
	return (prom_strcat(s1, s2));
}

caddr_t
strchr(const caddr_t s, int32_t c)
{
	return (prom_strchr(s, c));
}

caddr_t
strstr(caddr_t s1, caddr_t s2)
{
	return (prom_strstr(s1, s2));
}

void *
memccpy(caddr_t s1, caddr_t s2, int32_t c, size_t n)
{
	return (prom_memccpy(s1, s2, c, n));
}

void *
memchr(caddr_t s, int32_t c, size_t n)
{
	return (prom_memchr(s, c, n));
}


int32_t
memcmp(caddr_t s1, caddr_t s2, size_t n)
{
	return (prom_memcmp(s1, s2, n));
}

void *
memcpy(caddr_t s1, caddr_t s2, size_t n)
{
	return (prom_memcpy(s1, s2, n));
}

void *
memset(caddr_t s, int32_t c, size_t n)
{
	return (prom_memset(s, c, n));
}
