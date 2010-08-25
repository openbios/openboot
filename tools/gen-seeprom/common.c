/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: common.c
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
 * id: @(#)common.c 1.2 02/01/24
 * purpose:
 * copyright: Copyright 2000-2002 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "gen-seeprom.h"
#include "prototypes.h"

union data_format {
	unsigned char str[8];
	unsigned long long value;
};

/*
 * scan decimal or hex value in from a line of input
 */


void
strip_val(char *input_str, unsigned int *input_val)
{
	if ((strncmp(input_str, "0x", 2) == 0) ||
	    (strncmp(input_str, "0X", 2) == 0)) {
		sscanf(&input_str[2], "%x", input_val);
	} else {
		sscanf(&input_str[0], "%d", input_val);
	}
}

int
scan_line(char *line, unsigned int *input_val)
{
	char temp[MAXNAMESIZE];
	char input_str[MAXNAMESIZE];

	if (sscanf(line, "%32s %32s", temp, input_str) != 2) {
		return (ERROR);
	}
	strip_val(input_str, input_val);
	return (NO_ERROR);
}


/*
 * convert an integer value into a byte string and assign it to data_ptr
 * at the given offset
 */

void
write_bytes(unsigned int input_val, int size, int offset,
    unsigned char *data_ptr)
{
	unsigned char byte;

	while (size) {
		byte = input_val >> ((size-1)*8);
		byte &= 0xff;
		data_ptr[offset++] = byte;
		size--;
	}
}

void
store_chars(int len, unsigned char *string, unsigned char **ptr)
{
	union data_format data;

	while (len > 0) {
		if (len > 8) {
			memcpy(data.str, string, 8);
			store_bytes(8, data.value, ptr);
			len -= 8;
			string += 8;
		} else {
			memcpy(data.str, string, len);
			data.value >>= (8-len)*8;
			store_bytes(len, data.value, ptr);
			len = 0;
		}
	}
}

/* Internet checksum */
unsigned short
checksum(unsigned short *addr, int count)
{
	int sum = 0;
	while (count > 1) {
		sum += *addr++;
		count -= 2;
	}

	if (count > 0)
		sum += *(unsigned char *) addr;

	while (sum >> 16) {
		sum = (sum & 0xffff) + (sum >> 16);
	}

	sum = (~sum) & 0xffff;
	if (sum == 0)
		sum = 0xffff;
	return (sum);
}
