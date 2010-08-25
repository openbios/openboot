/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: filepath.c
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
 * @(#)filepath.c 1.1 02/05/02
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Copyright Use is subject to license terms.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "xref.h"

static char *root = NULL;
static int  no_relocate = 0;

char *
xref_extract_pathname(char *srcpath)
{
	char *file;
	char *pwd;
	char *dirname;
	char *iptr, *cptr;
	char *path;
	char *cwd;
	static char cwd_buf[255];

	if (no_relocate) {
		return (strdup(srcpath));
	}
	getcwd(cwd_buf, sizeof (cwd_buf));
	cwd = strdup(cwd_buf);

	if (root == NULL) {
		root = getenv("BP");
		if (root == NULL) {
			no_relocate = 1;
			return (strdup(srcpath));
		}
		chdir(root);
		getcwd(cwd_buf, sizeof (cwd_buf));
		chdir(cwd);
		root = strdup(cwd_buf);
	}

	path = strdup(srcpath);
	if (strncmp(path, "${BP}", 5) == 0) {
		char *npath;
		npath = malloc(strlen(root) + strlen(srcpath));
		strcpy(npath, root);
		strcat(npath, srcpath + 5);
		free(path);
		path = npath;
	}

	cptr = strrchr(path, '/');
	if (cptr == NULL) {
		dirname = strdup(".");
		file = strdup(path);
	} else {
		*cptr = 0;
		dirname = strdup(path);
		file = strdup(cptr+1);
	}
	free(path);

	chdir(dirname);
	getcwd(cwd_buf, sizeof (cwd_buf));
	chdir(cwd);
	free(cwd);

	pwd = strdup(cwd_buf);
	free(dirname);

	iptr = root;
	cptr = pwd;
	while (*iptr++ == *cptr++);
	strcpy(cwd_buf, "${BP}/");
	strcat(cwd_buf, cptr);
	strcat(cwd_buf, "/");
	strcat(cwd_buf, file);
	free(file);
	free(pwd);
	return (cwd_buf);
}
