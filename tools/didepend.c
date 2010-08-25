/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: didepend.c
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
 * id: @(#)didepend.c 1.12 04/04/22
 * purpose:
 * copyright: Copyright 1997-2004 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>

#include "defines.h"

#define	SOURCE_FLAG	0x01
#define	TARGET_FLAG	0x02
#define	DEPEND_FLAG	0x04
#define	CODE_FLAG	0x08
#define	CODE_START	0x10
#define	CODE_END	0x20
#define	COMPAT_MODE	0x40

#define	MAXLINE 512

FILE	*ifd;
char	*buildcmd = NULL;
char	*progname = NULL;
char	*filename = NULL;
char	*codefile  = NULL;
char	*srcfile  = NULL;
char	buffer[ MAXLINE ];
int	flags = 0;
int	line_num = 0;
int	argcount;
int	pedantic = 0;
int	defdepth = 0;
int	showsyms = 0;
int	verbose = 0;

void
usage(void)
{
	fprintf(stderr, "%s: [flag] sourcefile\n", progname);
	fprintf(stderr, "   -D <symbol> : define <symbol>\n");
	fprintf(stderr, "   -U <symbol> : undefine <symbol>\n");
	fprintf(stderr, "   -S          : show symbols used\n");
	fprintf(stderr, "   -s          : print sources\n");
	fprintf(stderr, "   -t          : print targets\n");
	fprintf(stderr, "   -d          : print dependancies\n");
	fprintf(stderr, "   -c          : print code\n");
	fprintf(stderr, "   -p          : pedantic mode\n");
	exit(1);
}

typedef void * retval;

#define	CAST(x) (retval) (x)

#define	CMD_NULL_ARGS	0x00
#define	CMD_OPT_ARGS	0x10
#define	CMD_COMPAT	0x20
#define	CMD_COMPAT_ONLY	0x40
#define	CMD_IFDEF	0x80
#define	CMD_MASK	0xf0

typedef struct CMD
{
	char	*name;
	retval	(*fn)(char *arg0, char *line);
	int	flags;
} cmd;

retval enable_cmds(char *line, char *arg0);
retval disable_cmds(char *line, char *arg0);
retval get_source_line(char *line, char *arg0);
retval set_build_cmd(char *arg0, char *line);
retval grab_depend_line(char *arg0, char *line);
retval grab_target_line(char *arg0, char *line);
retval grab_external_line(char *arg0, char *line);
retval grab_source(char *arg0, char *line);
retval comment_line(char *arg0, char *line);
retval unexpected_token(char *arg0, char *line);
retval get_execute_token(char *arg0, char *line);
retval grab_next_file(char *arg0, char *line);
retval set_code_file(char *arg0, char *line);
retval set_build_flags(char *arg0, char *line);
retval do_message(char *arg0, char *line);
retval do_define(char *arg0, char *line);
retval do_undef(char *arg0, char *line);
retval do_ifdef(char *arg0, char *line);
retval do_ifndef(char *arg0, char *line);
retval do_else(char *arg0, char *line);
retval do_endif(char *arg0, char *line);

#define	COMPAT_NO_ARGS	CMD_COMPAT|CMD_NULL_ARGS
#define	COMPAT_OPT_ARGS	CMD_COMPAT|CMD_OPT_ARGS

cmd cmds[] = {
	{  "version1",	disable_cmds,		COMPAT_NO_ARGS },
	{  "version2",	enable_cmds,		COMPAT_NO_ARGS },
	{  "build",  	set_build_cmd,		CMD_OPT_ARGS | 1 },
	{  "depend", 	grab_depend_line,	1 },
	{  "target", 	grab_target_line,	2 },
	{  "external",	grab_external_line,	1 },
	{  "source{", 	grab_source,		CMD_OPT_ARGS },
	{  "}source", 	unexpected_token,	CMD_NULL_ARGS },
	{  "#",		comment_line,		COMPAT_OPT_ARGS },
	{  "-",		get_source_line,	CMD_COMPAT_ONLY },
	{  "include",	grab_next_file,		1 },
	{  "codefile",	set_code_file,		1 },
	{  "buildoptions", set_build_flags,	CMD_OPT_ARGS | 1 },
	{  "message",	do_message,		CMD_OPT_ARGS | 1 },
	{  "#define",	do_define,		1 },
	{  "#undef",	do_undef,		1 },
	{  "#ifdef",	do_ifdef,		CMD_IFDEF | 1 },
	{  "#ifndef",	do_ifndef,		CMD_IFDEF | 1 },
	{  "#else",	do_else,		CMD_IFDEF | CMD_NULL_ARGS },
	{  "#endif",	do_endif,		CMD_IFDEF | CMD_NULL_ARGS },
	{  NULL, NULL, 0 }
};

void
malloc_failed(void *ptr)
{
	if (ptr == NULL) {
		fprintf(stderr, "%s:%d: Malloc failed\n", filename, line_num);
		exit(1);
	}
}

char *
get_arg(char *line, int which, int *rpos)
{
	static char	arg[MAXLINE];
	char		*tokens = " \t";
	char		*start;
	int		strip;
	int		len, end, pos, prev;

	if ((line == NULL) || (*line == 0)) {
		return (NULL);
	}

	end = strlen(line);
	prev = pos = 0;
	start = line;
	while ((which-- >= 0) && (pos < end)) {
		strip = strspn(start, tokens);
		start += strip;
		pos += strip;
		prev = pos;
		len = strcspn(start, tokens);
		pos += len;
		if ((pos >= end) && (which >= 0)) {
			if (rpos) *rpos = prev;
			return (NULL);
		}
		if (len) {
			strncpy(arg, start, len);
			arg[len] = 0;
		} else {
			strcpy(arg, start);
		}
		start += len;
	}
	if (rpos) *rpos = prev;
	return (arg);
}

int
count_args(char *line)
{
	int argc;
	char *lastarg;

	if (line == NULL) {
		return (0);
	}

	argc = 0;
	lastarg = line;
	while (lastarg) {
		lastarg = get_arg(line, argc+1, NULL);
		if (lastarg) argc++;
	}
	return (argc);
}

void
automatic_message(char comment)
{
	printf("%c\n", comment);
	printf("%c Warning this is a machine generated file\n", comment);
	printf("%c Changes made here will go away\n", comment);
	printf("%c\n", comment);
}

/* This is gross, but exists for Version1 compatability. */
char *fthsrc =
"id: %" "Z%%" "M%  %" "I%  %" "E%\n"
"purpose: %" "Y%\n"
"copyright: Copyright 1989-1997 Sun Microsystems, Inc. All Rights Reserved\n"
"\n"
"\" /packages/SUNW,builtin-drivers\" find-device\n"
"\n"
": do-fcode ( str$ -- )\n"
"   find-drop-in if\n"
"      2dup 2>r execute-buffer\n"
"      2r> free-drop-in\n"
"   then\n"
";\n\n";

char *
get_line(char *line, int from)
{
	char *argp;
	int  pos;

	argp = get_arg(line, from, &pos);
#if 0
	printf("rem_line: '%s'\n", (argp ? argp : ""));
#endif
	if (argp == NULL) {
		return ("");
	}
	return (line + pos);
}

retval
get_more_source(char *cmd, char *line)
{
	int len;
	char *backslash;

	printf("get_more_source('%s','%s')\n",
	    (cmd ? cmd : ""),
	    (line ? line : ""));
	len = strlen(line);
	if (len > 1) {
		backslash = line+len-1;
		if (*backslash == '\\') {
			*backslash = 0;
			if (cmd == NULL)
				printf("%s\n", get_line(line, 2));
			else
				printf("%s\n", line);
			return (CAST(get_more_source));
		}
	}
	return (CAST(get_execute_token));
}


retval
get_source_line(char *cmd, char *line)
{
	char *arg0, *argp, *arg1, *argn;
	static int once = 0;
	int tail;

#if 0
	printf("get_source_line('%s','%s')\n",
	    (cmd ? cmd : "NULL"),
	    (line ? line : "NULL"));
#endif
	arg0 = arg1 = argn = NULL;
	if (cmd == NULL) {
		argp = get_arg(line, 0, NULL);
		if (argp) arg0 = strdup(get_arg(line, 0, NULL));
		malloc_failed(arg0);
	} else {
		arg0 = strdup(cmd);
	}

	argp = get_arg(line, 1, NULL);
	if (argp) arg1 = strdup(argp);
	malloc_failed(arg1);

	argp = get_line(line, 2);
	if (flags & CODE_FLAG) {
		if (!once) {
			printf("%s", fthsrc);
			once++;
		}
		get_more_source(cmd, line);
	}
	if (cmd == NULL) {
		if (flags & SOURCE_FLAG) {
			printf("%s ", arg0);
		}
		if (flags & TARGET_FLAG) {
			printf("%s ", arg1);
		}
		if (flags & DEPEND_FLAG) {
			printf("%s: %s\n\t%s %s %s\n\n",
			    arg0, arg1,
			    buildcmd, arg0, arg1);
		}
	}
	if (arg0) free(arg0);
	if (arg1) free(arg1);
	return (CAST(get_more_source(cmd, line)));
}

retval
enable_cmds(char *arg0, char *line)
{
	flags &= ~COMPAT_MODE;
	return (CAST(get_execute_token));
}

retval
disable_cmds(char *arg0, char *line)
{
	flags |= COMPAT_MODE;
	return (CAST(get_execute_token));
}

retval
set_build_cmd(char *arg0, char *line)
{
	char *sptr;

	if (buildcmd) free(buildcmd);
	sptr = get_line(line, 1);
	if ((sptr == NULL) || ((sptr != NULL) && (strlen(sptr) == 0))) {
		fprintf(stderr, "%s:%d: Error, Missing argument\n",
		    filename, line_num);
		exit(1);
	}
	buildcmd = strdup(sptr);
	malloc_failed(buildcmd);
	return (CAST(get_execute_token));
}

retval
set_code_file(char *arg0, char *line)
{
	char *sptr;

	if (codefile) free(codefile);
	sptr = get_line(line, 1);
	if ((sptr == NULL) || ((sptr != NULL) && (strlen(sptr) == 0))) {
		fprintf(stderr, "%s:%d: Error, Missing argument\n",
		    filename, line_num);
		exit(1);
	}
	codefile = strdup(sptr);
	malloc_failed(codefile);
	return (CAST(get_execute_token));
}

retval
grab_depend_line(char *arg0, char *line)
{
	static int once = 0;

	if (flags & DEPEND_FLAG) {
		if (!once++) automatic_message('#');
		printf("\ninclude %s\n", get_arg(line, 1, NULL));
	}
	return (CAST(get_execute_token));
}

retval
grab_target_line(char *arg0, char *line)
{
	char *cptr, *dptr, *source, *target, *diname;
	int tflags;

	cptr = get_arg(line, 1, NULL);
	source = strdup(cptr);
	malloc_failed(source);
	dptr = strrchr(cptr, '/');
	if (dptr) cptr = dptr+1;
	target = strdup(cptr);
	malloc_failed(target);
	diname = get_arg(line, 2, NULL);
	cptr = strrchr(target, '.');
	if (cptr) *cptr = 0;

	if (flags & TARGET_FLAG) printf("%s.di ", target);
	if (flags & SOURCE_FLAG) printf("%s ", source);
	if (flags & DEPEND_FLAG) {
		printf("\n%s.di: %s %s\n\t%s %s %s\n",
		    target, srcfile, source,
		    buildcmd, source, diname);
	}
	free(target);
	free(source);
	return (CAST(get_execute_token));
}

retval
grab_external_line(char *arg0, char *line)
{
	if (flags & TARGET_FLAG) printf("%s ", get_arg(line, 1, NULL));
	return (CAST(get_execute_token));
}

retval
wait_source_end(char *arg0, char *line)
{
	int end, argc;
	char *last_arg;

	printf("wait_source_end('%s','%s')\n", arg0, line);

	end = (strcmp(arg0, "}source") == 0);
	if (flags & DEPEND_FLAG) {
		if (!end) printf("%s\n", line);
	}
	if (!end) {
		return (CAST(wait_source_end));
	}
	return (CAST(get_execute_token));
}

retval
grab_source(char *arg0, char *line)
{
	static int start_code = 0;
	static int once = 0;
	int end, start;
	int codebase, codeend, codelen;
	retval (*fn)(char *, char *);
	char *args;
	char *lptr = strdup(line);

	malloc_failed(lptr);

	fn = grab_source;
	start = (strcmp(arg0, "source{") == 0);
	if ((start) && (start_code++)) {
		fprintf(stderr, "%s:%d: Warning, unbalanced start{ tokens\n",
		    filename, line_num);
		if (pedantic) exit(1);
	}
	if (argcount)
		(void) get_arg(line, 1, &codebase);
	else
		codebase = strlen(arg0);
	args = get_arg(lptr, argcount, &codeend);
	end = (strcmp(args, "}source") == 0);

	if (!start)	codebase = 0;
	if (!end)	codeend  = strlen(line);

	codelen = (codeend-codebase);
	strncpy(lptr, line + codebase, codelen);
	lptr[codelen] = 0;

	if (flags & CODE_FLAG) {
		if (start && !once++) automatic_message('\\');
		printf("%s\n", lptr);
	}

	if (end) {
		start_code--;
		fn = get_execute_token;
	}
	free(lptr);
	return (CAST(fn));
}

retval
set_build_flags(char *arg0, char *line)
{
	if (flags & DEPEND_FLAG) {
		printf("\n%s", get_line(line, 1));
	}
	return (CAST(get_execute_token));
}

retval
comment_line(char *arg0, char *line)
{
	return (CAST(get_execute_token));
}

retval
do_message(char *arg0, char *line)
{
	if (flags & CODE_FLAG) {
		fprintf(stderr, "%s:%d: %s\n",
		    filename, line_num, get_line(line, 1));
	}
	return (CAST(get_execute_token));
}

retval
do_define(char *arg0, char *line)
{
	define_symbol(get_arg(line, 1, NULL), FORTH_DEFINE);
	return (CAST(get_execute_token));
}

retval
do_undef(char *arg0, char *line)
{
	define_symbol(get_arg(line, 1, NULL), FORTH_UNDEF);
	return (CAST(get_execute_token));
}

#define	DEF_ELSE	1
#define	DEF_ENDIF	2
#define	DEF_SKIP	4
#define	MAX_DEF_DEPTH	5

#define	defskip (def_state[defdepth] & DEF_SKIP)

static int def_state[10] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

void
def_state_check(int state, int flag, char *msg)
{
	if ((state & flag) == 0) {
		fprintf(stderr, "%s:%d: Parse Error, %s\n",
		    filename, line_num, msg);
		exit(1);
	}
	if (defdepth > MAX_DEF_DEPTH) {
		fprintf(stderr, "%s:%d: too many Nested IFDEF's\n",
		    filename, line_num);
		exit(1);
	}
}

void
do_common_ifdef(char *arg0, char *line, int do_true)
{
	int state = (DEF_ELSE | DEF_ENDIF);
	int def;

	def_state_check(1, 1, "");
	state |= def_state[defdepth++] & DEF_SKIP;
	def = symbol_defined(get_arg(line, 1, NULL));
	if ((do_true && !def) || (!do_true && def)) {
		state |= DEF_SKIP;
	}
	def_state[defdepth] = state;
}

retval
do_ifdef(char *arg0, char *line)
{
	do_common_ifdef(arg0, line, 1);
	return (CAST(get_execute_token));
}

retval
do_ifndef(char *arg0, char *line)
{
	do_common_ifdef(arg0, line, 0);
	return (CAST(get_execute_token));
}

retval
do_else(char *arg0, char *line)
{
	def_state_check(def_state[defdepth], DEF_ELSE, "Dangling #else");
	def_state[defdepth] &= ~DEF_ELSE;
	def_state[defdepth] ^= DEF_SKIP;
	def_state[defdepth] |= def_state[defdepth-1] & DEF_SKIP;
	return (CAST(get_execute_token));
}

retval
do_endif(char *arg0, char *line)
{
	def_state_check(def_state[defdepth], DEF_ENDIF, "Dangling #endif");
	def_state[defdepth--] &= ~DEF_ENDIF;
	return (CAST(get_execute_token));
}

retval
unexpected_token(char *arg0, char *line)
{
	fprintf(stderr, "%s:%d: bad token '%s'\n", filename, line_num, arg0);
	exit(1);
	return (NULL);
}

retval
get_execute_token(char *token, char *line)
{
	retval (*fn)(char *p, char *);
	cmd	*cptr = cmds;

	fn = unexpected_token;
	while (cptr->name != NULL) {
		int nargs;

		if (strcmp(cptr->name, token) != 0) {
			cptr++;
			continue;
		}

		if (((flags & COMPAT_MODE) && !(cptr->flags & CMD_COMPAT)) ||
		    (!(flags & COMPAT_MODE) && (cptr->flags & CMD_COMPAT_ONLY)))
			unexpected_token(token, line);

		nargs = cptr->flags & ~CMD_MASK;
		if (verbose) {
			printf("[%d,%d] CMD: '%s' args = %d, argc = %d\n",
			    defdepth, defskip, token, nargs, argcount);
		}

		if ((argcount > nargs) && (!(cptr->flags & CMD_OPT_ARGS))) {
			fprintf(stderr,
			    "%s:%d: Warning, extra arguments for '%s'\n",
			    filename, line_num, token);
			if (pedantic) exit(1);
		}

		if (argcount < nargs) {
			fprintf(stderr,
			    "%s:%d: Missing arguments for '%s'\n",
			    filename, line_num, token);
			exit(1);
		}
		fn = cptr->fn;
		break;
	}
	if ((flags & COMPAT_MODE) && (fn == unexpected_token)) {
		return (CAST(get_source_line(NULL, line)));
	}
	if (!(cptr->flags & CMD_IFDEF) && defskip) {
		fn = comment_line;
	}
	return (CAST((*fn)(token, line)));
}

void
process_file(char *name, int recurse)
{
	char	comment = 0;
	char	*savename;
	FILE	*infile;
	int	linenum;
	int	done = 0;
	retval (*process)(char *line, char *arg);

	/*
	 * This is a gross hack! I should have made this entire thing parameter
	 * driven, instead I chose to use globals :(
	 * So I need to save and restore them for this cruft to work.
	 */
	if (recurse) {
		if (flags & DEPEND_FLAG) printf("\n%s: %s\n", codefile, name);
		linenum = line_num;
		infile   = ifd;
		savename = filename;
		if (flags & CODE_FLAG) {
			comment = '\\';
		} else if (flags & DEPEND_FLAG) {
			comment = '#';
		}
		if (comment) printf("\n%c Included from %s\n", comment, name);
	}
	filename = strdup(name);
	malloc_failed(filename);
	ifd = fopen(filename, "r");
	if (ifd == NULL) {
		fprintf(stderr, "%s: unable to open: %s for reading",
		    progname, filename);
		exit(1);
	}

	process = get_execute_token;
	line_num = 0;
	while (!done) {
		char	*line, *cptr;
		char	cmd[MAXLINE];

		line_num++;
		line = fgets(buffer, MAXLINE, ifd);
		cmd[0] = 0;

		if (line) {
			cptr = strchr(line, '\n');
			if (cptr) *cptr = 0;
			argcount = count_args(line);
			cptr = get_arg(line, 0, NULL);
			if (cptr) strcpy(cmd, cptr);
		}
		done = (line == NULL) || feof(ifd);

		if (!done) {
			if (*cmd != 0)
				process = (retval (*)()) process(cmd, line);
		}
	}
	fclose(ifd);
	free(filename);
	if (recurse) {
		line_num = linenum;
		ifd = infile;
		filename = savename;
		if (comment) printf("\n%c back to %s\n", comment, filename);
	}
}

retval
grab_next_file(char *arg0, char *line)
{
	char *cptr, eptr;

	cptr = get_arg(line, 1, NULL);

	if (flags & DEPEND_FLAG) {
		printf("\n%s: %s\n", codefile, cptr);
	}

	process_file(cptr, 1);

	return (CAST(get_execute_token));
}

main(int argc, char **argv)
{
	extern char *optarg;
	extern int optind;
	int errflg = 0;
	int c;

	progname = argv[0];
	while ((c = getopt(argc, argv, "D:U:SVstdcp")) != EOF)
		switch (c) {
		case 'D':
			define_symbol(optarg, CMD_DEFINE);
			break;
		case 'U':
			define_symbol(optarg, CMD_UNDEF);
			break;
		case 'S':
			showsyms = 1;
			break;
		case 'V':
			verbose = 1;
			break;
		case 's':
			if (!flags) flags = SOURCE_FLAG; else usage();
			break;

		case 't':
			if (!flags) flags = TARGET_FLAG; else usage();
			break;

		case 'd':
			if (!flags) flags = DEPEND_FLAG; else usage();
			break;

		case 'c':
			if (!flags) flags = CODE_FLAG; else usage();
			break;

		case 'p':
			pedantic++;
			break;

		default:
			usage();
		}

	if (!flags) usage();
	flags |= COMPAT_MODE;

	progname = argv[0];
	(void) set_build_cmd(NULL, "build\t${MAKEDI}");
	(void) set_code_file(NULL, "codefile\tbuiltin.fth");
	srcfile = argv[optind];
	process_file(srcfile, 0);
	finish_symbols(showsyms);
	exit(0);
}
