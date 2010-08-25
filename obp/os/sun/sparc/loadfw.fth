id: @(#)loadfw.fth 1.20 06/02/07
purpose: Load file for base firmware - no platform specifics
copyright: Copyright 1994 Firmworks  All Rights Reserved
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

transient
\ 
\ macros are a 'simple' forth routine that will be unrolled into a caller
\ this sacrifices dictionary spaces for performance so don't over use them.
\ the termination for the copy is an 'unnest' so you must be very careful
\ macros are for simple routines where the execution cost of a subroutine
\ and return are a significant portion of the over execution time.
\ 
\ The way this works is:
\ 
\	transient
\	: my-unrolled-2dup over over ;
\	resident
\	macro: 2dup-macro my-unrolled-2dup
\ 
\	: xxx 2dup-macro ;
\ 
\	see xxx
\	: xxx
\		over over
\	;
\
: macro: \ name$ expansion-routine
   transient create immediate ' , resident does>
   @ >body begin
      dup token@ ['] unnest over <> while
         token, /token +
   repeat 2drop
;
resident

fload ${BP}/os/bootprom/sysintf.fth     \ Interfaces to system functions
fload ${BP}/os/bootprom/loaddevt.fth	\ Device tree and other OBP routines

fload ${BP}/arch/sun/cmn-msg-format.fth \ Common mesage framework

\ fload ${BP}/cpu/sparc/centry.fth	\ Now initialize the CIF handler

\ Interfaces for user created environment variables
fload ${BP}/pkg/confvar/interfaces/user-vars.fth 

fload ${BP}/os/bootprom/clientif.fth	\ Client interface

fload ${BP}/os/bootprom/canon.fth	\ canon client-services function

defer mac-address  ' system-mac-address to mac-address

fload ${BP}/os/bootprom/regwords.fth

fload ${BP}/os/bootprom/release.fth

fload ${BP}/pkg/fcode/loadfcod.fth	\ S Fcode interpreter

: (callback-call ( cb-array cb-vector -- result )  call nip  ;
' (callback-call is callback-call

fload ${BP}/os/bootprom/allocsym.fth	\ Allocate memory for symbol table
fload ${BP}/os/sun/symcif.fth		\ Symdebug Client Service
fload ${BP}/os/sun/symdebug.fth		\ Unix symbol table routines

fload ${BP}/os/sun/elfdebug.fth

64\ fload ${BP}/os/sun/elf64.fth
64\ fload ${BP}/os/sun/elfdbg64.fth

stand-init:  Init lock primitives
   ['] (lock[ is lock[ 
   ['] (]unlock is ]unlock
;

fload version.fth			\ Declares the firware version
fload ${BP}/os/bootprom/showvers.fth	\ Display firmware version

32\ fload ${BP}/cpu/sparc/fpu.fth
64\ fload ${BP}/cpu/sparc/fpu9.fth

64\ fload ${BP}/pkg/fcode/sparc/fcode32.fth

fload ${BP}/arch/sun/auto-field.fth	\ Support inline structure defs
