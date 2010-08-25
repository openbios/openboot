/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: wrapper.c
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
 * @(#)wrapper.c 2.29 02/09/23
 * Copyright 1985-1994 Bradley Forthware
 * Copyright 2001-2002 Sun Microsystems, Inc.  All Rights Reserved
 * Use is subject to license terms.
 *
 * This is the C wrapper program for Forthmacs.  There are 3 problems to
 * solve in porting Forthmacs to a different machine.
 *
 * 1) What is the format of a binary file
 * 2) How are I/O system calls invoked
 * 3) At which address will the binary run (relocation)
 *
 * This C program finesses problems 1 and 2 by assuming that the C
 * compiler/linker knows how to do those those things.  The Forth
 * interpreter itself is stored in a file whose format is system-independent.
 * The C program mallocs an array, reads the Forth image into that array,
 * and calls the array as a subroutine, passing it the address of another
 * array containing entry points for I/O subroutines.
 *
 * The Forth interpreter relocates itself from a relocation bitmap
 * which is part of the Forth image file.
 */

static  char sccsid[] = "wrapper.c 2.4 91/07/25";

/*
 * Dynamic loader for Forth.  This program reads in a binary image of
 * a Forth system and executes it.  It connects standard input to the
 * Forth input stream (key and expect) and puts the Forth output stream
 * (emit and type) on standard output.
 *
 * An array of entry points for system calls is provided to the Forth
 * system, so that Forth doesn't have to know the details of how to
 * invoke system calls.
 *
 * Synopsis:
 *
 * forth [ -e dict-size ] [ -d <forth-binary>.dic ] [ -u ]
 *
 * dict-size is an optional decimal number specifying the number of
 * kilobytes of dictionary extension space to allocate.  The dictionary
 * extension space is the amount that the dictionary may grow as a result
 * of additional compilation, ALLOTing, etc.  If the dict-size argument
 * is omitted, a default value DEF_DICT is used.
 *
 * <forth-binary> is the name of the ".dic" file containing the forth binary
 * image.  The binary image is in a system-independent format, which contains
 * a header, the relocatable program image, and a relocation bitmap.
 *
 * If there is no such argument, the default binary file DEF_EXE is used.
 *
 * The Forth system may determine whether the input stream is coming from
 * a file or from standard input by calling the function "fileques()".
 * This is useful for deciding whether or not to prompt if it is possible
 * to redirect the input stream to a file.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <strings.h>

#include <sys/types.h>
#include <sys/time.h>
#include <sys/param.h>
#include <sys/stat.h>

#include <signal.h>

#include "wrapper.h"
#include "xref.h"
#include "defines.h"

#ifdef SYS5
#define	signal sigset
#endif

/*
 * deprecate all syscalls above 45
 */
#define	UNIMPL_FSYS

extern char *substr();

extern int	path_open();

void keyqmode(void);
void linemode(void);
void keymode(void);
void restoremode(void);

extern long 	f_open(), f_creat();
extern long	f_close(), f_read(), f_write();
extern long	f_ioctl();
extern long	f_lseek();
extern long	f_crstr();
extern long	c_key();
extern long	c_emit();
extern long	c_keyques();
extern long	c_cr();
extern long	fileques();
extern long	f_unlink();
extern long	c_expect();
extern long	c_type();
extern long	syserror();
extern int	errno;		/* Wherever the error code goes */
extern long	s_bye();
extern long	emacs();
extern long	pr_error();
extern long	s_signal();
extern long	s_system();
extern long	s_chdir();
extern long	s_getwd();
extern long	m_alloc();
extern long	m_free();
extern long	c_getenv();
extern long	today();
extern long	timez();
extern long	timezstr();
extern long	s_flushcache();
extern long	f_init(), f_op(), f_move(), f_rows(), f_cols();
extern long	pathname();
extern long	m_sbrk();
#ifdef PPCSIM
extern long printnum(), mmap(), close(), open();
#endif
#ifdef DLOPEN
extern long	dlopen(), dlsym(), dlerror(), dlclose();
#endif

void error(char *str1, char *str2);

extern long	find_next();

long    save_image(/* char *name,  header_t *header */);
long	bootstrap(/* char *name */);
long	includefile(/* char *name */);
long	refill(/* char *adr, fd, actual not-eof? error? */);
long	stack_syscall();

#define	UNIMPL(x)	printf("%s:%d: Unimplemented syscall " #x "\n", \
    __FILE__, __LINE__)

