/*
* ========== Copyright Header Begin ==========================================
*
* Hypervisor Software File: fsys.c
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
 * @(#)fsys.c 1.3 03/08/20
 * Copyright 1985-1994 Bradley Forthware
 * Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
 * Copyright Use is subject to license terms.
 *
 * this file contains the routines that have the same function as
 * those in wrapper.c, except that they use the forth stack to take and
 * return arguments, effectively they are wrapper additions to the
 * forth engine hooked into the machine using the same vector interface
 * as wrapper.c.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <strings.h>

#ifdef DLOPEN
#include <dlfcn.h>
#include <link.h>
#endif

#include <sys/types.h>
#include <sys/time.h>
#include <sys/param.h>
#include <sys/stat.h>

#include <signal.h>
#include <termios.h>

#include "wrapper.h"
#include "xref_support.h"
#include "defines.h"

#define	FPROTO(x)	static fstackp x(fstackp stack)
#define	UNIMPL(xx)	printf("%s:%d: Unimplemented syscall " #xx "\n", \
    __FILE__, __LINE__); \
    return (stack)

extern char *substr();
extern void s_bye(long code);

extern int	errno;		/* Wherever the error code goes */

struct termios ostate;
struct termios lstate;
struct termios kstate;
struct termios kqstate;

#define	M_ORIG 0
#define	M_KEY  1
#define	M_LINE 2
#define	M_KEYQ 3
static lmode = M_ORIG;

static fstackp
pop_fstring(fstackp stack, char **buf, int *len)
{
	char *fstr;
	*len = POP(stack);
	fstr = (char *)POP(stack);
	if (*len) {
		*buf = malloc(*len+1);
		strncpy(*buf, fstr, *len);
		(*buf)[*len] = 0;
		*len++;
	} else {
		*buf = NULL;
	}
	return (stack);
}

static fstackp
push_cstring(fstackp stack, char *buf, int len)
{
	PUSH(len, stack);
	PUSH(buf, stack);
	return (stack);
}

static void
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

static void
linemode(void)
{
	initline();
	if (lmode != M_LINE) {
		tcsetattr(0, TCSANOW, &lstate);
		lmode = M_LINE;
	}
}

static void
keyqmode(void)
{
	initline();
	if (lmode != M_KEYQ) {
		tcsetattr(0, TCSANOW, &kqstate);
		lmode = M_KEYQ;
	}
}

static void
keymode(void)
{
	initline();
	if (lmode != M_KEY) {
		tcsetattr(0, TCSANOW, &kstate);
		lmode = M_KEY;
	}
}

static void
restoremode(void)
{
	initline();
	if (lmode != M_ORIG) {
		tcsetattr(0, TCSANOW, &ostate);
		lmode = M_ORIG;
	}
}

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

extern char *progname;
extern char sccs_get_cmd[128]; /* sccs get command string */
extern int uflag;
extern int vflag;
extern int xref_enabled;
extern int show_symbols;

/*
 * Returns true if a key has been typed on the keyboard since the last
 * call to c_key().
 */
FPROTO(c_keyques)
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

	PUSH(nchars, stack);
	return (stack);
}

