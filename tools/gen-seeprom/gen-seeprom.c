/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: gen-seeprom.c
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
 * id: @(#)gen-seeprom.c 1.12 05/11/15
 * purpose:
 * copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

/*
 * Parse a config file and generate a binary file containing the cpu seeprom
 * image.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <time.h>
#include "gen-seeprom.h"
#include "prototypes.h"

#define	MAX_IMAGE 0x800

int system_type = EXCALIBUR;
int system_type_init = 0;
int config_type_init = 0;
struct fixed_seeprom *seeprom_data;
char *config_file;
char err_string[MAXLINE];
int type = CPU;
int do_checksum = 0;
static int quiet = 0, release = 0;
int force_debug = 0;

static struct unique_functions seeprom_func[] = {
	SET_FUNC_ENTRY(cpu_dynamic, check_cpu, write_cpu, dump_cpu, reg_cpu)
	SET_FUNC_ENTRY(sys_dynamic, check_sys, write_sys, dump_sys, reg_sys)
	SET_FUNC_ENTRY(env_dynamic, check_env, write_env, dump_env, reg_env)
	SET_FUNC_ENTRY(mem_dynamic, check_mem, write_mem, dump_mem, reg_mem)
	SET_FUNC_ENTRY(cpu_dynamic, check_cpu, write_cpu, dump_cpu, reg_cpu)
};

static void
usage(char *name)
{
	static struct tm tm_compiled = { COMPILE_TIME };
	time_t compiled, expire;
	compiled = mktime(&tm_compiled);
	expire = compiled + ACTIVE_TIME;

	/* -q option is quiet mode, no processing messages. */
	fprintf(stderr,
	    "%s: [ -q ] <config_filename>\n", name);
	fprintf(stderr, "   -q Suppresses config file processing messages.\n");

	fprintf(stderr, "\nTool will expire on %s\n", ctime(&expire));

	exit(1);
}

static int
usage_expired(void)
{
	int status = 0;

	static struct tm tm_compiled = { COMPILE_TIME };
	time_t compiled, now, expire;

	compiled = mktime(&tm_compiled);
	expire = compiled + ACTIVE_TIME;
	now = time(NULL);
	now = mktime(gmtime(&now));
	status = (now > expire);
	return (status);
}

void
print_error(char *string)
{
	fprintf(stderr, "%s: ERROR: %s\n", config_file, string);
}

static void
print_input_error(char *parameter)
{
	sprintf(err_string, "Input error for %s", parameter);
	print_error(err_string);
}

/*
 * Get seeprom parameter value from data structure
 */
unsigned long long
get_seeprom(char *name)
{
	int i = 0;
	char *parameter;

	while ((parameter = seeprom_data[i].name) != NULL) {
		if (strcmp(parameter, name) == 0) {
			return (seeprom_data[i].value);
		}
		i++;
	}
	sprintf(err_string, "Cannot find value of %s", name);
	print_error(err_string);
	return (0);
}

static int
update_reg(data_reg *cpu_reg, char *name, unsigned long long new,
    unsigned long long *reg, int num_entries)
{
	int i, found;
	unsigned long long data;

	i = found = 0;

	while (!found && (i < num_entries)) {
		if (strcmp(cpu_reg[i].name, name) == 0) {
			int bits, mask;
			bits = cpu_reg[i].size-1;
			mask = 1;
			while (bits) {
				mask |= (1 << bits);
				bits--;
			}
			data = *reg &
			    (0xffffffffffffffffLL ^ (mask << cpu_reg[i].pos));
			data |= ((new & mask) << cpu_reg[i].pos);
			*reg = data;
			found = 1;
		}
		i++;
	}
	return (!found);
}

/*
 * Set seeprom parameter value in data structure
 */
int
update_seeprom(char *name, unsigned long long value)
{
	int i = 0, retval = 0;
	char *s1, *s2;
	char parameter[MAXNAMESIZE];
	void (*notify)(void *data);

	strcpy(parameter, name);
	if ((s1 = strtok(parameter, ".")) != NULL) {
		while ((seeprom_data[i].name) != NULL) {
			if (strcmp(seeprom_data[i].name, s1) == 0) {
				s2 = strtok(NULL, ".");
				notify = seeprom_data[i].notify;
				if (s2 == NULL) {
					seeprom_data[i].value = value;
				} else {
					int (*funcp)(), num_entries;
					data_reg *cpu_reg;
					funcp = seeprom_func[type].reg_func;
					num_entries = funcp(s1, &cpu_reg);
					if (num_entries) {
						retval = update_reg(cpu_reg,
						    s2, value,
						    &seeprom_data[i].value,
						    num_entries);
					} else {
						retval = 1;
					}
				}
				if (notify != NULL) notify((void *) value);
				return (retval);
			}
			i++;
		}
	}
	return (1);
}