long ((*functions[])()) = {
/*	0	1	*/
	c_key,	c_emit,

	/* 2		3		4		5	*/
	f_open,		f_creat,	f_close, 	f_read,

	/* 6		7		8			*/
	f_write,	f_ioctl,	c_keyques,

	/* 9		10		11		12	*/
	s_bye,		f_lseek,	f_unlink,	fileques,

	/* 13		14		15			*/
	c_type,		c_expect,	syserror,

	/* 16		17		18			*/
	today,		timez,		timezstr,

	/* 19		20					*/
#if 0
	fork,		execve,
#else
	0L,		0L,
#endif
	/* 21							*/
	c_getenv,

	/* 22		23					*/
	s_system,	s_signal,

	/* 24		25					*/
	s_chdir,	s_getwd,

	/* 26		27		28			*/
	m_alloc,	c_cr,		f_crstr,

	/* 29		30		31			*/
	s_flushcache,	pr_error,	emacs,

	/* 32							*/
	m_free,

	/* 33		34		35		36	37 */
	f_init,		f_op,		f_move,		f_rows,	f_cols,

	/* 38							*/
	pathname,

#ifdef PPCSIM
	/* 39		40		41		42	*/
	printnum,	mmap,		open,		close,
#else
	/* 39							*/
	m_sbrk,

	/* 40		41		42		43	*/
#ifdef DLOPEN
	dlopen,		dlsym,		dlerror,	dlclose,
#else
	0,		0,		0,		0,
#endif
	/* 44							*/
#ifdef SIMFORTH
	find_next,
#else
	0,
#endif
	/* 45,		, 46		, 47		, 48	*/
	stack_syscall,	0,		0,		0,

	/* 49,		50		51		, 52	*/
	0,		0,		0,		0,

	/* 53,		54,		55,			*/
	0,		0,		0,

	/* 56							*/
	stack_syscall,

#endif
	/* EOT 							*/
	0
};

/*
 * Function semantics:
 *
 * Functions which are the names of Unix system calls have the semantics
 * of those Unix system calls.
 *
 * char c_key();				Gets next input character
 *	no echo or editing, don't wait for a newline.
 * c_emit(char c);				Outputs the character.
 * long f_open(char *path, long mode);		Opens a file.
 *	Mode must agree with wrsys.fth
 * long f_creat(char *path, long mode); 	Creates a file.
 *	Mode must agree with wrsys.fth
 * long f_read(long fd, char *buf, long cnt);	Reads from a file
 * long f_write(long fd, char *buf, long cnt);	Writes to a file
 * long f_ioctl(long fd, long code, char *buf);	Is not used right now.
 * long c_keyques();				True if a keystroke is pending.
 *	If you can't implement this, return false.
 * s_bye(long status);				Cleans up and exits.
 * long f_lseek(long fd, long offset, long whence);Changes file position.
 *	Whence:  0 - from start of file  1 - from current pos.  2 - from end
 * long f_unlink(char *path);			Deletes a file.
 * long fileques();				True if input stream has been
 *	redirected away from a keyboard.
 * long c_type(long len, char *addr);		Outputs len characters.
 * long c_expect(long max, char *buffer);	Reads an edited line of input.
 * long c_cr();					Advances to next line.
 * long f_crstr()				Returns file line terminator.
 * long syserror();				Error code from the last
 *	failed system call.
 */

extern void exit_handler();
#ifdef BSD
extern void cont_handler();
extern void stop_handler();
#endif /* BSD */

#ifdef EMACS
char *genvp;
#endif

char *progname;
char sccs_get_cmd[128]; /* sccs get command string */
int uflag = 0; /* controls auto execution of sccs get */
int vflag = 0; /* controls reporting of file names */
int xref_enabled = 0;
int xref_enable_forward_refs = 0;
int show_symbols = 0;
int compile_errors = 0;
int compile_msgs = 0;
int compile_warnings = 0;

/*
 * Execute the MicroEmacs editor.
 */
extern char *emacs_main();
char *fake_argv[] = { "micro-emacs", "dontexit", 0 };
long
emacs(void)
{
#ifdef EMACS
	char *eret;

	eret = emacs_main(2, fake_argv, genvp);
	keymode();
	return ((long)eret);
#endif
}

