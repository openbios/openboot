/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: mem-seeprom.c
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
 * id: @(#)mem-seeprom.c 1.4 05/11/15
 * purpose:
 * copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/param.h>
#include "gen-seeprom.h"
#include "mem-seeprom.h"
#include "prototypes.h"

struct fixed_seeprom mem_seeprom_data[] = {
	/*   name		size	type	value */
	{ NULL, 0, 0, 0, NULL},
};

static struct dimm_list_entry *dimm_list = NULL;
static struct dimm_list_entry *cur_dimm;

/* mem_layout is array of pointers to data for each memc */
static struct mem_data_entry *mem_layout = NULL;

static int max_bits = 0;
static int max_banks = 0;
static int num_dimms_per_bank = 0;
static int num_memc = 1;

static int cur_memc = 0;   /* bit_mask to indicate which memc data applies */
static int force_default_mc = 0;   /* support for older cfgs w/out memc_id */

static int max_encode_dimm_bits = 0;
static int max_dimms  = 0;
static int num_dimms_in_list = 0;
static int num_bits_in_list = 0;
static int *bit_to_dimm_map = NULL;
static int *bit_to_pin_map = NULL;

static int processing_dimm_list = 0;
static int processing_bit_map = 0;
static int table_width = 0;
static int memc_id_init = 0;

static int
parse_memc_id(char *line)
{
	unsigned int input_val;

	if (scan_line(line, &input_val) == ERROR)
		return (ERROR);

	/* For each memc_id, set the mask bit */
	if ((input_val >= 0) && (input_val < num_memc)) {
		cur_memc |= (1 << input_val);
		memc_id_init = 1;
	} else {
		print_error("Invalid memc_id\n");
		return (ERROR);
	}

	return (NO_ERROR);
}

static int
update_dimm_list(char *parameter, char *line)
{

	char temp[MAXNAMESIZE], input_str[DIMM_NAME_SIZE+1];

	if (strcmp("memc_id", parameter) == 0) {
		return (parse_memc_id(line));
	} else if (strcmp("DIMM", parameter) != 0) {
		fprintf(stderr, "%s is not a valid DIMM list parameter\n",
			parameter);
		return (ERROR);
	}
	if (sscanf(line, "%32s %s", temp, input_str) != 2) {
		fprintf(stderr, "DIMM list entries need 2 strings\n");
		return (ERROR);
	}
	if (strlen(input_str) > (DIMM_NAME_SIZE - 1)) {
		fprintf(stderr, "DIMM name cannot be greater than %d letters\n",
			DIMM_NAME_SIZE-1);
		return (ERROR);
	}

	if (dimm_list == NULL) {
		dimm_list = malloc(sizeof (struct dimm_list_entry));
		dimm_list->next = NULL;
		cur_dimm = dimm_list;
	} else {
		cur_dimm->next = malloc(sizeof (struct dimm_list_entry));
		cur_dimm = cur_dimm->next;
		cur_dimm->next = NULL;
	}
	num_dimms_in_list += 1;
	(void) strcpy(cur_dimm->name, input_str);
	return (NO_ERROR);
}

int prev_bit_num = 0;


static int
update_bit_map(char *parameter, char *line)
{
	int bit_num, dimm, pin_num;

	if (strcmp("memc_id", parameter) == 0) {
		return (parse_memc_id(line));
	}

	if (sscanf(line, "%d %d %d", &bit_num, &dimm, &pin_num) != 3) {
		fprintf(stderr, "bit map entries need 3 numeric values\n");
		return (ERROR);
	}

	if ((bit_num >= 0 && (bit_num < (max_bits))) &&
		(dimm >= 0 && (dimm < (num_dimms_per_bank))) &&
		(pin_num >= 0))  {
		bit_to_dimm_map[bit_num] = dimm;
		bit_to_pin_map[bit_num] = pin_num;
	} else {
		fprintf(stderr, "Invalid bit map entry for bit# %d\n", bit_num);
		fprintf(stderr, "bit#, dimm# and pin# must be >= 0, ");
		fprintf(stderr, " bit# must be < %d and dimm# < %d\n", max_bits,
			num_dimms_per_bank);
		return (ERROR);
	}

	num_bits_in_list++;

	return (NO_ERROR);

}

static int
mem_params(char *line, int *mem_data)
{
	char temp2[MAXNAMESIZE];
	int data = 0;

	if ((sscanf(line, "%32s %d", temp2, &data) != 2) || (data <= 0)) {
		return (ERROR);
	} else {
		*mem_data = data;
	}
	return (NO_ERROR);
}

static int
init_mem_params()
{
	int retval = NO_ERROR;

	if (table_width == 0) {
		print_error("table_width must be initialized!\n");
		retval = ERROR;
	}
	if (max_banks == 0) {
		print_error("max_banks must be initialized!\n");
		retval = ERROR;
	}
	if (max_bits == 0) {
		print_error("max_bits must be initialized!\n");
		retval = ERROR;
	}
	if (num_dimms_per_bank == 0) {
		print_error("num_dimms_per_bank must be initialized!\n");
		retval = ERROR;
	}
	if (mem_layout == NULL) {
		print_error("num_memc not initialized.  Assuming 1\n");
		mem_layout = malloc(sizeof (struct mem_data_entry));
		force_default_mc = 1;
	}
	return (retval);
}

int
mem_dynamic(char *parameter, char *line)
{

	int retval = NO_ERROR;
	unsigned long long temp;
	char temp2[MAXNAMESIZE];
	int count, i;

	if (strcmp(parameter, "table_width") == 0) {
		retval =  mem_params(line, &table_width);
	} else if (strcmp(parameter, "max_bits") == 0) {
		retval =  mem_params(line, &max_bits);
	} else if (strcmp(parameter, "max_banks") == 0) {
		retval =  mem_params(line, &max_banks);
	} else if (strcmp(parameter, "num_memc") == 0) {
		retval =  mem_params(line, &num_memc);
		if (mem_layout == NULL) {
			mem_layout =
			malloc(sizeof (struct mem_data_entry)*num_memc);
		} else {
			printf("ERROR: Already initialized num_memc\n");
			retval = ERROR;
		}
	} else if (strcmp(parameter, "num_dimms_per_bank") == 0) {
		retval = mem_params(line, &num_dimms_per_bank);
		if (retval != ERROR)  {
			max_dimms = num_dimms_per_bank * max_banks;
			max_encode_dimm_bits = 0;
			count = num_dimms_per_bank;
			while (count != 1) {
				count >>= 1;
				max_encode_dimm_bits++;
			}
		}
	} else if (processing_dimm_list) {
		if (strcmp(parameter, "dimm_list_end") == 0) {
			processing_dimm_list = 0;
			if (num_dimms_in_list !=
				(num_dimms_per_bank * max_banks)) {
				sprintf(err_string,
					"DIMM list must have %d names!\n",
					num_dimms_per_bank * max_banks);
				print_error(err_string);
				retval = ERROR;
			}
			if (force_default_mc) {
				cur_memc = 1;
			} else if (memc_id_init == 0) {
				print_error("Must init memc_id in dimm_list\n");
				retval = ERROR;
			}
			for (i = 0; i < num_memc; i++) {
				if (cur_memc & (1 << i)) {
					mem_layout[i].dimm_list = dimm_list;
				}
			}
			dimm_list = NULL;
		} else {
			retval = update_dimm_list(parameter, line);
		}
	} else if (processing_bit_map) {
		if (strcmp(parameter, "bit_map_end") == 0) {
			processing_bit_map = 0;
			if (num_bits_in_list != max_bits) {
				sprintf(err_string,
				    "Bit map has %d entries, should have %d!\n",
				    num_bits_in_list, max_bits);
				print_error(err_string);
				retval = ERROR;
			}
			if (force_default_mc) {
				cur_memc = 1;
			} else if (memc_id_init == 0) {
				print_error("Must init memc_id in bitmap\n");
				retval = ERROR;
			}
			for (i = 0; i < num_memc; i++) {
				if (cur_memc & (1 << i)) {
					mem_layout[i].bit_to_dimm_map =
						bit_to_dimm_map;
					mem_layout[i].bit_to_pin_map =
						bit_to_pin_map;
				}
			}
		} else {
			retval = update_bit_map(parameter, line);
		}
	} else if (strcmp(parameter, "dimm_list_start") == 0) {
		if (init_mem_params() == NO_ERROR) {
			num_dimms_in_list = 0;
			processing_dimm_list = 1;
			cur_memc = 0;
			memc_id_init = 0;
		} else
			retval = ERROR;
	} else if (strcmp(parameter, "dimm_list_end") == 0) {
		fprintf(stderr, "Missing dimm_list_start\n");
		retval = ERROR;
	} else if (strcmp(parameter, "bit_map_start") == 0) {
		if (init_mem_params() == NO_ERROR) {
			num_bits_in_list = 0;
			bit_to_dimm_map = malloc(max_bits * sizeof (int));
			bit_to_pin_map =  malloc(max_bits * sizeof (int));
			processing_bit_map = 1;
			cur_memc = 0;
			memc_id_init = 0;
		} else
			retval = ERROR;
	} else {
		retval = UNKNOWN;
	}
	return (retval);
}

static void
free_mem(void)
{
	struct dimm_list_entry *dimm_ptr, *tmp1;

	free(bit_to_dimm_map);
	free(bit_to_pin_map);

	dimm_ptr = dimm_list;
	while (dimm_ptr->next != NULL) {
		tmp1 = dimm_ptr->next;
		free(dimm_ptr);
		dimm_ptr = tmp1;
	}
	free(dimm_ptr);
}

void
write_mem(unsigned char **ptr)
{
	struct dimm_list_entry *dimm_ptr;
	unsigned char *p;
	int bits;
	int i, j, new_val, size;

	size = (max_dimms * DIMM_NAME_SIZE) + max_bits +
		(max_bits*max_encode_dimm_bits)/8 + TABLE_WIDTH_LEN + 1;
	store_bytes(4, (unsigned long long) size, ptr);

	for (j = 0; j < num_memc; j++) {
		dimm_ptr = mem_layout[j].dimm_list;
		while (dimm_ptr != NULL) {
			p = (unsigned char *) dimm_ptr->name;
			store_chars(DIMM_NAME_SIZE, p, ptr);
			dimm_ptr = dimm_ptr->next;
		}
		store_bytes(1, (unsigned long long) table_width, ptr);

		bits = max_bits - 1;
		while (bits >= 0) {
			new_val = 0;
			for (i = 8-max_encode_dimm_bits; i >= 0;
					i -= max_encode_dimm_bits) {
				new_val |=
				mem_layout[j].bit_to_dimm_map[bits--] << i;
			}
			store_bytes(1, (unsigned long long) new_val, ptr);
		}
		for (i = 0; i < max_bits; i++) {
			store_bytes(1,
			(unsigned long long) mem_layout[j].bit_to_pin_map[i],
			    ptr);
		}
		/* last byte ends in 0 */
		store_bytes(1, 0, ptr);
	}
}

void
dump_mem(void)
{
}

int
check_mem(void)
{
	return (0);
}

int
reg_mem(char *s1, data_reg **reg)
{
	return (0);
}