FPROTO(f_bye)
{
	int status;

	status = POP(stack);
	s_bye(status);
	return (stack);
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

FPROTO(c_key)
{
	int c;

	keymode();

	fflush(stdout);
	if ((c = getc(stdin)) != EOF) {
		PUSH(c, stack);
		return (stack);
	}
	s_bye(0L);
	return (NULL);
}

/*
 * Send the character c to the output stream.
 */
FPROTO(c_emit)
{
	int c;

	c = (int)POP(stack);
	putchar(c);
	fflush(stdout);
	return (stack);
}

/*
 * This routine is called by the Forth system to determine whether
 * its input stream is connected to a file or to a terminal.
 * It uses this information to decide whether or not to
 * prompt at the beginning of a line.  If you are running in an environment
 * where input cannot be redirected away from the terminal, just return 0L.
 */
FPROTO(fileques)
{
	int status = !isatty(fileno(stdin));
	PUSH(status, stack);
	return (stack);
}

/*
 * Get an edited line of input from the keyboard, placing it at buffer.
 * At most "max" characters will be placed in the buffer.
 * The line terminator character is not stored in the buffer.
 */
FPROTO(c_expect)
{
	int c;
	long max;
	char *buffer;
	char *p;

	max = POP(stack);
	buffer = (char *)POP(stack);

	p = buffer;
	linemode();

	fflush(stdout);
	while (max-- && ((c = getc(stdin)) != '\n') && (c != EOF))
		*p++ = c;
	if (c == EOF)
		*p++ = '\n';
	keymode();

	PUSH((p-buffer), stack);
	return (stack);
}

/*
 * Send len characters from the buffer at addr to the output stream.
 */
FPROTO(c_type)
{
	long len;
	char *addr;

	len = POP(stack);
	addr = (char *)POP(stack);

	while (len--)
		putchar(*addr++);
	fflush(stdout);

	return (stack);
}

/*
 * Sends an end-of-line sequence to the output stream.
 */
FPROTO(c_cr)
{
	putchar('\n');
	fflush(stdout);
	return (stack);
}

/*
 * Returns the end-of-line sequence that is used within files as
 * a packed (leading count byte) string.
 */
FPROTO(f_crstr)
{
	char crstr[2] = { 0x01, '\n' };
	PUSH(crstr, stack);
	return (stack);
}

/* Find the error code returned by the last failing system call. */
FPROTO(syserror)
{
	PUSH(errno, stack);
	return (stack);
}

/* Display an error message */

FPROTO(pr_error)
{
	errno = POP(stack);
	perror("");
	return (stack);
}

FPROTO(f_open)
{
	char *name;
	int flag;
	mode_t mode;
	int status;

	mode = (mode_t)POP(stack);
	flag = (int)POP(stack);
	name = (char *)POP(stack);
	name = expand_name(name);

#ifdef SCCS
	if (uflag)
		if (isobsolete(name) == 1)
			system(sccs_get(name));
#endif SCCS
	if (vflag)
		printf("File: %s\n", name);

	status = open(name, flag, mode);
	return (stack);
}

FPROTO(f_creat)
{
#if 0
	(char *name, long mode)
	name = expand_name(name);

	return ((long)open(name, O_RDWR|O_CREAT|O_TRUNC, (int)mode));
#endif
	return (stack);
}

/* f_read ( fd buf len -- #bytes ) */
FPROTO(f_read)
{
	int fd;
	char *buf;
	size_t len;
	ssize_t bytes;

	len = POP(stack);
	buf = (char *)POP(stack);
	fd = POP(stack);
	bytes = read(fd, buf, len);
	PUSH(bytes, stack);
	return (stack);
}

/* f_write ( fd adr len -- #written ) */
FPROTO(f_write)
{
	int fd;
	char *buf;
	size_t len;
	ssize_t bytes;

	len = POP(stack);
	buf = (char *)POP(stack);
	fd = POP(stack);

	bytes = write(fd, buf, len);
	PUSH(bytes, stack);
	return (stack);
}

FPROTO(f_close)
{
	int fd, status;

	fd = POP(stack);
	status = close(fd);
	return (stack);
}

/* unlink ( str,len -- ok? ) */
FPROTO(f_unlink)
{
	int len;
	char *buffer;
	char *path;
	int status;

	stack = pop_fstring(stack, &path, &len);
#if 0
	status = unlink(path);
#else
	printf("UNLINK: %s\n", path);
#endif
	free(path);
	PUSH(status, stack);
	return (stack);
}

/* f_seek ( fd offset whence -- ) */
FPROTO(f_lseek)
{
	int fd;
	off_t offset;
	int whence;
	off_t status;

	whence = POP(stack);
	offset = POP(stack);
	fd = POP(stack);

	status = lseek(fd, offset, whence);

	PUSH(status, stack);
	return (stack);
}

FPROTO(f_ioctl)
{
	int fd;
	char *buf;
	int code;
	int status;

	buf = (char *)POP(stack);
	code = POP(stack);
	fd = POP(stack);

	status = ioctl(fd, code, buf);
	PUSH(status, stack);
	return (stack);
}

FPROTO(s_signal)
{
	void (*disp)(int);
	int sig;
	void (*prev)(int);

	disp = (void (*)())POP(stack);
	sig = POP(stack);
	prev = signal(sig, disp);
	PUSH(prev, stack);
	return (stack);
}

FPROTO(s_system)
{
	int len, status;
	char *buf;
	char *sbuf;

	stack = pop_fstring(stack, &sbuf, &len);

	linemode();
	status = system(sbuf);
	keymode();
	free(sbuf);

	PUSH(status, stack);
	return (stack);
}

/* chdir ( str,len -- ok? ) */
FPROTO(s_chdir)
{
	int len, status;
	char *buf;
	char *sbuf;

	stack = pop_fstring(stack, &sbuf, &len);
	status = chdir(sbuf);
	free(sbuf);

	PUSH(status, stack);
	return (stack);
}

/* getwd ( -- str,len ) */
FPROTO(s_getwd)
{
	char *buf, *sbuf;
	int len;

	buf = malloc(MAXPATHLEN+1);
	sbuf = getwd(buf);
	if (sbuf != NULL) {
		len = strlen(buf);
		sbuf = strdup(buf);
		free(buf);
		buf = sbuf;
	} else {
		free(buf);
		len = 0;
	}
	PUSH(buf, stack);
	PUSH(len, stack);
	return (stack);
}

/* alloc ( len -- buf ) */
FPROTO(m_alloc)
{
	size_t size;
	void *buf;

#ifdef PPCSIM
	size = (size+7) & ~7;
#endif
	buf = malloc(size);
	if (buf != NULL)
		memset(buf, 0, size);

	PUSH(buf, stack);
	return (stack);
}

/* free ( adr,len -- ) */
FPROTO(m_free)
{
	int len;
	char *buf;

	len = POP(stack);
	buf = (char *)POP(stack);
	free(buf);
	return (stack);
}

/* sbrk ( size -- va ) */
FPROTO(m_sbrk)
{
	intptr_t size;
	void *ptr;

	size = POP(stack);
	ptr = sbrk(size);
	PUSH(ptr, stack);
	return (stack);
}

#ifndef DLOPEN
FPROTO(f_dlopen)
{
	UNIMPL(f_dlopen);
}

FPROTO(f_dlclose)
{
	UNIMPL(f_dlclose);
}

FPROTO(f_dlsym)
{
	UNIMPL(f_dlsym);
}

FPROTO(f_dlerror)
{
	UNIMPL(f_dlerror);
}
#else
/* dlopen ( str,len mode -- handle ) */
FPROTO(f_dlopen)
{
	int mode;
	int len;
	char *lib;
	void *handle;

	mode = POP(stack);
	stack = pop_fstring(stack, &lib, &len);

	handle = dlopen(lib, mode);
	free(lib);
	PUSH(handle, stack);
	return (stack);
}

/* dlclose ( handle -- ) */
FPROTO(f_dlclose)
{
	void *handle;
	handle = (void *)POP(stack);
	dlclose(handle);
	return (stack);
}

/* dlerror ( -- str,len ) */
FPROTO(f_dlerror)
{
	int len;
	char *err = dlerror();

	if (err != NULL) {
		stack = push_cstring(stack, err, strlen(err));
	} else {
		stack = push_cstring(stack, err, 0);
	}
	return (stack);
}

/* dlsym ( str,len handle -- ptr ) */
FPROTO(f_dlsym)
{
	void *handle, *symptr;
	char *sym;
	int len;

	handle = (void *)POP(stack);
	stack = pop_fstring(stack, &sym, &len);
	symptr = dlsym(handle, sym);
	free(sym);
	PUSH(symptr, stack);
	return (stack);
}
#endif

/* getenv ( str,len -- buf,len ) */
FPROTO(c_getenv)
{
	int len, blen;
	char *cstr, *sbuf, *buf;

	stack = pop_fstring(stack, &sbuf, &len);
	buf = getenv(sbuf);
	free(sbuf);
	if (buf == NULL) {
		blen = 0;
	} else {
		blen = strlen(buf);
	}
	PUSH(buf, stack);
	PUSH(blen, stack);
	return (stack);
}

FPROTO(today)
{
	long tadd;

	time(&tadd);
	PUSH(localtime(&tadd), stack);
	return (stack);
}

FPROTO(timez)
{
	UNIMPL(timez);
}

FPROTO(timezstr)
{
	UNIMPL(timezstr);
}

/*
 * Flush the data cache if necessary and possible.  Used after writing
 * instructions into the dictionary.
 */
FPROTO(s_flushcache)
{
#ifdef NeXT
	asm("trap #2");
#endif
	UNIMPL(s_flushcache);
}

FPROTO(f_init)
{
	UNIMPL(f_init);
}

FPROTO(f_op)
{
	UNIMPL(f_op);
}

FPROTO(f_move)
{
	UNIMPL(f_move);
}

FPROTO(f_rows)
{
	UNIMPL(f_rows);
}

FPROTO(f_cols)
{
	UNIMPL(f_cols);
}

FPROTO(pathname)
{
	UNIMPL(pathname);
}

#ifdef SIMFORTH
FPROTO(find_next)
{
	int shift = POP(stack);
	int token_size = POP(stack);
	int origin = POP(stack);
	char *link = (char *)POP(stack);
	char *str = (char *)POP(stack);
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
		if (nextlen == -1) {
			PUSH((((long)link)-token_size), stack);
			return (stack);
		}

		if (tshift == 0)
			link = (char *)((*(unsigned long *)(link-token_size))
			    +(origin));
		else
			link = (char *)((*(unsigned short *)(link-token_size)
			    << tshift) +(origin));
	}

	PUSH(0, stack);
	return (stack);
}
#endif /* SIMFORTH */