static char *help_msg =
"Forth [flags] [forth-flags]\n"
"[Flags] may be some of:\n"
"   -h           :  help\n"
"   -d <file>    :  use dictionary <file>\n"
"   -e <Kb>      :  set dictionary extent\n"
"   -L           :  little endian mode"
#ifndef PPC
" (unused)"
#endif
" \n"
"   -D <symbol>  :  define <symbol>, value follows optional =\n"
"   -U <symbol>  :  undefine <symbol>\n"
"   -S           :  show all defined symbols at exit\n"
"   -F           :  enable forward XREF definitions (metacompiler)\n"
"   -u           :  enable SCCS get\n"
"   -v           :  verbose mode\n"
"   -x <file>    :  Xref save to <file>\n"
"\n"
"   Any flag not recognised above terminates the argument parsing; it and\n"
"   all subsequent args will be passed to the forth engine, all forth flags\n"
"   must therefore appear after the wrapper flags\n"
"\n"
"   Example:\n"
"      # forth -e 900 -d ${BP}/fm/kernel/sparc/k32t32.dic -x forth.xref\n"
"\n"
"   Which translates to: Run 32bit forth with 32bit tokens, \n"
"   extend dictionary to 900KB, using forth.xref as the reference index file\n"
"\n";


static void
usage(void)
{
	printf(help_msg);
}

static void
create_xref_symbol(char *name, char *value)
{
	char *tstr;

	tstr = malloc(strlen(name) + strlen(value) + 2);
	/* set the default limit */
	sprintf(tstr, "%s=%s", name, value);
	undef_symbol(name, CMD_UNDEF);
	define_symbol(tstr, CMD_DEFINE);
	free(tstr);
}

int
main(int argc, char *argv[], char *envp)
{
	char *loadaddr;
	long cnt;
	int f, c;
	long dictsize, extrasize, imagesize;
	char *dictend;
	int extrak;
	extern char *optarg;
	extern int optind;
	int little_endian;
	int input_args = 0;
	char *dictfile;
	char *getmem();
	header_t header;
	char **fargv;
	int fargc;
	int extraargs;

	progname = *argv;

#ifdef EMACS
	/*
	 * We only look at the last 5 characters of the name in case
	 * the path name was explicitly specified, e.g. /usr/bin/emacs
	 */
	if ((strlen(progname) >= 5) &&
	    (strcmp(substr(progname, -5, 5), "emacs") == 0)) {
		emacs_main(argc, argv, envp);
		exit(0);
	}
#endif

	opterr = 0;
	vflag = 0;
	extrak = -1;
	dictfile = DEF_EXE;
	little_endian = 0;
	extraargs = 0;
	fargv = malloc(((argc+5) * sizeof (char *)));
	memset(fargv, 0, ((argc+5) * sizeof (char *)));
	fargc = 0;
	fargv[fargc++] = argv[0];

	while ((extraargs == 0) &&
	    ((c = getopt(argc, argv, "he:d:Luvx:X:r:l:D:U:SF")) != EOF))
		switch (c) {

		case 'h':
			usage();
			exit(1);
			break;

		case 'x':
			create_xref_symbol("XREF-FILE", optarg);
#if 0
			fargv[fargc++] = "-x";
#endif
			break;

		case 'e':
			extrak = getnum(optarg);
			input_args |= 2;
			break;

		case 'd':
			dictfile = optarg;
			input_args |= 1;
			break;

		case 'L':
			little_endian = 1;
			break;

		case 'u':
			uflag = 1;
			break;

		case 'v':
			vflag++;
			break;

		case 'D':
			define_symbol(optarg, CMD_DEFINE);
			break;

		case 'U':
			undef_symbol(optarg, CMD_UNDEF);
			break;

		case 'S':
			show_symbols = 1;
			break;

		case 'F':
			xref_enable_forward_refs = 1;
			break;

		default:
			if (extraargs == 0)
				extraargs = optind-1;
			break;
		}

	if (extraargs || (argc - optind)) {
		if (extraargs == 0) extraargs = optind;
		while (extraargs < argc) {
			fargv[fargc++] = argv[extraargs++];
		}
	}
	fargv[fargc] = "";
#if 0
	{
		int i;

		for (i = 0; i < fargc; i++) {
			printf("Farg[%d] = %s\n", i, fargv[i]);
		}
	}
#endif
	if ((input_args & 1) == 0) {
		printf("Warning: falling back to default dictionary: %s\n",
		    dictfile);
	}

	/* Open file for reading */
	if ((f = path_open(dictfile)) < 0) {
		error("forth: Can't open dictionary file ", dictfile);
		exit(1);
	}

#ifdef SCCS
	strcpy(sccs_get_cmd, "sccs ");
	if (getenv("SCCSFLAGS") != NULL)
		strcat(sccs_get_cmd, getenv("SCCSFLAGS"));
	strcat(sccs_get_cmd, " get ");
	if (getenv("SCCSGETFLAGS") == NULL)
		strcat(sccs_get_cmd, " -s");
	else
		strcat(sccs_get_cmd, getenv("SCCSGETFLAGS"));
	strcat(sccs_get_cmd, " ");
#endif SCCS

	/*
	 * Read just the header into a separate buffer,
	 * use it to find the size of text+data+bss, allocate that
	 * much memory plus sizeof(header), copy header to the
	 * new place, then read the rest of the file.
	 */
	if (f_read(f, (char *)&header, (long)sizeof (header)) !=
	    (long)sizeof (header)) {
		error("forth: Can't read dictionary file header", "");
		exit(1);
	}

	/*
	 * Determine the dictionary growth size.
	 * First priority:  command line specification
	 * Second priority: h_blen header field
	 * Default:	    DEF_DICT
	 */
	if (extrak == -1)
		extrasize = header.h_blen ? header.h_blen : DEF_DICT;
	else
		extrasize = (long)extrak * 1024L;

	/* imagesize is the number of bytes to read from the file */

	imagesize = header.h_tlen  + header.h_dlen
	    + header.h_trlen + header.h_drlen;

	/* dictsize is the total amount of dictionary memory to allocate */

	dictsize = sizeof (header) + imagesize +  extrasize;
	dictsize = ROUNDUP(dictsize, DICT_SIZE_ALIGNMENT);

	loadaddr = (char *)getmem(dictsize);

	memcpy(loadaddr, &header, sizeof (header));

	if (f_read(f, loadaddr+sizeof (header), imagesize) != imagesize) {
		error("forth: The dictionary file is too short", "");
		exit(1);
	}

	f_close(f);

	keymode();

#ifdef SIMFORTH
	simulate(sizeof (functions)/sizeof (void *), loadaddr,
	    (long)loadaddr+dictsize, functions,  fargc, fargv);
#else /* SIMFORTH */
	signal(SIGHUP, exit_handler);
	signal(SIGINT, exit_handler);
	signal(SIGILL, exit_handler);
	signal(SIGIOT, exit_handler);
	signal(SIGTRAP, exit_handler);
	signal(SIGFPE, exit_handler);
	signal(SIGEMT, exit_handler);
	signal(SIGBUS, exit_handler);
	signal(SIGSEGV, exit_handler);
	signal(SIGSYS, exit_handler);
#ifdef BSD
	signal(SIGCONT, cont_handler);
	signal(SIGTSTP, stop_handler);
#endif /* BSD */

	s_flushcache();		/* We're about to execute data! */

	/*
	 * Call the Forth interpreter as a subroutine.  If it returns,
	 * exit with its return value as the status code.
	 */
#ifdef PPCSIM
	simulate(0, loadaddr+sizeof (header),
	    loadaddr, functions, ((long)loadaddr+dictsize - 16) & ~15,
	    argc, argv, little_endian);
#else
	s_bye((*(long (*)())(loadaddr+sizeof (header)))
	    (loadaddr, functions, (long)loadaddr+dictsize, fargc, fargv));
#endif
#endif /* SIMFORTH */
}

