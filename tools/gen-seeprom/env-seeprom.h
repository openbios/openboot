/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: env-seeprom.h
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
 * id: @(#)env-seeprom.h 1.2 02/10/09
 * purpose: 
 * copyright: Copyright 2000-2002 Sun Microsystems, Inc.  All Rights Reserved
 * copyright: Use is subject to license terms.
 */


struct env_parameter_data
{
	char *name;
	unsigned short size;
};

#define	H_POFF_SIZE	1
#define	H_SDWN_SIZE	1
#define	H_WARN_SIZE	1
#define	L_WARN_SIZE	1
#define	L_SDWN_SIZE	1
#define	L_POFF_SIZE	1
#define	POLICY_SIZE	1
#define	VB_SIZE		1
#define	RES_SIZE	1
#define	NUM_COR_SIZE	2

#define	COR_SIZE	2

#define	FAN_TSPIN_SZ		1
#define	FAN_SPD_SZ		1
#define	FAN_SETPOINT_SZ		2
#define	FAN_LOOPGAIN_SZ		2
#define	FAN_LOOPBIAS_SZ		2
#define	FAN_HYST_SZ		2
#define	FAN_TEST_INT_SZ		2
#define	FAN_TEST_RPM_SZ		2
#define	FAN_GROSS_RPM_SZ	2
#define	FAN_CTL_PAIR_SZ		1
#define	FAN_MIN_RANGE_SZ	2

#define	ID_SIZE		4
#define	OFFSET_SIZE	2
#define	FAN_ID_SIZE	4
#define	FAN_OFF_SIZE	2
#define	SENSOR_BLOCK_SIZE	(ID_SIZE + OFFSET_SIZE)
#define	FAN_BLOCK_SIZE		(FAN_ID_SIZE + FAN_OFF_SIZE)

#define	VER_SIZE	1
#define	NUM_SEN_SIZE	1
#define	NUM_FAN_SIZE	1

struct env_parameter_data env_parameters[] =
{
	/*  name		size  */
	{ "high-poweroff",	H_POFF_SIZE },
	{ "high-shutdown",	H_SDWN_SIZE },
	{ "high-warning",	H_WARN_SIZE },
	{ "low-warning",	L_WARN_SIZE },
	{ "low-shutdown",	L_SDWN_SIZE },
	{ "low-poweroff",	L_POFF_SIZE },
	{ "policy",		POLICY_SIZE },
	{ "valid-bytes",	VB_SIZE  },
	{ "reserved1",		RES_SIZE },
	{ "reserved2",		RES_SIZE },
	{ "reserved3",		RES_SIZE },
	{ "reserved4",		RES_SIZE },
	{ "reserved5",		RES_SIZE },
	{ "reserved6",		RES_SIZE },
	{ "num-corrections",	NUM_COR_SIZE },
	{ "correction",		0 },
	{ NULL,			0 },
};

struct env_parameter_data fan_parameters[] =
{
	/*  name		size  */
	{ "tspin-up",		FAN_TSPIN_SZ },
	{ "min-fan-spd",	FAN_SPD_SZ },
	{ "setpoint",		FAN_SETPOINT_SZ },
	{ "loop-gain",		FAN_LOOPGAIN_SZ },
	{ "loop-bias",		FAN_LOOPBIAS_SZ },
	{ "hysteresis",		FAN_HYST_SZ },
	{ "test-interval",	FAN_TEST_INT_SZ },
	{ "test-rpm-threshold",	FAN_TEST_RPM_SZ },
	{ "gross-rpm-threshold", FAN_GROSS_RPM_SZ },
	{ "num-ctl-pairs",	FAN_CTL_PAIR_SZ },
	{ "fan-min-range",	FAN_MIN_RANGE_SZ },
	{ NULL,			0 },
};

/*
 * COR_SIZE is not added because the number of corrections is dynamic
 */

#define	ENV_ENTRY_SIZE		(H_POFF_SIZE + 	H_SDWN_SIZE + H_WARN_SIZE + \
				L_WARN_SIZE + L_SDWN_SIZE + L_POFF_SIZE + \
				POLICY_SIZE + VB_SIZE + (6 * RES_SIZE) + \
				NUM_COR_SIZE)

/*
 * FAN_MIN_RANGE_SIZE is not added because the number of min/range entries
 * is dynamic.
 */

#define	ENV_FAN_ENTRY_SIZE	(FAN_TSPIN_SZ + FAN_SPD_SZ + FAN_SETPOINT_SZ \
				+ FAN_LOOPGAIN_SZ + FAN_LOOPBIAS_SZ \
				+ FAN_HYST_SZ + FAN_TEST_INT_SZ \
				+ FAN_TEST_RPM_SZ + FAN_GROSS_RPM_SZ \
				+ FAN_CTL_PAIR_SZ)

struct id_header_data
{
	int num_sensors, num_fans;
	unsigned char *id_block;
	unsigned char *fan_block;
};

struct env_table_entry
{
	unsigned char env_data[ENV_ENTRY_SIZE];
	int correction_size;
	unsigned char *correction_data;
	struct env_table_entry *next;
};

struct fan_table_entry
{
	unsigned char fan_data[ENV_FAN_ENTRY_SIZE];
	int fan_pair_size;
	unsigned char *fan_ctl_data;
	struct fan_table_entry *next;
};
