/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: sys-seeprom.c
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
 * id: @(#)sys-seeprom.c 1.7 06/04/27
 * purpose:
 * copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <strings.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <fcntl.h>
#include "gen-seeprom.h"
#include "sys-seeprom.h"
#include "prototypes.h"

#define	SYS_DEFAULT_MAGIC 0x5359

#define	MAX_TABLE_SIZE	  1000
#define	OBP_RO_MAX	  0x400

extern int system_type;
extern struct fixed_seeprom *seeprom_data;

struct fixed_seeprom sys_seeprom_data[] = {
	/*   name		size	type	value */
	{ "id_magic",		2,	NUM,	0, NULL },
	{ "ro-checksum",	1,	NUM,	0, NULL },
	{ "ro-size",		2,	NUM,	0, NULL  },
	{ "id_format",		1,	NUM,	0, NULL },
	{ "pad",		2,	NUM,	0, NULL },
	{ "pad",		8,	NUM,	0, NULL },
	{ "sys_speed_max",	1,	NUM,	0, NULL },
	{ "sys_speed_min",	1,	NUM,	0, NULL },
	{ "upa_speed_max",	1,	NUM,	0, NULL },
	{ "upa_speed_min",	1,	NUM,	0, NULL },
	{ "stick_freq",		1,	NUM,	0, NULL },
	{ "memc",		1,	NUM,	0, NULL },
	{ "num_timing_sets",	1,	NUM,	0, NULL },
	{ "pad",		1,	NUM,	0, NULL },
	{ NULL, 0, 0, 0, NULL},
};

struct fixed_seeprom fiesta_sys_data[] = {
	/*   name		size	type	value */
	{ "id_magic",		2,	NUM,	0, NULL },
	{ "ro-checksum",	1,	NUM,	0, NULL },
	{ "ro-size",		2,	NUM,	0, NULL  },
	{ "id_format",		1,	NUM,	0, NULL },
	{ "pad",		2,	NUM,	0, NULL },
	{ "pad",		6,	NUM,	0, NULL },
	{ "sys_ssc",	        1,	NUM,	0, NULL },
	{ "pci_ssc",	        1,	NUM,	0, NULL },
	{ "sys_speed_max",	1,	NUM,	0, NULL },
	{ "sys_speed_min",	1,	NUM,	0, NULL },
	{ "upa_speed_max",	1,	NUM,	0, NULL },
	{ "upa_speed_min",	1,	NUM,	0, NULL },
	{ "stick_freq",		1,	NUM,	0, NULL },
	{ NULL, 0, 0, 0, NULL},
};

static struct timing_table_entry *timing_table = NULL;
static struct timing_table_entry *cur_timing_table;

static int processing_timing = 0;

void
set_byte(int index, int data, unsigned short *byte)
{
	*byte |= data;
	*byte <<= (4*index);
}

static int
update_timing_table(char *parameter, char *line)
{
	int i = 0, offset = 0;
	unsigned int input_val;

	while (strcmp(timing_parameters[i].name, parameter)) {
		offset += timing_parameters[i++].size;
		if (timing_parameters[i].name == NULL) {
			fprintf(stderr,
			    "%s is not a valid timing parameter\n", parameter);
			return (1);
		}
	}

	if (scan_line(line, &input_val) == ERROR)
		return (ERROR);

	write_bytes(input_val, timing_parameters[i].size, offset,
	    cur_timing_table->timing_data);

	return (NO_ERROR);
}

int
sys_dynamic(char *parameter, char *line)
{

	int retval = NO_ERROR;
	unsigned long long temp;

	if (processing_timing) {
		if (strcmp(parameter, "timing_table_end") == 0) {
			temp = get_seeprom("num_timing_sets");
			update_seeprom("num_timing_sets", temp+1);
			processing_timing = 0;
		} else {
			retval = update_timing_table(parameter, line);
		}
	} else {
		if (strcmp(parameter, "timing_table_start") == 0) {
			if (timing_table == NULL) {
				timing_table = malloc(
				    sizeof (struct timing_table_entry));
				timing_table->next = NULL;
				cur_timing_table = timing_table;
			} else {
				cur_timing_table->next = malloc(
				    sizeof (struct timing_table_entry));
				cur_timing_table = cur_timing_table->next;
				cur_timing_table->next = NULL;
			}
			processing_timing = 1;
		} else if (strcmp(parameter, "timing_table_end") == 0) {
			fprintf(stderr, "Missing timing_table_start\n");
			retval = 1;
		} else {
			retval = UNKNOWN;
		}
	}
	return (retval);
}

static void
free_sys(void)
{
	struct timing_table_entry *table_ptr2, *tmp2;

	if (timing_table != NULL) {
		table_ptr2 = timing_table;
		while (table_ptr2->next != NULL) {
			tmp2 = table_ptr2->next;
			free(table_ptr2);
			table_ptr2 = tmp2;
		}
		free(table_ptr2);
	}
}

void
write_sys(unsigned char **ptr)
{
	struct timing_table_entry *table_ptr2;
	unsigned char *p;
	int i, size, len;

	i = size = 0;
	while (seeprom_data[i].name != NULL) {
		size += seeprom_data[i++].size;
	}

	table_ptr2 = timing_table;
	while (table_ptr2 != NULL) {
		len = TIMING_ENTRY_SIZE;
		size += len;
		p = table_ptr2->timing_data;
		store_chars(TIMING_ENTRY_SIZE, p, ptr);
		table_ptr2 = table_ptr2->next;
	}

	free_sys();
}

void
dump_sys(void)
{
}

static void
sys_checksum(unsigned short *checksum, unsigned int bytes,
    unsigned char *addr)
{
	while (bytes--) {
		*checksum ^= *addr++;
	}
}

int
check_sys(void)
{
	int error = 0;

	if (get_seeprom("id_magic") != SYS_DEFAULT_MAGIC) {
		sprintf(err_string,
		    "id_magic must be 0x%4x!", SYS_DEFAULT_MAGIC);
		print_error(err_string);
		error = 1;
	}

	if (system_type == EXCALIBUR) {
		if (timing_table == NULL) {
			print_error("Must specify a timing table!\n");
			error = 1;
		}

		if (processing_timing) {
			print_error("Missing timing_table_end!\n");
			error = 1;
		}
	}

	if (!error) {
		int i, size;
		unsigned short checksum;
		struct timing_table_entry *table_ptr2;

		i = checksum = size = 0;
		while (seeprom_data[i].name != NULL) {
			if (strcmp(seeprom_data[i].name, "checksum") &&
			    strcmp(seeprom_data[i].name, "ro-size")) {
				sys_checksum(&checksum,
				    seeprom_data[i].size,
				    (uchar_t *)&seeprom_data[i].value +
				    (8-seeprom_data[i].size));
			}
			size += seeprom_data[i].size;
			i++;
		}
		table_ptr2 = timing_table;
		while (table_ptr2 != NULL) {
			sys_checksum(&checksum,
			    TIMING_ENTRY_SIZE, table_ptr2->timing_data);
			size += TIMING_ENTRY_SIZE;
			table_ptr2 = table_ptr2->next;
		}

		sys_checksum(&checksum, 2, (unsigned char *)&size+2);
		update_seeprom("ro-size", (unsigned long long)size);
		update_seeprom("ro-checksum", (unsigned long long)checksum);
	}
	return (error);
}

int
reg_sys(char *s1, data_reg **reg)
{
	return (0);
}