/*
 * If the input string contains only decimal digits, returns the base 10
 * number represented by that digit string.  Otherwise returns -1.
 */
int
getnum(char *s)
{
	int digit, n;

	for (n = 0; *s; s++) {
		digit = *s - '0';
		if ((digit < 0) || (digit > 9))
			return (-1);
		n = n * 10  +  digit;
	}
	return (n);
}

#ifdef BSD
void
stop_handler(void)
{
	restoremode();
	kill(0, SIGSTOP);
}
void
cont_handler(void)
{
	keymode();
}
#endif /* BSD */

void
exit_handler(int sig)
{
	psignal(sig, "forth");

	if (sig == SIGINT) {
		s_bye(0L);
	} else {
		restoremode();
		kill(0, SIGQUIT);
	}
}

/*
 * Returns true if a key has been typed on the keyboard since the last
 * call to c_key().
 */
long
c_keyques(void)
{
	int nchars = 0;

	fflush(stdout);

#ifdef FreeBSD
	if ((nchars = stdin->_r) == 0) {
		char c[1];
		keyqmode();
		nchars = read(0, c, 1) > 0;
		if (nchars)
			ungetc(c[0], stdin);
	}
#else
#ifdef IRIS
	return (0);
#endif
#endif
	{
		char c[1];
		keyqmode();
		nchars = read(0, c, 1) > 0;
		if (nchars)
			ungetc(c[0], stdin);
	}

	return ((long)nchars);
}

/*
 * Get the next character from the input stream.
 */
