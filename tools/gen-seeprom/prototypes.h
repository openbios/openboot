/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: prototypes.h
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
 * id: @(#)prototypes.h 1.7 05/11/15
 * purpose:
 * copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */

extern struct fixed_seeprom cpu_seeprom_data[];
extern struct fixed_seeprom gm_cpu_seeprom_data[];
extern struct fixed_seeprom serrano_cpu_seeprom_data[];
extern struct fixed_seeprom sys_seeprom_data[];
extern struct fixed_seeprom fiesta_sys_data[];
extern struct fixed_seeprom env_seeprom_data[];
extern struct fixed_seeprom mem_seeprom_data[];
extern struct fixed_seeprom env_seeprom_data_v2[];

extern struct fixed_seeprom cpu_rw_data[];
extern int cpu_dynamic(char *parameter, char *line);
extern int check_cpu(void);
extern int reg_cpu(char *s1, data_reg **reg);
extern void write_cpu(unsigned char **ptr);
extern void dump_cpu(void);

extern int sys_dynamic(char *parameter, char *line);
extern int check_sys(void);
extern int reg_sys(char *s1, data_reg **reg);
extern void write_sys(unsigned char **ptr);
extern void dump_sys(void);

extern int env_dynamic(char *parameter, char *line);
extern int check_env(void);
extern int reg_env(char *s1, data_reg **reg);
extern void write_env(unsigned char **ptr);
extern void dump_env(void);

extern int mem_dynamic(char *parameter, char *line);
extern int check_mem(void);
extern int reg_mem(char *s1, data_reg **reg);
extern void write_mem(unsigned char **ptr);
extern void dump_mem(void);

extern int scan_line(char *line, unsigned int *input_val);
extern void write_bytes(unsigned int input_val, int size, int offset,
    unsigned char *data_ptr);
extern void store_chars(int len, unsigned char *string, unsigned char **ptr);

void store_bytes(unsigned short bytes, unsigned long long data,
    unsigned char **);

unsigned long long get_seeprom(char *name);
int update_seeprom(char *name, unsigned long long value);
void print_error(char *string);

extern char err_string[];
