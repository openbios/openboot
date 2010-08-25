/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: env-seeprom.c
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
 * id: @(#)env-seeprom.c 1.3 03/06/11
 * purpose: 
 * copyright: Copyright 2000-2003 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "gen-seeprom.h"
#include "prototypes.h"
#include "env-seeprom.h"

int processing_env = 0, processing_fan = 0;
int running_offset = VER_SIZE;
struct env_table_entry *env_table = NULL;
struct env_table_entry *cur_env_table;
struct fan_table_entry *fan_table = NULL;
struct fan_table_entry *cur_fan_table;
struct id_header_data id_header;
int current_correction = 0, current_fan_pair = 0;
int num_corrections = 0, num_fan_ctl_pairs = 0;
int id_num = 0, fan_id_num = 0, env_version = 0;

void
set_env_ver(void *data)
{
	env_version = (int)data;
}

/*
 * allocate memory for the id-offset block
 */

void
set_num_sensors(void *data)
{
	id_header.num_sensors = (int)data;
	running_offset += NUM_SEN_SIZE +
		(id_header.num_sensors * SENSOR_BLOCK_SIZE);
	id_header.id_block = malloc(id_header.num_sensors * SENSOR_BLOCK_SIZE);
}


/*
 * "version" , "num-sensors" , "num-fans" will only show up once in a properly
 * configured environmental segment
 */

struct fixed_seeprom env_seeprom_data[] = {
	/*  name		size	type	value */
	{ "version",		VER_SIZE,	NUM,	0,  set_env_ver},
	{ "num-sensors",	NUM_SEN_SIZE,	NUM,	0,  set_num_sensors},
	{ NULL, 0, 0, 0, NULL},
};


int
not_byte_range(int value)
{
	return (value > 255 || value < 0);
}

int
not_sbyte_range(int value)
{
	return (value > 127 || value < -128);
}

correction_scan(char *line, unsigned int *input_val)
{
	char temp[MAXNAMESIZE];
	char input_one[MAXNAMESIZE];
	char input_two[MAXNAMESIZE];
	unsigned int temp_val;
	int retval = NO_ERROR;

	if (sscanf(line, "%s %s %s", temp, input_one, input_two) != 3) {
		retval = ERROR;
	}

	strip_val(input_one, input_val);
	strip_val(input_two, &temp_val);

	if (not_sbyte_range(*input_val) || not_sbyte_range(temp_val))
		retval = ERROR;

	*input_val = (*input_val & 0xff) << 8;
	*input_val += (temp_val & 0xff);

	if (retval == ERROR) {
		printf("Correction table entries must be entered as a ");
		printf("pair of signed bytes\n");
	}
	return (retval);
}

fan_min_range_scan(char *line, unsigned int *input_val)
{
	char temp[MAXNAMESIZE];
	char input_one[MAXNAMESIZE];
	char input_two[MAXNAMESIZE];
	unsigned int temp_val;
	int retval = NO_ERROR;

	if (sscanf(line, "%s %s %s", temp, input_one, input_two) != 3) {
		retval = ERROR;
	}

	strip_val(input_one, input_val);
	strip_val(input_two, &temp_val);

	if (not_sbyte_range(*input_val) || not_byte_range(temp_val))
		retval = ERROR;

	*input_val = (*input_val & 0xff) << 8;
	*input_val += (temp_val & 0xff);

	if (retval == ERROR) {
		printf("Fan min/range table entries must be entered as a ");
		printf("signed, unsigned byte pair.\n");
	}
	return (retval);
}

int
update_env_table(char *parameter, char *line)
{
	int i = 0, offset = 0;
	unsigned int input_val;
	int size;
	unsigned char *data_ptr;

	while (strcmp(env_parameters[i].name, parameter)) {
		offset += env_parameters[i++].size;
		if (env_parameters[i].name == NULL) {
			fprintf(stderr,
			    "%s is not a valid env parameter\n", parameter);
			return (ERROR);
		}
	}
	size = env_parameters[i].size;
	data_ptr = cur_env_table->env_data;

	if (strcmp(parameter, "correction") == 0) {
		offset = COR_SIZE * current_correction;
		current_correction++;
		size = COR_SIZE;
		data_ptr = cur_env_table->correction_data;
		if ((correction_scan(line, &input_val) == ERROR))
			return (ERROR);
	} else if ((scan_line(line, &input_val) == ERROR))
		return (ERROR);


	if (strcmp(parameter, "num-corrections") == 0) {
		num_corrections = input_val;
		cur_env_table->correction_data =
		    (unsigned char *) malloc(COR_SIZE * num_corrections);
		cur_env_table->correction_size = num_corrections * COR_SIZE;
	}

	write_bytes(input_val, size, offset, data_ptr);

	return (NO_ERROR);
}

int
update_fan_table(char *parameter, char *line)
{
	int i = 0, offset = 0;
	unsigned int input_val;
	int size;
	unsigned char *data_ptr;

	while (strcmp(fan_parameters[i].name, parameter)) {
		offset += fan_parameters[i++].size;
		if (fan_parameters[i].name == NULL) {
			fprintf(stderr,
				"%s is not a valid fan parameter\n", parameter);
			return (ERROR);
		}
	}
	size = fan_parameters[i].size;
	data_ptr = cur_fan_table->fan_data;

	if (strcmp(parameter, "fan-min-range") == 0) {
		offset = FAN_MIN_RANGE_SZ * current_fan_pair;
		current_fan_pair++;
		data_ptr = cur_fan_table->fan_ctl_data;
		if ((fan_min_range_scan(line, &input_val) == ERROR))
			return (ERROR);
	} else if ((scan_line(line, &input_val) == ERROR))
		return (ERROR);


	if (strcmp(parameter, "num-ctl-pairs") == 0) {
		num_fan_ctl_pairs = input_val;
		cur_fan_table->fan_ctl_data =
			(unsigned char *) malloc(FAN_MIN_RANGE_SZ *
			num_fan_ctl_pairs);
		cur_fan_table->fan_pair_size = num_fan_ctl_pairs *
			FAN_MIN_RANGE_SZ;
	}

	write_bytes(input_val, size, offset, data_ptr);

	return (NO_ERROR);
}

int
set_num_fans(char *line)
{
	unsigned int input_val;

	if (id_header.num_fans == 0) {
		if (scan_line(line, &input_val) == ERROR)
			return (ERROR);
		id_header.num_fans = input_val;
		running_offset += NUM_FAN_SIZE +
			(id_header.num_fans * FAN_BLOCK_SIZE);
		id_header.fan_block = malloc(id_header.num_fans *
			FAN_BLOCK_SIZE);
		return (NO_ERROR);
	} else {
		printf("ERROR: Already initialized num_fans\n");
		return (ERROR);
	}
}

/*
 * fill the id-offset block with id numbers and their respective data
 * offsets as they are presented in the cfg file.
 */

int
parse_id(char *line)
{
	unsigned int input_val, offset, i;

	offset = id_num * SENSOR_BLOCK_SIZE;
	id_num++;
	if (scan_line(line, &input_val) == ERROR)
		return (ERROR);

	for (i = 0; i < id_num-1; i++) {
	if (!memcmp(&input_val, &id_header.id_block[i*SENSOR_BLOCK_SIZE],
	    ID_SIZE)) {
			printf("ERROR: Two sensors with id = %x\n", input_val);
			return (ERROR);
		}
	}
	write_bytes(input_val, ID_SIZE, offset, id_header.id_block);
	offset += ID_SIZE;
	write_bytes(running_offset, OFFSET_SIZE, offset, id_header.id_block);

	return (NO_ERROR);
}

int
parse_fan_id(char *line)
{
	unsigned int input_val, offset, i;

	offset = fan_id_num * FAN_BLOCK_SIZE;
	fan_id_num++;
	if (scan_line(line, &input_val) == ERROR)
		return (ERROR);
	for (i = 0; i < fan_id_num-1; i++) {
		if (!memcmp(&input_val, &id_header.fan_block[i*FAN_BLOCK_SIZE],
			FAN_ID_SIZE)) {
			printf("ERROR: Two fans with id = %x\n", input_val);
			return (ERROR);
		}
	}
	write_bytes(input_val, FAN_ID_SIZE, offset, id_header.fan_block);
	offset += FAN_ID_SIZE;
	write_bytes(running_offset, FAN_OFF_SIZE, offset, id_header.fan_block);

	return (NO_ERROR);
}

/*
 * The sensor data blocks are marked by sensor-data-start and sensor-data-end
 * tokens.  sensor data blocks should only be presented between these two tokens
 */

int
env_dynamic(char *parameter, char *line)
{
	int retval = NO_ERROR;

	if (strcmp(parameter, "sensor-data-start") == 0) {
		if (processing_fan) {
			printf("ERROR, fan data cannot contain");
			printf(" sensor-data-start\n");
			return (ERROR);
		}
		if (!processing_env) {
			if (env_table == NULL) {
				env_table = malloc(
				sizeof (struct env_table_entry));
				cur_env_table = env_table;
				cur_env_table->next = NULL;
			} else {
				cur_env_table->next = malloc(
				sizeof (struct env_table_entry));
				cur_env_table = cur_env_table->next;
				cur_env_table->next = NULL;
			}
			processing_env = 1;
		} else {
			printf("ERROR, consecutive sensor-data-start tokens");
			printf(" without sensor-data-end\n");
			retval = ERROR;
		}
	} else if (strcmp(parameter, "sensor-data-end") == 0) {
		if (processing_fan) {
			printf("ERROR, fan data cannot contain");
			printf(" sensor-data-end\n");
			return (ERROR);
		}
		if (!processing_env) {
			fprintf(stderr, "Missing env_table_start\n");
			retval = ERROR;
		} else {
			if (current_correction != num_corrections) {
				printf("ERROR, missing correction entries\n");
				retval = ERROR;
			}
			running_offset += ENV_ENTRY_SIZE +
				(num_corrections * COR_SIZE);
			processing_env = 0;
			num_corrections = 0;
			current_correction = 0;
		}
	} else if (strcmp(parameter, "id") == 0) {
		if (processing_env) {
			retval = parse_id(line);
		} else {
			retval = UNKNOWN;
		}
	} else if (strcmp(parameter, "fan-data-start") == 0) {
		if (processing_env) {
			printf("ERROR, sensor data cannot contain");
			printf(" fan-data-start\n");
			return (ERROR);
		}
		if (!processing_fan) {
			if (fan_table == NULL) {
				fan_table = malloc(
				sizeof (struct fan_table_entry));
				memset(fan_table, 0,
					sizeof (struct fan_table_entry));
				cur_fan_table = fan_table;
				cur_fan_table->next = NULL;
			} else {
				cur_fan_table->next = malloc(
				sizeof (struct fan_table_entry));
				memset(cur_fan_table->next, 0,
					sizeof (struct fan_table_entry));
				cur_fan_table = cur_fan_table->next;
				cur_fan_table->next = NULL;
			}
			processing_fan = 1;
		} else {
			printf("ERROR, consecutive fan-data-start tokens");
			printf(" without fan-data-end\n");
			retval = ERROR;
		}
	} else if (strcmp(parameter, "fan-data-end") == 0) {
		if (processing_env) {
			printf("ERROR, sensor data cannot contain");
			printf(" fan-data-end\n");
			return (ERROR);
		}
		if (!processing_fan) {
			fprintf(stderr, "Missing fan_table_start\n");
			retval = ERROR;
		} else {
			if (current_fan_pair != num_fan_ctl_pairs) {
				printf("ERROR, missing fan-min-range");
				printf(" entries\n");
				retval = ERROR;
			}
			running_offset += ENV_FAN_ENTRY_SIZE +
				(num_fan_ctl_pairs * FAN_MIN_RANGE_SZ);
			processing_fan = 0;
			num_fan_ctl_pairs = 0;
			current_fan_pair = 0;
		}
	} else if (strcmp(parameter, "fan-id") == 0) {
		if (processing_fan) {
			retval = parse_fan_id(line);
		} else {
			retval = UNKNOWN;
		}
	} else if (strcmp(parameter, "num-fans") == 0) {
		if (env_version == 2) {
			set_num_fans(line);
		} else {
			printf("ERROR, num_fans is not a valid parameter");
			printf(" for this version of the cfg file\n");
			retval = ERROR;
		}
	} else {
		if (processing_env) {
			retval = update_env_table(parameter, line);
		} else if (processing_fan) {
			retval = update_fan_table(parameter, line);
		} else {
			retval = UNKNOWN;
		}
	}
	return (retval);
}

/*
 * the number of sensor ids must match the number-sensors token value
 */

int
check_env()
{
	int retval = NO_ERROR;
	if (id_num != id_header.num_sensors) {
		printf("ERROR, number of id fields does not match number ");
		printf("of sensors\n");
		retval = ERROR;
	}
	if (fan_id_num != id_header.num_fans) {
		printf("ERROR, number of fan_id fields does not match number ");
		printf("of fans\n");
		retval = ERROR;
	}
	return (retval);
}

int
reg_env(char *s1, data_reg **reg)
{
	return (NO_ERROR);
}

/*
 * version and num-sensors have already been added by the gen-seeprom tool.
 * First add the id-offset table, and then the sensor table data
 */

void
write_env(unsigned char **ptr)
{
	struct env_table_entry *table_ptr;
	struct fan_table_entry *fan_table_ptr;

	store_chars((id_header.num_sensors * SENSOR_BLOCK_SIZE),
	    id_header.id_block, ptr);
	if (env_version > 1) {
		store_bytes(NUM_FAN_SIZE,
			(unsigned long long) id_header.num_fans, ptr);
		store_chars((id_header.num_fans * FAN_BLOCK_SIZE),
		id_header.fan_block, ptr);
	}


	table_ptr = env_table;
	while (table_ptr != NULL) {
		store_chars(ENV_ENTRY_SIZE, table_ptr->env_data, ptr);
		store_chars(table_ptr->correction_size,
		    table_ptr->correction_data, ptr);
		table_ptr = table_ptr->next;
	}

	fan_table_ptr = fan_table;
	while (fan_table_ptr != NULL) {
		store_chars(ENV_FAN_ENTRY_SIZE, fan_table_ptr->fan_data, ptr);
		store_chars(fan_table_ptr->fan_pair_size,
			fan_table_ptr->fan_ctl_data, ptr);
		fan_table_ptr = fan_table_ptr->next;
	}

}

void
dump_env()
{
}