/*
 * There is a minor problem under Regulus relating to interrupted system
 * calls.  If the user types the INTERRUPT character (e.g. DEL) while
 * Forth is waiting for input, the read system call will be interrupted.
 * Forth will field the signal thus generated, save the state, and return
 * to the Forth interpreter.  If the user then tries to restart from the
 * saved state, the restarted system call will return 0, which is the same
 * code that is returned for end-of-file.  This is especially nasty when
 * using the Regulus standard-I/O package, because when it see the 0-length
 * read, it set a flag in the stdio file descriptor and returns EOF
 * forevermore.  What we really want to happen is for the read system call
 * to restart cleanly and continue waiting for input, rather than returning
 * 0.
 */

long
c_key(void)
{
	int c;

	keymode();

	fflush(stdout);
	if ((c = getc(stdin)) != EOF)
		return (c);

	s_bye(0L);
}

/*
 * Send the character c to the output stream.
 */
long
c_emit(long c)
{
	putchar((int)c);
	fflush(stdout);
	return (0);
}

/*
 * This routine is called by the Forth system to determine whether
 * its input stream is connected to a file or to a terminal.
 * It uses this information to decide whether or not to
 * prompt at the beginning of a line.  If you are running in an environment
 * where input cannot be redirected away from the terminal, just return 0L.
 */
long
fileques()
{
	return (!isatty(fileno(stdin)));
}

/*
 * Get at least "size" bytes of memory, returning the starting address
 * of the memory.
 */
char *
getmem(size)
	long size;
{
	char *start;

	start = (char *)sbrk(size+DICT_ORIGIN_ALIGNMENT+DICT_HEADER_SIZE);

	if (start == (char *)-1) {
		error("forth: couldn't get memory", "");
		exit(1);
	}
	return ((char *)((ulong_t)
	    ROUNDUP(start+DICT_HEADER_SIZE, DICT_ORIGIN_ALIGNMENT)
	    - DICT_HEADER_SIZE));
}

#include <termios.h>
struct termios ostate;
struct termios lstate;
struct termios kstate;
struct termios kqstate;

#define	M_ORIG 0
#define	M_KEY  1
#define	M_LINE 2
#define	M_KEYQ 3
static lmode = M_ORIG;

void
initline(void)
{
	if (lmode != M_ORIG)
		return;

	tcgetattr(0, &ostate);			/* save old state */

	tcgetattr(0, &lstate);			/* base of line state */
	lstate.c_iflag |= IXON|IXANY|IXOFF;	/* XON/XOFF */
	lstate.c_iflag |= ICRNL;		/* CR/NL munging */
#ifndef FreeBSD
	lstate.c_iflag &= ~(IUCLC);		/* no case folding */
#endif
/* Always turning on ONLCR is safe, but it is a pain in an EMACS window  */
#ifdef notdef
	lstate.c_oflag |=  OPOST|ONLCR;		/* Map NL to CR-LF */
	lstate.c_oflag &= ~(OLCUC);		/* No case folding */
	lstate.c_oflag &= ~(OCRNL|ONLRET);	/* Don't swap cr and lf */
#else
	lstate.c_oflag |=  OPOST;
#endif
	lstate.c_lflag |= ICANON|ECHO;		/* Line editing on */
	lstate.c_cc[VMIN] = 1;			/* Don't hold up input */
	lstate.c_cc[VTIME] = 0;			/* No input delay */

	tcgetattr(0, &kstate);			/* base of key state */
	kstate.c_iflag &= ~(IXON|IXANY|IXOFF);  /* no XON/XOFF */
	kstate.c_iflag &= ~(INLCR|ICRNL);	/* no CR/NL munging */
#ifndef FreeBSD
	kstate.c_iflag &= ~(IUCLC);		/* no case folding */
#endif
/* Always turning on ONLCR is safe, but it is a pain in an EMACS window  */
#ifdef notdef
	kstate.c_oflag |=  OPOST|ONLCR;		/* Map NL to CR-LF */
	kstate.c_oflag &= ~(OLCUC);		/* No case folding */
	kstate.c_oflag &= ~(OCRNL|ONLRET);	/* Don't swap cr and lf */
#else
	kstate.c_oflag |=  OPOST;		/* */
#endif
	kstate.c_lflag &= ~(ICANON|ECHO);	/* No editing characters */
	kstate.c_cc[VMIN] = 1;			/* Don't hold up input */
	kstate.c_cc[VTIME] = 0;			/* No input delay */

	kqstate = kstate;
	kqstate.c_cc[VMIN] = 0;			/* Poll for character */

}