/*
 * Get one parameter value from config file
 */
static unsigned int
get_one_input(int num_input, char *input_str, unsigned long long *input_val)
{
	unsigned int retval;

	retval = 0;
	if (--num_input) {
		if ((strncmp(input_str, "0x", 2) == 0) ||
		    (strncmp(input_str, "0X", 2) == 0)) {
			input_str += 2;
			retval = sscanf(input_str, "%llx", input_val);
		} else {
			retval = sscanf(input_str, "%d", input_val);
			*input_val >>= 32;
		}
	}
	return (retval);
}

/*
 * Check if parameter is from the fixed region
 */
int
fixed_parameter(char *name)
{
	int i = 0;
	char *c, parameter[MAXNAMESIZE];

	strcpy(parameter, name);
	if ((c = strtok(parameter, ".")) != NULL) {
		while (seeprom_data[i].name != NULL) {
			if (strcmp(seeprom_data[i++].name, c) == 0) {
				return (1);
			}
		}
	}
	return (0);
}

/*
 * Parse parameters
 */
static int
process_line(char *line)
{
	char parameter[MAXNAMESIZE];
	char input_str[MAXNAMESIZE];

	int num_scanned, error;

	error = 0;
	num_scanned = sscanf(line, "%32s %32s", parameter, input_str);
#if 0
	if (num_scanned != 2) {
		fprintf(stderr,
		    "WARNING: Ignoring following line:\n%s\n",
		    line);
		return (0);
	}
#endif
	if (strcmp(parameter, "cfg_type") == 0) {
		if (!config_type_init) {
			if (strcmp(input_str, "cpu") == 0) {
				type = CPU;
				seeprom_data = &cpu_seeprom_data[0];
			} else if (strcmp(input_str, "sys") == 0) {
				type = SYS;
				seeprom_data = &sys_seeprom_data[0];
			} else if (strcmp(input_str, "env") == 0) {
				type = ENV;
				seeprom_data = &env_seeprom_data[0];
			} else if (strcmp(input_str, "mem") == 0) {
				type = MEM;
				seeprom_data = &mem_seeprom_data[0];
			} else if (strcmp(input_str, "cpu_rw") == 0) {
				type = CPU_RW;
				seeprom_data = &cpu_rw_data[0];
			} else {
				fprintf(stderr, " invalid config type: %s\n",
					input_str);
				error = 1;
			}
			config_type_init = 1;
		} else {
			fprintf(stderr, "config type already initialized!\n");
			error = 1;
		}
		return (error);
	}

	if (strcmp(parameter, "system") == 0) {
		if (!system_type_init) {
			if (strcmp(input_str, "fiesta") == 0) {
				system_type = FIESTA;
			} else if (strcmp(input_str, "gmfiesta") == 0) {
				system_type = GMFIESTA;
				if (type == CPU)
					seeprom_data = &gm_cpu_seeprom_data[0];
			} else if (strcmp(input_str, "excalibur") == 0) {
				system_type = EXCALIBUR;
			} else if (strcmp(input_str, "serrano") == 0) {
				system_type = SERRANO;
				if (type == CPU)
					seeprom_data =
						&serrano_cpu_seeprom_data[0];
			} else {
				fprintf(stderr, " invalid system type: %s\n",
					input_str);
				error = 1;
			}
			system_type_init = 1;
		} else {
			fprintf(stderr, "system type already initialized!\n");
			error = 1;
		}
		if ((system_type == FIESTA || system_type == GMFIESTA ||
				system_type == SERRANO) &&
		    type == SYS)
			seeprom_data = &fiesta_sys_data[0];
		return (error);
	}

	if (fixed_parameter(parameter)) {
		unsigned long long input_val;
		if (get_one_input(num_scanned, input_str, &input_val))  {
			if (update_seeprom(parameter, input_val)) {
				error = 1;
			}
		} else
			error = 1;
	} else {
		int (*funcp)();

		funcp = seeprom_func[type].dynamic_func;
		switch (funcp(parameter, line)) {
		case ERROR:
			error = 1;
			break;
		case UNKNOWN:
			fprintf(stderr,
			    "WARNING: Unknown parameter: %s\n", parameter);
			break;
		default:
			break;
		}
	}
	if (error)
		print_input_error(parameter);
	return (error);
}

/*
 * Print config info
 */
static void
dump_seeprom(void)
{
	char *string;
	void (*funcp)();
	int i = 0;

	if (quiet)
		return;

	while (seeprom_data[i].name != NULL) {
		if (strcmp(seeprom_data[i].name, "pad")) {
			string = strdup(seeprom_data[i].name);
			string = strcat(string, ":");
			printf("%-20s", string);
			printf("	0x%llx\n", seeprom_data[i].value);
		}
		i++;
	}
	printf("\n");
	funcp = seeprom_func[type].dump_func;
	funcp();
}