/* save-image ( up,len origin,len name,len -- ) */
FPROTO(save_image)
{
	char *fname;
	uchar_t *upaddr, *dicaddr;
	int flen, ulen, dlen;
	FILE *file;

	stack = pop_fstring(stack, &fname, &flen);
	dlen = POP(stack);
	dicaddr = (uchar_t *)POP(stack);
	ulen = POP(stack);
	upaddr = (uchar_t *)POP(stack);

	file = fopen(fname, "wb");
	if (file == NULL) {
		fprintf(stderr, "save_image: failed to create %s\n",
		    fname);
		return (stack);
	}
	fwrite(dicaddr, 1, dlen, file);
	fwrite(upaddr, 1, ulen, file);
	fclose(file);
	return (stack);
}

static include_file_t *includes = NULL;

/* include ( str,len -- str,len ) */
FPROTO(includefile)
{
	include_file_t *newfile;
	FILE *fd;
	char *cname, *name;
	char *fname;
	int len;
	fstackp current;

	(void) pop_fstring(stack, &cname, &len);

	name = expand_name(cname);

#ifdef SCCS
	if (uflag)
		if (isobsolete(name) == 1)
			system(sccs_get(name));
#endif
	/*
	 * open the file, using SCCS if required
	 */
	fd = fopen(name, "r");
	if (fd == NULL) {
		printf("failed to open %s\n", name);
	}
	newfile = malloc(sizeof (include_file_t));
	if (newfile == NULL) {
		printf("Malloc failed for include file: %s\n", name);
		exit(1);
	}
	newfile->next = includes;
	newfile->linenum = 0;
	newfile->name = strdup(name);
	newfile->fd = fd;
	includes = newfile;
	if (vflag) {
		printf("File: %s\n", name);
	}
	free(cname);
	return (current);
}