void
linemode(void)
{
	initline();
	if (lmode != M_LINE) {
		tcsetattr(0, TCSANOW, &lstate);
		lmode = M_LINE;
	}
}

void
keyqmode(void)
{
	initline();
	if (lmode != M_KEYQ) {
		tcsetattr(0, TCSANOW, &kqstate);
		lmode = M_KEYQ;
	}
}

void
keymode(void)
{
	initline();
	if (lmode != M_KEY) {
		tcsetattr(0, TCSANOW, &kstate);
		lmode = M_KEY;
	}
}

void
restoremode(void)
{
	initline();
	if (lmode != M_ORIG) {
		tcsetattr(0, TCSANOW, &ostate);
		lmode = M_ORIG;
	}
}

/*
 * Get an edited line of input from the keyboard, placing it at buffer.
 * At most "max" characters will be placed in the buffer.
 * The line terminator character is not stored in the buffer.
 */
long
c_expect(long max, char *buffer)
{
	int c;
	char *p = buffer;

	linemode();

	fflush(stdout);
	while (max-- && ((c = getc(stdin)) != '\n') && (c != EOF))
		*p++ = c;
	if (c == EOF)
		*p++ = '\n';
	keymode();
	return ((long)(p - buffer));
}

/*
 * Send len characters from the buffer at addr to the output stream.
 */
long
c_type(long len, char *addr)
{
	while (len--)
		putchar(*addr++);
	fflush(stdout);
	return (0);
}

/*
 * Sends an end-of-line sequence to the output stream.
 */
long
c_cr(void)
{
	putchar('\n');
	fflush(stdout);
	return (0);
}

/*
 * Returns the end-of-line sequence that is used within files as
 * a packed (leading count byte) string.
 */
long
f_crstr(void)
{
	return ((long)"\1\n");
}

long
s_bye(code)
	long code;
{
	restoremode();
#ifdef SIMFORTH
	simexit();
#endif /* SIMFORTH */
	xref_generate(0);
	finish_symbols(show_symbols);	/* display? */
	finish_symbols(0);		/* force a free if not already done */
	if (compile_msgs || compile_errors) {
		fprintf(stderr,
		    "%s: Compile completed with "
		    "%d messages, %d warnings, %d errors\n",
		    (compile_errors ? "ERROR" : "NOTICE"),
		    compile_msgs, compile_warnings, compile_errors);
	}
	exit((int)(code|compile_errors));
}

/*
 * Display the two strings, followed by an newline, on the error output
 * stream.
 */
void
error(char *str1, char *str2)
{
	write(2, str1, strlen(str1));
	write(2, str2, strlen(str2));
	write(2, "\n", 1);
}


/* Find the error code returned by the last failing system call. */
long
syserror()
{
	extern int errno;

	return ((long)errno);
}

/* Display an error message */

long
pr_error(errnum)
	long errnum;
{
	errno = errnum;
	perror("");
}

long
f_open(char *name, long flag, long mode)
{
	char *expand_name();
	char *sccs_get();

	if (vflag)
		printf("File: %s\n", name);

	name = expand_name(name);
#ifdef SCCS

	if (uflag)
		if (isobsolete(name) == 1)
			s_system(sccs_get(name));
#endif SCCS

	return ((long)open(name, (int)flag, (int)mode));
}

long
f_creat(char *name, long mode)
{
	char *expand_name();

	name = expand_name(name);
	return ((long)open(name, O_RDWR|O_CREAT|O_TRUNC, (int)mode));
}

long
f_read(long fd, char *buf, long cnt)
{
	return (read((int)fd, buf, cnt));
}

long
f_write(long fd, char *buf, long cnt)
{
	return (write((int)fd, buf, cnt));
}

long
f_close(long fd)
{
	extern int close();

	return ((long)close((int)fd));
}

long
f_unlink(char *name)
{
	extern int unlink();

	return ((long)unlink(name));
}

long
f_lseek(long fd, long offset, long flag)
{
	extern long lseek();

	return (lseek((int)fd, offset, (int)flag));
}

long
f_ioctl(long fd, long code, char *buf)
{
	return ((long)ioctl((int)fd, (int)code, buf));
}

long
s_signal(long signo, void (*adr)())
{
	return ((long)signal((int)signo, (void (*)())adr));
}

long
s_system(char *str)
{
	int i;
	linemode();
	i = system(str);
	keymode();

	return ((long)i);
}

long
s_chdir(char *str)
{
	return ((long)chdir(str));
}

long
s_getwd(char *buf)
{
	return ((long)getcwd(buf, MAXPATHLEN));
}

