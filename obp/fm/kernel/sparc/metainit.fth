\ id: @(#)metainit.fth 2.7 02/05/02
\ purpose: 
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1995-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

\ Metacompiler initialization

\ Debugging aids

0 #words ! h# 2a0 threshold ! 10 granularity ! warning-t on

forth definitions

metaon
meta definitions

\ We want the kernel to be romable, so we put variables in the user area
:-h variable  ( -- )  nuser  ;-h
alias \m  \

initmeta

\ Allocate space for the target image
th 22000 alloc-mem h# 1000 round-up target-image

\ org sets the lowest address that is used by Forth kernel.
hex

0.0000 org  0.0000
   voc-link-t a-t!

200 equ ps-size

assembler

\ This is at the first location in the Forth image.

\ init-forth is the initialization entry point.  It should be called
\ exactly once, with arguments (dictionary_start, dictionary_size).
\ init-forth sets up some global variables which allow Forth to locate
\ its RAM areas, including the data stack, return stack, user area,
\ cpu-state save area, and dictionary.

hex
mlabel cld
   9000 always brif annul	\ The address will be fixed later.
   nop				\ Delay slot
   nop
   nop
[ifdef] miniforth?
\ truncated traptable
64\   100 10 - 0 ?do unimp /l +loop
[else]
64\   8000 10 - 0 ?do unimp /l +loop
[then]

meta