/* bootstrap ( str,len -- buf,len ) */
FPROTO(bootstrap)
{
	int fd;
	char *cname, *name;
	struct stat sbuf;
	int flen, len;
	char *fname, *buffer;

	stack = pop_fstring(stack, &cname, &len);
	if (len == 0) {
		buffer = NULL;
		goto error;
	}
	name = expand_name(cname);

	printf("Bootstrap: %s (%s)\n", cname, name);
#ifdef SCCS
	if (uflag)
		if (isobsolete(name) == 1)
			system(sccs_get(name));
#endif

	/*
	 * open the file, using SCCS if required
	 */
	fd = open(name, O_RDONLY);
	if (fd < 0) {
		printf("failed to open bootstrap file %s\n", name);
		buffer = NULL;
		goto error;
	}
	fstat(fd, &sbuf);
	buffer = malloc(sbuf.st_size+1);
	if (buffer == NULL) {
		printf("Malloc failed for bootstrap file: %s\n", name);
		buffer = NULL;
		goto error;
	}
	len = read(fd, buffer, sbuf.st_size);
	buffer[len] = 0;
	close(fd);
	if (len != sbuf.st_size) {
		printf("Short read on bootstrap file %s\n", name);
		free(buffer);
		buffer = NULL;
		len = 0;
		goto error;
	} else {
		if (vflag > 1) {
			printf("Bootstrapped: %s [%d bytes]\n",
			    name, sbuf.st_size);
		}
	}
error:
	if (cname != NULL)
		free(cname);
	PUSH(buffer, stack);
	PUSH(len, stack);
	return (stack);
}