#ifdef SYS5
#define	bzero(b, n) (void *)memset(b, 0, n)
#endif SYS5
long
m_alloc(long size)
{
	long r;

#ifdef PPCSIM
	size = (size+7) & ~7;
#endif
	r = (long)malloc(size);
	if (r) bzero((char *)r, size);
	return (r);
}

/* ARGSUSED */
long
m_free(long size, char *adr)
{
	free(adr);
}

long
f_init(void)
{
	UNIMPL(f_init);
}

long
f_op(void)
{
	UNIMPL(f_op);
}

long
f_move(void)
{
	UNIMPL(f_move);
}

long
f_rows(void)
{
	UNIMPL(f_rows);
}

long
f_cols(void)
{
	UNIMPL(f_cols);
}

long
m_sbrk(long size)
{
	return ((long)sbrk(size));
}

long
c_getenv(char *str)
{
	return ((long)getenv(str));
}

long
today(void)
{
	long tadd;
	extern struct tm *localtime();

	time(&tadd);
	return ((long)localtime(&tadd));
}

long
timez(void)
{
#ifdef BSD
	static struct timeval t;
	static struct timezone tz;
	extern int gettimeofday();

	gettimeofday(&t, &tz);
	return ((long)tz.tz_minuteswest);
#endif
#ifdef SYS5
	time_t clock;

	tzset();
	return (timezone/60);
#endif
#ifdef MINIWRAPPER
	return ((long)480);	/* Assume PST */
#endif
}

/* Return a string representing the name of the time zone */
long
timezstr(void)
{
	return ((long)"");	/* Regulus doesn't seem to have this */
}

/*
 * Flush the data cache if necessary and possible.  Used after writing
 * instructions into the dictionary.
 */
long
s_flushcache()
{
#ifdef NeXT
	asm("trap #2");
#endif
}

/*
 * Tries to open the named file looking in each directory of the
 * search path specified by the environment variable FTHPATH.
 * Returns file descriptor or -1 if not found
 */
char    fnb[300];
int
path_open(char *fn)
{
	static char *path;
	register char *dp;
	int fd;
	register char  *lpath;

	if (fn == NULL)
		return (-1);

	if (path == NULL) {
		path = getenv("FTHPATH");
		if (path == NULL) {
			path = getenv("FPATH");
		}
	}
	if (path == NULL)
		path = DEF_FPATH;

	lpath = (*fn == '/') ? "" : path;
	do {
		dp = fnb;
		while (*lpath && *lpath != ':')
			*dp++ = *lpath++;
		if (dp != fnb)
			*dp++ = '/';
		strcpy(dp, fn);
		fd = open(fnb, 0);
		if (fd >= 0)
			return (fd);
	} while (*lpath++);
	fd = open(fn, 0);
	if (fd >= 0)
		return (fd);
	return (-1);
}

executable(char *filename)	/* True if file is executable */
{
	struct stat stbuf;

	return ((stat(filename, &stbuf) == 0) &&
	    ((stbuf.st_mode & S_IFMT) == S_IFREG) &&
	    (access(filename, 1) == 0));
}

/* Find fname for symbol table  */
long
pathname(void)
{
	static char buf[256];
	char *cp, *cp2;

	cp = getenv("PATH");
	if (cp == NULL)
		cp = DEF_PATH;
	if ((*cp == ':') || (*progname == '/')) {
		cp++;
		if (executable(progname)) {
			strcpy(buf, progname);
			return ((long)buf);
		}
	}
	while (*cp) {
		/* copy over current directory and then append progname */
		cp2 = buf;
		while ((*cp != 0) && (*cp != ':')) {
			*cp2++ = *cp++;
		}
		*cp2++ = '/';
		strcpy(cp2, progname);
		if (*cp) cp++;
		if (!executable(buf)) continue;
		return ((long)buf);
	}
	strcpy(buf, progname);
	return ((long)buf);
}

char *
substr(char *str, int pos, int n)
{
	int len = strlen(str);
	static char outstr[128];

	if (pos < 0)
		pos += len+1;
	if (pos <= 0)
		pos = 1;
	if (n < 0)
		n += len;
	if (pos + n - 1 > len) {
		n = len + 1  - pos;
		if (n < 0)
		    n = 0;
	}
	strncpy(outstr, str + pos - 1, n);
	outstr[n] = '\0';

	return (outstr);
}

#ifdef SCCS