/*
 * Verify parameters are valid
 */
static int
check_data(void)
{
	int (*funcp)();
	funcp = seeprom_func[type].check_func;
	return (funcp());
}

/*
 * Write n bytes to string
 */
void
store_bytes(unsigned short bytes, unsigned long long data,
    unsigned char **store_ptr)
{
	unsigned short count;
	unsigned char byte;

	count = bytes;

	while (count) {
		byte = data >> ((count-1)*8);
		byte &= 0xff;
		**store_ptr = byte;
		*store_ptr += 1;
		count--;
	}
}

/*
Generate binary image
*/
static int
write_image(char *out_file)
{
	int i, size;
	unsigned char *image, *ptr;
	void (*funcp)();
	int file, retval = 0;
	int checksum_offset = 0;
	int found = 0;

	ptr = image = malloc(MAX_IMAGE);

	i = 0;
	while (seeprom_data[i].name != NULL) {
		if (strcmp(seeprom_data[i].name, "checksum")) {
			if (!found)
				checksum_offset += seeprom_data[i].size;
		} else {
			found = 1;
			if (do_checksum && seeprom_data[i].size != 2) {
				fprintf(stderr, "Cannot generate checksum,");
				fprintf(stderr,
					"checksum size must be 2 bytes!\n");
				do_checksum = 0;
			}
		}
		store_bytes(seeprom_data[i].size, seeprom_data[i].value, &ptr);
		i++;
	}

	funcp = (void (*)()) seeprom_func[type].write_func;
	funcp(&ptr);

	size = ptr-image;
	if (size > MAX_IMAGE) {
		sprintf(err_string,
		    "SEEPROM image size of %d,"
		    "exceeds maximum size of %d bytes!",
		    size, MAX_IMAGE);
		print_error(err_string);
		retval = 1;
	} else {
		if (do_checksum) {
			if (fixed_parameter("checksum")) {
				/*
				modify checksum for release images
				so diff between debug and release
				version is less obvious
				*/
				unsigned short cksum =
				checksum((unsigned short *) image, size);
				if (release && type == CPU)
					cksum *= 2;
				image[checksum_offset] = (cksum >> 8) & 0xff;
				image[checksum_offset+1] = cksum & 0xff;
			}
		}
		file = open(out_file, O_CREAT|O_TRUNC|O_WRONLY, 0666);
		if (file < 0) {
			fprintf(stderr, "Can't open output file %s\n",
			    out_file);
			retval = 1;
		} else {
			int tmp = write(file, image, size);
			if (tmp != size) {
				fprintf(stderr, "Short write on %s\n",
				    out_file);
				retval = 1;
			} else {
				if (!quiet)
					printf("Wrote %d bytes to %s\n",
					    size, out_file);
			}
			close(file);
		}
	}
	free(image);
	return (retval);
}

int
main(int argc, char **argv)
{
	char *out_file;
	char line[MAXLINE];
	int c;
	extern char *optarg;
	extern int optind;
	char *output_file, *endptr;
	FILE *file;

	if (usage_expired()) {
		fprintf(stderr, "%s: tool expired. Need new copy.\n", argv[0]);
		exit(1);
	}

	while ((c = getopt(argc, argv, "qr")) != EOF)
		switch (c) {
		case 'q':
			quiet = 1;
			break;
#ifndef DEBUG
		/* r option will clear high bit of id_magic */
		/* as well as muddle up checksum. */
		case 'r':
			release = 1;
			break;
#endif
		default:
			usage(argv[0]);
		}


	if (optind < argc) {
		config_file = argv[optind];
	} else {
		usage(argv[0]);
	}

	if (!quiet)
		printf("config_file:		%s\n", config_file);
	if ((file = fopen(config_file, "r")) != NULL) {
		while (fgets(line, MAXLINE, file)) {
			if ((line[0] != '\n') && (line[0] != '#')) {
				if (process_line(line)) {
					exit(1);
				}
			}
		}
		fclose(file);
	} else {
		sprintf(err_string, "Can't open config file %s!", config_file);
		print_error(err_string);
		exit(1);
	}

	if (check_data()) {
		fprintf(stderr, "Config file error!\n");
		exit(1);
	}

	dump_seeprom();
	output_file = strdup(config_file);
	endptr = strrchr(output_file, '.');
	if (endptr != NULL) *endptr = 0;
	out_file = strcat(output_file, ".bin");
	/* Debug images have the high bit of id_magic set */
	if (force_debug)
		release = 0;
	if (type == CPU && !release) {
		unsigned long long temp;
		temp = get_seeprom("id_magic");
		update_seeprom("id_magic", temp | 0x8000);
	}
	if (write_image(out_file)) {
		sprintf(err_string, "Write to output file %s unsuccessful!",
		    out_file);
		print_error(err_string);
		exit(1);
	}
	exit(0);
}