/*
 * xref_symbol ( str,len  line# state -- str,len  )
 *   state:
 *	0	symbol_reference
 *	1	symbol_definition
 *	2	smybol_hide
 *	3	symbol_reveal
 *	4	string content
 */
FPROTO(xref_symbol)
{
	int state;
	int len;
	char *name;
	char *fnname = NULL;
	int line;
	state = POP(stack);

#ifdef SHOWREFS
#define	RPRINTF(x)	printf x
#else
#define	RPRINTF(x)
#endif

	if (xref_enabled) {
		switch (state) {
		case 0:
			line = POP(stack);
			pop_fstring(stack, &fnname, &len);
			RPRINTF(("ref: %s\n", fnname));
			xref_add_symbol_reference(fnname, line);
			break;

		case 1:
			line = POP(stack);
			pop_fstring(stack, &fnname, &len);
			RPRINTF(("define: %s\n", fnname));
			xref_add_symbol_definition(fnname, line);
			break;

		case 2:
			pop_fstring(stack, &fnname, &len);
			RPRINTF(("hide: %s\n", fnname));
			xref_modify_symbol_definition(fnname, 0);
			break;

		case 3:
			pop_fstring(stack, &fnname, &len);
			RPRINTF(("reveal: %s\n", fnname));
			xref_modify_symbol_definition(fnname, 1);
			break;

		case 4:
			line = POP(stack);
			pop_fstring(stack, &fnname, &len);
			RPRINTF(("string: %s\n", fnname));
			xref_add_string(fnname, len, line);
			break;

		default:
			printf("%s:%d: xref_symbol invalid state %d\n",
			    __FILE__, __LINE__, state);
			break;
		}
		if (fnname != NULL)
			free(fnname);
	}
	return (stack);
}

/* xref-file ( [name,len,-1 -- name,len] | [ 0 -- ] ) */
FPROTO(xref_file)
{
	int state;
	int len;
	char *name;
	char *fname = NULL;

	state = POP(stack);
	if (state) {
		/*
		 * We dont actually pop the stack though..
		 */
		pop_fstring(stack, &fname, &len);
#if 0
		printf("Pushing.. %s\n", fname);
#endif
	}

	if ((xref_enabled) || 1) {
		if (state) {
			xref_add_file_reference(fname);
		} else {
			xref_remove_file_reference();
		}
	}
	if (fname != NULL)
		free(fname);
	return (stack);
}

/* xref_trigger ( state -- ) */
FPROTO(xref_trigger)
{
	int what;
	char *symbol;
	char *preload;
	extern int xref_enable_forward_refs;

	what = POP(stack);
	switch (what) {
	case 0:
		/*
		 * Xref Off
		 * Flush the xref-file to disk.
		 */
		if (xref_enabled)
			xref_generate(1);
		xref_enabled = 0;
		break;

	case 1:
		/*
		 * Xref On
		 */
		symbol = "XREF-FILE";
		if (symbol_defined(symbol)) {
			xref_enabled = 1;
		}
		break;

	case -1:
		/*
		 * Init; extract the xref variables from the symbol table.
		 */
		symbol = "XREF-FILE";
		if (symbol_defined(symbol)) {
			char *symdata = extract_symbol(symbol);
			char *preload = extract_symbol("XREF-PRELOAD");
			xref_init(symdata, preload, xref_enable_forward_refs);
			PUSH(-1, stack);
		} else {
			PUSH(0, stack);
		}
		break;

	default:
		printf("%s:%d Unexpected Xref trigger\n", __FILE__, __LINE__);
		break;
	}
	return (stack);
}

