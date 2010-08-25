/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: cpu-seeprom.c
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
 * id: @(#)cpu-seeprom.c 1.10 05/11/15
 * purpose:
 * copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
*/

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "gen-seeprom.h"
#include "cpu-seeprom.h"
#include "prototypes.h"

#define	ULTRA3_MODE	1	/* Ultra3 */
#define	ULTRA3_PLUS	2	/* Ultra3+ in 2way E$ mode */
#define	ULTRA3_PLUS_DM	3	/* Ultra3+ in direct mapped mode */

int format_mode, id_magic;
int clk_div_set = 0;
static int speed_ratio_max = 6;
static int speed_ratio_min = 4;
static int cpu_ratios_min = 3;
static int cpu_ratios_bits = 8;	/* # of bits in cpu ratios fru parameter */

extern int do_checksum;
extern int system_type, type;
extern struct fixed_seeprom *seeprom_data;

void
set_magic_bytes(void *data)
{
	if ((int)data != CPU_DEFAULT_MAGIC) {
		do_checksum = 1;
	}
	id_magic = (int)data;
}

void
set_format_byte(void *data)
{
	format_mode = (int)data;
}

void
set_clk_div_byte(void *data)
{
	clk_div_set = 1;
}

struct fixed_seeprom cpu_seeprom_data[] = {
	/*  name		size	type	value */
	{ "id_magic",		2,	NUM,	0, set_magic_bytes },
	{ "id_format",		1,	NUM,	0, set_format_byte  },
	{ "cpu_ratios",		1,	NUM,	0, NULL	 },
	{ "checksum",		2,	NUM,	0, NULL	 },
	{ "clk_divisor",	1,	NUM,	0, set_clk_div_byte },
	{ "cpu_id",		1,	NUM,	0, NULL	 },
	{ "dcr",		8,	NUM,	0, NULL	 },
	{ "lsucr",		8,	NUM,	0, NULL	 },
	{ "ecache_size",	4,	NUM,	0, NULL	 },
	{ "stick_divisor",	1,	NUM,	0, NULL	 },
	{ "speed_table_width",	1,	NUM,	0, NULL	 },
	{ "num_ecache_cfgs",	1,	NUM,	0, NULL	 },
/*
	on excal, the next entry is a pad byte.  Instead of defining
	2 different structs with different names for this byte, we use
	num_memc_cfgs and just leave it as 0 for excal.
*/
	{ "num_memc_cfgs",	1,	NUM,	0, NULL	 },
/*	{ "pad",		1,	NUM,	0, NULL	 }, */
	{ NULL, 0, 0, 0, NULL },
};

struct fixed_seeprom gm_cpu_seeprom_data[] = {
	/*  name		size	type	value */
	{ "id_magic",		2,	NUM,	0, set_magic_bytes },
	{ "id_format",		1,	NUM,	0, set_format_byte  },
	{ "cpu_ratios",		1,	NUM,	0, NULL	 },
	{ "checksum",		2,	NUM,	0, NULL	 },
	{ "clk_divisor",	1,	NUM,	0, set_clk_div_byte },
	{ "cpu_id",		1,	NUM,	0, NULL	 },
	{ "dcr",		8,	NUM,	0, NULL	 },
	{ "lsucr",		8,	NUM,	0, NULL	 },
	{ "core_config",	8,	NUM,	0, NULL	 },
	{ "ecache_size",	4,	NUM,	0, NULL	 },
	{ "stick_divisor",	1,	NUM,	0, NULL	 },
	{ "speed_table_width",	1,	NUM,	0, NULL	 },
	{ "num_ecache_cfgs",	1,	NUM,	0, NULL	 },
	{ "num_memc_cfgs",	1,	NUM,	0, NULL	 },
	{ NULL, 0, 0, 0, NULL },
};

struct fixed_seeprom serrano_cpu_seeprom_data[] = {
	/*  name		size	type	value */
	{ "id_magic",		2,	NUM,	0, set_magic_bytes },
	{ "id_format",		1,	NUM,	0, set_format_byte  },
	{ "cpu_id",		1,	NUM,	0, NULL  },
	{ "checksum",		2,	NUM,	0, NULL  },
	{ "cpu_ratios",		2,	NUM,	0, NULL  },
	{ "dcr",		8,	NUM,	0, NULL  },
	{ "lsucr",		8,	NUM,	0, NULL  },
	{ "ecache_size",	4,	NUM,	0, NULL  },
	{ "clk_divisor",	1,	NUM,	0, set_clk_div_byte },
	{ "stick_divisor",	1,	NUM,	0, NULL  },
	{ "speed_table_width",	1,	NUM,	0, NULL  },
	{ "num_ecache_cfgs",	1,	NUM,	0, NULL  },
	{ "num_memc_cfgs",	1,	NUM,	0, NULL  },
	{ "pad",		7,	NUM,	0, NULL  },
	{ NULL, 0, 0, 0, NULL },
};

struct fixed_seeprom cpu_rw_data[] = {
	/*  name		size	type	value */
	{ "id_magic",		2,	NUM,	0, NULL },
	{ "id_format",		1,	NUM,	0, set_format_byte  },
	{ "num_memc_cfgs",	1,	NUM,	0, NULL  },
	{ NULL, 0, 0, 0, NULL },
};


data_reg dcr[] = {
	/*   field		 pos	size  */
	{ "obs",		 6,	3	 },
	{ "bpe",		 5,	1	 },
	{ "rpe",		 4,	1	 },
	{ "si",			 3,	1	 },
	{ "ms",			 0,	1	 },
	{ NULL,			 0,	0	},
};

data_reg lsucr[] = {
	/*  field		pos	size	*/
	{ "cp",			49,	1  },
	{ "cv",			48,	1  },
	{ "me",			47,	1  },
	{ "re",			46,	1  },
	{ "pe",			45,	1  },
	{ "hpe",		44,	1  },
	{ "spe",		43,	1  },
	{ "sl",			42,	1  },
	{ "we",			41,	1  },
	{ "pm",			33,	8  },
	{ "vm",			25,	8  },
	{ "pr",			24,	1  },
	{ "pw",			23,	1  },
	{ "vr",			22,	1  },
	{ "vw",			21,	1  },
	{ "fm",			4,	16  },
	{ "dm",			3,	1  },
	{ "im",			2,	1  },
	{ "dc",			1,	1  },
	{ "ic",			0,	1  },
	{ NULL,			0,	0  },
};

static struct ecache_entry *cpu_ecache_table = NULL;
static struct speed_entry *speed_table = NULL;
static struct fiesta_memc_entry *fiesta_memc = NULL;

static int
calculate_mspd(unsigned short mclk, unsigned long long mcr2,
					unsigned int cpuspeed)
{

#define	MEM_SPEED(a, b)		((cpuspeed * a) / b)

	int rc = NO_ERROR;
	unsigned int mspeed, mcr2_ratio;

	if (system_type == SERRANO) {
		mcr2_ratio = mcr2 & 0x1f;
	} else {
		mcr2_ratio = mcr2 & 0xf;
	}
	switch (mcr2_ratio) {
		case	0:
			mspeed = MEM_SPEED(1, 8);
			break;
		case	2:
			mspeed = MEM_SPEED(1, 9);
			break;
		case	4:
			mspeed = MEM_SPEED(1, 10);
			break;
		case	5:
			mspeed = MEM_SPEED(2, 21);
			break;
		case	6:
			mspeed = MEM_SPEED(1, 11);
			break;
		case	8:
			mspeed = MEM_SPEED(1, 12);
			break;
		case	9:
			mspeed = MEM_SPEED(2, 25);
			break;
		case	0xa:
			mspeed = MEM_SPEED(1, 13);
			break;
		case	0xb:
			mspeed = MEM_SPEED(2, 27);
			break;
		case	0xc:
			mspeed = MEM_SPEED(1, 14);
			break;
		case	0xe:
			mspeed = MEM_SPEED(1, 15);
			break;
		/* following entries with bit 4 set are Serrano only */
		case	0x10:
			mspeed = MEM_SPEED(1, 16);
			break;
		case	0x11:
			mspeed = MEM_SPEED(2, 33);
			break;
		case	0x13:
			mspeed = MEM_SPEED(2, 35);
			break;
		case	0x14:
			mspeed = MEM_SPEED(1, 18);
			break;
		default:
			sprintf(err_string,
				"memc_entry: Invalid CPU_SDRAM clk ratio %x",
			mcr2_ratio);
			rc = ERROR;
			break;
	}
	if (mspeed > mclk) {
		sprintf(err_string,
			"memc_entry: calculated mem speed %d exceeds mclk %hd",
		mspeed, mclk);
		rc = ERROR;
	}
	return (rc);
}

/*
 * MCR0_CTL_MASK is used to check if following control bits are set
 * in the memc_entries, they should be 0:
 * X4DIMM, Addr_Gen, DIMMX_bankY, AUTO_REFRESH_EN, CKE_EN, CLK_UPDATE,
 * PRECHG_ALL, SET_MODE_REG
 */

#define	MCR0_CTL_MASK		-1 ^ 0x0ffffb03ff803fffLL

/*
 * Get fiesta_memc_entries parameters of format:
 * memc_entry   bus_max(Mhz) bus_min(Mhz) ratio mspeed mcr0 mcr1 mcr2
 */

static unsigned int
fiesta_memc_input(char *line, struct fiesta_memc_entry *entry)
{
	char parameter[MAXNAMESIZE];
	unsigned short bus_hi, bus_lo, entry_id, ratio, mclk;
	unsigned long long mcr[3];
	int i, entries;

	for (i = 0; i < 3; i++)
		mcr[i] = 0;

	entries = sscanf(line, "%32s %hd %hd %hd %hd %hd %llx %llx %llx",
		parameter, &bus_hi, &bus_lo, &entry_id, &ratio, &mclk, &mcr[0],
		&mcr[1], &mcr[2]);
	if ((entries != 9)) {
		print_error("memc_entry line incorrectly defined");
		return (ERROR);
	}
	if (bus_hi < bus_lo) {
		print_error("memc_entry.bus_hi must be greater than bus_lo!");
		return (ERROR);
	}
	if (entry_id > FIESTA_MAX_MEMC) {
		sprintf(err_string, "memc_entry: id cannot exceed %d",
			FIESTA_MAX_MEMC);
		print_error(err_string);
		return (ERROR);
	}

	entry->bus_hi = bus_hi;
	entry->bus_lo = bus_lo;
	entry->entry_id = entry_id;
	entry->ratio = ratio;

	if (calculate_mspd(mclk, mcr[1], bus_hi * ratio)) {
		print_error(err_string);
		sprintf(err_string, "Error in memc_entry %d", entry_id);
		print_error(err_string);
		return (ERROR);
	} else {
		entry->memclk = mclk;
	}
	if (system_type != SERRANO && mclk != 133) {
		print_error("memc_entry.mspd must be 133 only !");
		return (ERROR);
	}
	if (mcr[0] & ((unsigned long long) MCR0_CTL_MASK)) {
		sprintf(err_string, "memc_entry id %d: "
			"MCR0 control bits not zero. "
			"Should be %llx\n", entry_id,
			mcr[0] & (-1 ^ ((unsigned long long) MCR0_CTL_MASK)));
		print_error(err_string);
		return (ERROR);
	}
	for (i = 0; i < 3; i++) {
		entry->mcr[i] = mcr[i];
	}
	entry->next = NULL;
	return (NO_ERROR);
}

/*
 * Get ecache_ctrl_reg parameters of format:
 * ecache_ctrl_reg   cpu_max(Mhz)     cpu_min(Mhz) ecache_ctrl_reg_default
 */
static unsigned int
get_ecache_input(char *line, struct ecache_entry *entry)
{
	char parameter[MAXNAMESIZE];
	unsigned short cpu_max, cpu_min;
	unsigned long long ecache[2];
	int entries;

	ecache[0] = 0;
	ecache[1] = 0;
	entries = sscanf(line, "%32s %hd %hd %llx %llx",
	    parameter, &cpu_max, &cpu_min, &ecache[0], &ecache[1]);
	if ((entries < 4) || (entries > 5)) {
		print_error("ecache_ctrl.reg line incorrectly defined");
		return (0);
	}
	if (cpu_max < cpu_min) {
		print_error("ecache_ctrl.reg.cpu_max must be greater"
		    "than cpu_min!");
		return (0);
	}
	entry->cpu_max = cpu_max;
	entry->cpu_min = cpu_min;
	entry->ecache_cfg[0] = ecache[0];
	if (entries == 5) entry->ecache_cfg[1] = ecache[1];
	entry->next = NULL;
	return (1);
}

/*
 * Add fiesta_memc_entry to data structure
 */
static void
update_fiesta_memc(struct fiesta_memc_entry *entry)
{
	struct fiesta_memc_entry *ptr;
	unsigned long long temp;

	ptr = fiesta_memc;
	if (ptr == NULL) {
		fiesta_memc = malloc(sizeof (struct fiesta_memc_entry));
		*fiesta_memc = *entry;
	} else {
		while (ptr->next != NULL)
			ptr = ptr->next;
		ptr->next = malloc(sizeof (struct fiesta_memc_entry));
		*ptr->next = *entry;
	}
	temp = get_seeprom("num_memc_cfgs");
	update_seeprom("num_memc_cfgs", temp+1);
}

/*
 * Add ecache_ctrl_reg entry to data structure
 */
static void
update_ecache_table(struct ecache_entry *entry)
{
	struct ecache_entry *ptr;
	unsigned long long temp;

	ptr = cpu_ecache_table;
	if (ptr == NULL) {
		cpu_ecache_table = malloc(sizeof (struct ecache_entry));
		*cpu_ecache_table = *entry;
	} else {
		while (ptr->next != NULL)
			ptr = ptr->next;
		ptr->next = malloc(sizeof (struct ecache_entry));
		*ptr->next = *entry;
	}
	temp = get_seeprom("num_ecache_cfgs");
	update_seeprom("num_ecache_cfgs", temp+1);
}

/*
 * Remove duplicate speed entries and sort from lowest to highest
 */
static int
sort_speed(unsigned short *speed_list, int num_speeds)
{
	unsigned short sort_list[MAXSPEEDLIST];
	int i, j, done;
	unsigned short lowest;

	if (num_speeds == 1) {
		if (speed_list[0] > MAX_SAFARI_SPEED) {
			sprintf(err_string,
			    "cpu_sys_ratio.safari_speed must be <= %dMhz!",
			    MAX_SAFARI_SPEED);
			print_error(err_string);
			return (-1);
		} else
			return (1);
	}

	i = done = 0;
	while (!done) {
		done = 1;
		lowest = MAX_SAFARI_SPEED;
		for (j = 0; j < num_speeds; j++) {
			if (speed_list[j] != 0) {
				if (speed_list[j] > MAX_SAFARI_SPEED) {
					sprintf(err_string,
					    "cpu_sys_ratio.safari_speed "
					    "must be <= %dMhz!",
					    MAX_SAFARI_SPEED);
					print_error(err_string);
					return (-1);
				} else {
					lowest = (lowest <= speed_list[j]) ?
					    lowest : speed_list[j];
					done = 0;
				}
			}
		}
		if (!done) {
			sort_list[i++] = lowest;
			for (j = 0; j < num_speeds; j++) {
				if (speed_list[j] == lowest) {
					speed_list[j] = 0;
				}
			}
		}
	}
	for (j = 0; j < i; j++)
		speed_list[j] = sort_list[j];
	return (i);
}

/*
 * Update data structure with new speed entry
 */
static void
update_speeds(unsigned short *speeds, unsigned short ratio, int num_speeds)
{
	struct speed_entry *ptr, *prev, *temp_ptr;
	unsigned long long cpu_ratios;

	int i;

	/*
	 * if we already have entries for this ratio, delete them
	 */
	if (get_seeprom("cpu_ratios") & (1 << (ratio - cpu_ratios_min))) {
		ptr = prev = speed_table;
		while (ptr->ratio != ratio) {
			prev = ptr;
			ptr = ptr->next;
		}
		while ((ptr != NULL) && (ptr->ratio == ratio)) {
			temp_ptr = ptr;
			ptr = ptr->next;
			free(temp_ptr);
		}
		if (prev == speed_table)
			speed_table = ptr;
		else
			prev->next = ptr;
	}

	/*
	 * add speeds for this ratio to the list
	 */

	for (i = 0; i < num_speeds; i++) {
		temp_ptr = malloc(sizeof (struct speed_entry));
		temp_ptr->ratio = ratio;
		temp_ptr->speed_hi = temp_ptr->speed_lo = speeds[i];
		temp_ptr->next = NULL;
		if (speed_table == NULL) {
			speed_table = temp_ptr;
		} else {
			ptr = speed_table;
			while (ptr->next != NULL) {
				ptr = ptr->next;
			}
			ptr->next = temp_ptr;
		}
	}
	cpu_ratios = get_seeprom("cpu_ratios");
	cpu_ratios |= (1 << (ratio - cpu_ratios_min));
	update_seeprom("cpu_ratios", cpu_ratios);
}

/*
Get cpu_sys_ratio parameters of format:
cpu_sys_ratio	cpu/sys_ratio   Valid_Safari_speed(Mhz)

Multiple valid Safari speeds may be separated by commas.
*/
static unsigned int
get_speed_input(char *line, unsigned short *speeds,
    unsigned short *ratio, int *num_speeds)
{
	char parameter[MAXNAMESIZE], speedinfo[MAXLINE];
	char *temp;
	int i;

	if (sscanf(line, "%32s %hd %s", parameter, ratio, speedinfo) == 3) {
		if ((*ratio > speed_ratio_max) || (*ratio < speed_ratio_min)) {
			sprintf(err_string, "Invalid cpu_sys_ratio: %d",
			    *ratio);
			print_error(err_string);
			return (0);
		}
		temp = strtok(speedinfo, ",");
		i = 0;
		while (temp != NULL) {
			if (sscanf(temp, "%hd", &speeds[i++])) {
				temp = strtok(NULL, ",");
			} else {
				sprintf(err_string,
				    "Invalid cpu_sys_ratio.safari_speed: %s",
				    temp);
				print_error(err_string);
				return (0);
			}
		}
		*num_speeds = sort_speed(speeds, i);
		if (*num_speeds == -1)
			return (0);
		else
			return (1);
	}
	return (0);
}

/*
Calculate speed table width
*/
static unsigned long long
speed_table_width(void)
{
	struct speed_entry *ptr;
	unsigned short count, biggest;

	ptr = speed_table;
	biggest = count = 1;
	while (ptr->next != NULL) {
		if (ptr->ratio == ptr->next->ratio) {
			count++;
			if (count > biggest) biggest = count;
		} else {
			count = 1;
		}
		ptr = ptr->next;
	}
	return (biggest);
}

int
cpu_dynamic(char *parameter, char *line)
{
	if (strcmp(parameter, "ecache_ctrl_reg") == 0) {
		if (system_type != GMFIESTA) {
			struct ecache_entry new_ecache_entry;
			if (get_ecache_input(line, &new_ecache_entry))
				update_ecache_table(&new_ecache_entry);
			else
				return (ERROR);
		}
	} else if (strcmp(parameter, "cpu_sys_ratio") == 0) {
		unsigned short speed_list[MAXSPEEDLIST];
		unsigned short ratio;
		int num_speeds;
		switch (system_type) {
			case FIESTA:
			case GMFIESTA:
				speed_ratio_max = 10;
				speed_ratio_min = 6;
				cpu_ratios_min = 3;
				cpu_ratios_bits = 8;
				break;
			case SERRANO:
				speed_ratio_max = 16;
				speed_ratio_min = 6;
				cpu_ratios_min = 6;
				cpu_ratios_bits = 16;
				break;
			default:
				speed_ratio_max = 10;
				speed_ratio_min = 4;
				cpu_ratios_min = 3;
				cpu_ratios_bits = 8;
				break;
		}
		if (get_speed_input(line, speed_list, &ratio, &num_speeds))
			update_speeds(speed_list, ratio, num_speeds);
		else
			return (ERROR);
	} else if (strcmp(parameter, "memc_entry") == 0) {
		switch (system_type) {
			struct fiesta_memc_entry new_memc_entry;
			case FIESTA:
			case GMFIESTA:
			case SERRANO:
				if (!fiesta_memc_input(line, &new_memc_entry))
					update_fiesta_memc(&new_memc_entry);
				else
				return (ERROR);
			default:
				break;
		}
	} else {
		return (UNKNOWN);
	}
	return (NO_ERROR);
}

static void
free_cpu(void)
{
	struct ecache_entry *ecache, *tmp1;
	struct speed_entry *speed, *tmp2;
	struct fiesta_memc_entry *memc, *tmp3;

	if (cpu_ecache_table != NULL) {
		ecache = cpu_ecache_table;
		while (ecache->next != NULL) {
			tmp1 = ecache->next;
			free(ecache);
			ecache = tmp1;
		}
		free(ecache);
	}

	if (speed_table != NULL) {
		speed = speed_table;
		while (speed->next != NULL) {
			tmp2 = speed->next;
			free(speed);
			speed = tmp2;
		}
		free(speed);
	}

	if (fiesta_memc != NULL) {
		memc = fiesta_memc;
		while (memc->next != NULL) {
			tmp3 = memc->next;
			free(memc);
			memc = tmp3;
		}
		free(memc);
	}
}

void
write_cpu(unsigned char **ptr)
{
	struct ecache_entry *ecache;
	struct speed_entry *speed;
	struct fiesta_memc_entry *memc;
	unsigned short ratio;
	int i;

	ecache = cpu_ecache_table;
	while (ecache != NULL) {
		store_bytes(2, (unsigned long long) ecache->cpu_max, ptr);
		store_bytes(2, (unsigned long long) ecache->cpu_min, ptr);
		store_bytes(8, ecache->ecache_cfg[0], ptr);
		if (format_mode == 2 || format_mode == 3) {
			store_bytes(8, ecache->ecache_cfg[1], ptr);
		}
		ecache = ecache->next;
	}

	if (fixed_parameter("speed_table_width")) {
		int width = (int)get_seeprom("speed_table_width");
		int found = 0;

		for (i = 0; i < cpu_ratios_bits; i++, found = 0) {
			if (get_seeprom("cpu_ratios") & (1 << i)) {
				ratio = i+ cpu_ratios_min;
				speed = speed_table;
				/*
				 * Stay at this ratio until all found and
				 * stored.
				 */
				while (speed != NULL) {
					if (speed->ratio == ratio) {
						store_bytes(1, speed->speed_hi,
							ptr);
						store_bytes(1, speed->speed_lo,
							ptr);
						speed->ratio = 0;
						found++;
					}
					speed = speed->next;
				}
				while (found++ < width) {
					store_bytes(2, 0, ptr);
				}
			}
		}
	}
	memc = fiesta_memc;
	while (memc != NULL) {
		store_bytes(2, (unsigned long long) memc->bus_hi, ptr);
		store_bytes(2, (unsigned long long) memc->bus_lo, ptr);
		store_bytes(1, (unsigned long long) memc->entry_id, ptr);
		store_bytes(1, (unsigned long long) memc->ratio, ptr);
		store_bytes(2, (unsigned long long) memc->memclk, ptr);
		for (i = 0; i < 3; i++)
			store_bytes(8, memc->mcr[i], ptr);
		memc = memc->next;
	}
	free_cpu();
}

void
dump_cpu(void)
{
	struct ecache_entry *ecache;
	struct speed_entry *speed;
	struct fiesta_memc_entry *memc;

	ecache = cpu_ecache_table;
	if (ecache != NULL)
		printf("ecache_ctrl_reg:  "
		    "cpu_max         cpu_min         ecache_cfg\n");
	while (ecache != NULL) {
		printf("                  %hd"
		    "			%hd             0x%llx",
		    ecache->cpu_max, ecache->cpu_min, ecache->ecache_cfg[0]);
		if (format_mode == 2 || format_mode == 3)
			printf(" 0x%llx", ecache->ecache_cfg[1]);
		printf("\n");
		ecache = ecache->next;
	}

	speed = speed_table;
	if (speed != NULL)
		printf("cpu_sys_ratio:            ratio   speed\n");
	while (speed != NULL) {
		printf("    		              %hd     %hd\n",
		    speed->ratio, speed->speed_hi);
		speed = speed->next;
	}

	memc = fiesta_memc;
	if (memc != NULL)  {
		printf("memc_entries:\n");
		printf("hi    lo   id  ratio  memclk");
		printf("    mcr1               mcr2               mcr3\n");
		while (memc != NULL) {
			printf("%-4hd  %-4hd  %-1hd    %-1hd      %-4hd",
				memc->bus_hi, memc->bus_lo, memc->entry_id,
				memc->ratio, memc->memclk);
			printf("	0x%016llx 0x%016llx 0x%016llx\n",
				memc->mcr[0], memc->mcr[1], memc->mcr[2]);
			memc = memc->next;
		}
	}
}

int
match_ecache_cfg(unsigned short speed)
{
	struct ecache_entry *ecache;

	ecache = cpu_ecache_table;
	while (ecache != NULL) {
		if ((speed >= ecache->cpu_min) && (speed <= ecache->cpu_max)) {
			return (1);
		}
		ecache = ecache->next;
	}
	sprintf(err_string, "No ecache cfg entry for cpu speed %d", speed);
	print_error(err_string);
	return (0);
}

static int
ecache_fmt(unsigned long long e_size, int format)
{
	struct ecache_entry *ecache;
	unsigned int ecache_code;
	int error = NO_ERROR;
	int size_pos = 0;

	switch (system_type) {
	case EXCALIBUR:
		switch (format) {
		case	1:
		case	2:
		case	3:
			switch (e_size) {
			case	0x100000:
			case	0x400000:
			case	0x800000:
				size_pos = 13;
				ecache_code = e_size / 0x400000;
				ecache_code <<= size_pos;
				break;
			default:
				error = ERROR;
				break;
			}
			break;
		default:
			error = ERROR;
			break;
		}
		break;
	default:
		error = ERROR;
		break;
	}

	if (error == NO_ERROR) {
		ecache = cpu_ecache_table;
		while (ecache != NULL) {
			int cfg = ecache->ecache_cfg[0] &
				    (3 << size_pos);
			if (cfg != ecache_code) {
				fprintf(stderr,
					"WARNING: Changing "
					"ecache_cfg.EC_SIZE "
					"to match ecache_size!\n");
			}
			ecache->ecache_cfg[0] &= (-1^(3 << size_pos));
			ecache->ecache_cfg[0] |= ecache_code;
			ecache = ecache->next;
		}
	} else {
		printf("Invalid id_format or ecache size!\n");
	}
	return (error);
}

int
match_memc_cfg(unsigned short speed, unsigned short ratio)
{
	struct fiesta_memc_entry *memc_table;

	memc_table = fiesta_memc;
	while (memc_table != NULL) {
		if ((memc_table->bus_hi == speed) &&
			(memc_table->ratio == ratio)) {
			return (1);
		}
		memc_table = memc_table->next;
	}
	sprintf(err_string, "No memc cfg entry for ratio %d sys speed %d",
		ratio, speed);
	print_error(err_string);
	return (0);
}

int
check_cpu(void)
{
	int error = 0;
	struct speed_entry *speed_ptr;
	unsigned long long temp;

	if (type == CPU) {
		if (speed_table == NULL) {
			print_error("Must specify a cpu_sys_ratio entry!");
			error = ERROR;
		} else {
			update_seeprom("speed_table_width",
					speed_table_width());
			speed_ptr = speed_table;
			while (speed_ptr != NULL) {
				if (system_type != GMFIESTA &&
				    !match_ecache_cfg(speed_ptr->speed_hi*
						    speed_ptr->ratio))
					error = ERROR;
				if (system_type == FIESTA ||
				    system_type == GMFIESTA ||
				    system_type == SERRANO)
					if (!match_memc_cfg(speed_ptr->speed_hi,
						speed_ptr->ratio))
						error = ERROR;
				speed_ptr = speed_ptr->next;
			}
		}
	}
	if (type == CPU_RW &&
	    (system_type == FIESTA || system_type == GMFIESTA ||
						system_type == SERRANO)) {
		if (format_mode != 1) {
			print_error("Invalid id_format!");
			error = ERROR;
		}
	}
	if (fiesta_memc == NULL &&
	    (system_type == FIESTA || system_type == GMFIESTA ||
						system_type == SERRANO)) {
		print_error("Must specify a memc entry!");
		error = ERROR;
	}

	if (fixed_parameter("ecache_size") && (system_type == EXCALIBUR)) {
		if (ecache_fmt(get_seeprom("ecache_size"), format_mode))
			error = ERROR;
	}
	if ((type == CPU) && (id_magic != CPU_DEFAULT_MAGIC)) {
		if (!clk_div_set) {
			print_error("Must specify clk_divisor!");
			error = ERROR;
		}
	}
	return (error);
}

int
reg_cpu(char *s1, data_reg **reg)
{
	int count = 0;
	if (strcmp(s1, "lsucr") == 0) {
		*reg = &lsucr[0];
		count = sizeof (lsucr) / sizeof (data_reg);
	} else if (strcmp(s1, "dcr") == 0) {
		*reg = &dcr[0];
		count = sizeof (dcr) / sizeof (data_reg);
	}
	return (count);
} 