char *
sccs_name(char *name)
{
	static char sccsname[512];
	char *p;
	int dirlen;

	/* Find the beginning of the last filename component */

	if ((p = strrchr(name, '/')) == NULL)
		p = name;
	else
		p++;

	dirlen = p - name;

	strcpy(sccsname, name);			/* Copy whole path */
	strcpy(sccsname+dirlen, "SCCS/s.");	/* Merge in "SCCS/s." */
	strcat(sccsname, p);			/* Put filename back */

	return (sccsname);

}

/*
 * file | SCCS | obsolete (return value)
 * -----+------+------------------------
 *    Y   |  Y   |    ?     (SCCS > file)
 *    N   |  Y   |    Y          (1)
 *    Y   |  N   |    N          (0)
 *    N   |  N   |    Error      (-1)
 */
int
isobsolete(char *name)
{
	struct stat status, sccsstatus;
	int file, sccsfile;

	file = stat(name, &status);
	sccsfile = stat(sccs_name(name), &sccsstatus);

	/* If the file is missing, it is deemed "obsolete" */
	if (file == -1) {
		if (sccsfile == -1)
			return (-1);	/* Both file and SCCS file missing */
		else
			return (1);	/* file missing, SCCS file is there */
	}
	if (sccsfile == -1)
		return (0);		/* file is there, no SCCS file */
	else				/* Both exist, compare times */
		return ((sccsstatus.st_mtime > status.st_mtime) ? 1 : 0);
}

char *
sccs_get(char *name)
{
	static char str[512];

	strcpy(str, sccs_get_cmd);
	strcat(str, name);
	strcat(str, " -G");
	strcat(str, name);
	return (str);
}

#endif SCCS

char *
expand_name(char *name)
{
	char envvar[64], *fnamep, *envp, paren;
	static char fullname[256];
	int ndx = 0;

	fnamep = name;
	fullname[0] = '\0';

	if (*fnamep == '$') {
		fnamep++;
		if ((*fnamep == '{') || (*fnamep == '(')) {
			/* multi char env variable */
			if (*fnamep == '{')
				paren = '}';
			else
				paren = ')';
			fnamep++;

			envvar[ndx++] = *(fnamep++);

			while ((*fnamep != paren) && (ndx < 64) &&
			    (*fnamep != '\0')) {
				envvar[ndx++] = *(fnamep++);
			}
			if (*fnamep == paren) {
				fnamep++;
			} else {
				ndx = 0;
				fnamep = name;
			}
		} else {
			/* single char env. var. */
			envvar[ndx++] = *(fnamep++);
		}
		envvar[ndx] = '\0';

		if (ndx > 0 && (envp = getenv(envvar)) != NULL) {
			strcpy(fullname, envp);
			strcat(fullname, fnamep);
			return (fullname);
		} else {
			printf("Can't find environment variable %s in %s\n",
			    envvar, name);
		}
	}
	return (fnamep);
}

#ifdef SIMFORTH
long
find_next(int tshift, int token_size, int origin, char *link, char *str)
{
	int len, nextlen;
	char *namep;
	char *p = str;

	len = strlen(p);

	if (tshift == 0)
	    link = (char *)((*(unsigned long *)(link)) +(origin));
	else
	    link = (char *)((*(unsigned short *)(link) << tshift) +(origin));

	while (link != (char *)origin) {
		p = str;
		namep = link - token_size - 1;
		nextlen = (*namep) & 0x1f;
		namep = namep - nextlen;
		if (len == nextlen)
			while (nextlen--)
				if (*(namep++) != *(p++))
					break;
		if (nextlen == -1)
			return (((long)link)-token_size);

		if (tshift == 0)
			link = (char *)((*(unsigned long *)(link-token_size))
			    +(origin));
		else
			link = (char *)((*(unsigned short *)(link-token_size)
			    << tshift) +(origin));
	}

	return (0);
}
#endif /* SIMFORTH */

long
stack_syscall(long p)
{
	extern fstackp ((*sfunctions[])(fstackp));
	int fsyscall;
	fstackp stack = (fstackp)p;
#if 1
	fsyscall = POP(stack);
#if 0
	printf("fsyscall: %x\n", fsyscall);
	printf("fptr: %x\n", sfunctions[fsyscall]);
#endif
	return ((long)((sfunctions[fsyscall])(stack)));
#else
	int a, b, c;

	a = POP(stack);
	b = POP(stack);
	c = POP(stack);
	printf("tos = %x, tos-1 = %x, tos-2 = %x\n", a, b, c);
	PUSH(a+1, stack);
	PUSH(b+1, stack);
	PUSH(c+1, stack);
	return ((long)stack);
#endif
}