/* xref_stat ( -- ) */
FPROTO(xref_stat)
{
	printf("Xref enabled?: %d\n", xref_enabled);
	xref_status();
	return (stack);
}

/* symbol-set ( data,dlen symbol,len create? -- ) */
FPROTO(symbol_set)
{
	int create;
	int slen;
	char *sname;
	int dlen;
	char *data;
	char *symbol;

	create = POP(stack);
	stack = pop_fstring(stack, &symbol, &slen);
	if (create) {
		stack = pop_fstring(stack, &data, &dlen);
		if (dlen) {
			char cstr[256];

			snprintf(cstr, sizeof (cstr), "%s=%s", symbol, data);
			free(data);
			free(symbol);
			symbol = strdup(cstr);
		}
		define_symbol(symbol, FORTH_DEFINE);
	} else {
		undef_symbol(symbol, FORTH_UNDEF);
	}
	free(symbol);
	return (stack);
}

/* symbol-exists( symbol,len -- exists? ) */
FPROTO(symbol_exists)
{
	int slen;
	char *symname;
	char *symbol;
	int defined;
	int invert = 0;

	stack = pop_fstring(stack, &symbol, &slen);
	symname = symbol;
	if (symname[0] == '!') {
		symname++;
		invert = 1;
	}
	defined = symbol_defined(symname);
	if (invert) {
		defined = !defined;
	}
	free(symbol);
	PUSH(defined, stack);
	return (stack);
}

/* symbol-value( symbol,len -- value,len ) */
FPROTO(symbol_value)
{
	int slen;
	int invert = 0;
	char *symname;
	char *symbol;
	char *value;
	char *symdata;

	stack = pop_fstring(stack, &symname, &slen);
	symbol = symname;
	if (symname[0] == '!') {
		symbol++;
		invert = 1;
	}
	if (symbol_defined(symbol)) {
		symdata = extract_symbol(symbol);
		if (symdata == NULL) {
			symdata = (char *)&slen;
			slen = 0;
		} else {
			slen = strlen(symdata);
		}
		if (invert) {
			symdata = NULL;
			slen = 0;
		}
	} else {
		symdata = NULL;
		if (invert) {
			symdata = (char *)&slen;
		}
		slen = 0;
	}
	free(symname);
	PUSH(symdata, stack);
	PUSH(slen, stack);
	return (stack);
}

FPROTO(stack_syscall)
{
	long tos;
	int i;

	tos = POP(stack);
	printf("Tos: %x\n", tos);
	PUSH(1, stack);
	PUSH(2, stack);

	return (stack);
}

FPROTO(compile_info)
{
	extern int compile_msgs;
	compile_msgs++;
	return (stack);
}

FPROTO(compile_abort)
{
	extern int compile_errors;
	compile_errors++;
	return (stack);
}

FPROTO(compile_warn)
{
	extern int compile_warnings;
	compile_warnings++;
	return (stack);
}

/*
 * Now the function table.
 */
fstackp ((*sfunctions[])(fstackp)) = {
	/* 0		1					*/
	c_key,		c_emit,

	/* 2		3		4		5	*/
	f_open,		f_creat,	f_close, 	f_read,

	/* 6		7		8			*/
	f_write,	f_ioctl,	c_keyques,

	/* 9		10		11		12	*/
	f_bye,		f_lseek,	f_unlink,	fileques,

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
	s_flushcache,	pr_error,	0,

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
	f_dlopen,	f_dlsym,	f_dlerror,	f_dlclose,

	/* 44							*/
#ifdef SIMFORTH
	find_next,
#else
	0,
#endif
	/* 45,		, 46		, 47		, 48	*/
	save_image,	bootstrap,	 includefile,	0,

	/* 49,		50		51		, 52	*/
	xref_symbol,	xref_file,	xref_trigger, 	xref_stat,

	/* 53,		54,		55,			*/
	symbol_set,	symbol_exists,	symbol_value,

	/* 56							*/
	stack_syscall,

	/* 57		58,		59,		60	*/
	compile_info,	compile_abort,	compile_warn,	0,
#endif
	/* EOT 							*/
	0
};
