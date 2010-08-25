\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: memtest.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)memtest.fth 2.16 01/04/06
purpose: 
copyright: Copyright 1999-2001 Sun Microsystems, Inc.  All Rights Reserved

\ TODO: Make this interruptible

\ Generic memory test module.  This will test pretty much any memory
\ array, given the address, size, and width of the array.
\
\ Variables:
\   mask		Contains a bit mask with ones for each data bit
\			which is implemented in the memory array.  Examples:
\			A 32-bit memory array would use mask = (hex)ffffffff.
\			A 24-bit memory array would use mask = (hex)00ffffff.
\
\   mem@		Defer word which by default executes l@ .  Change this
\			if your memory cannot handle 32-bit operations.
\
\   mem!		Defer word which by default executes l! .  Change this
\			if your memory cannot handle 32-bit operations.
\
\ Tests:
\
\ mem-addr-test  ( membase memsize -- fail-flag )
\			In the memory array starting at membase, tests
\			the address lines for the following static
\			faults:
\			a) Address line stuck
\			b) Address line shorted to another address line
\			c) Address line shorted to a data line
\
\			This test is quite fast; it's execution time is
\			O(#add-lines).
\
\ mem-data-test  ( membase -- fail-flag )
\			"Walking Ones and Zeroes" data line test.  Tests
\			each data line for static "stuck-at" faults.  The
\			value contained in the "mask" variable controls
\			which data lines are tested.
\
\ mem-size-test  ( membase -- fail-status )
\			Verifies that memory can be accessed either as
\			bytes, shortwords, or longwords.  Writes the
\			hex number 12345678 to the location at membase,
\			one byte at a time.  Then reads it back as a longword
\			and checks the value.  Then does the same thing
\			writing one shortword at a time.
\			The "mask" variable selects which data bits are
\			significant.
\
\ mem-bits-test  ( membase memsize -- status )
\			Within the range membase .. membase+memsize-1, tests
\			each location to ensure that no bits are stuck at
\			either one or zero.  This is done by verifying that the
\			location can contain both the value ffffffff and
\			the value 0.  The "mask" variable selects which data
\			bits are significant.
\
\ address=data-test  ( membase memsize -- fail-flag )
\			Within the range membase .. membase+memsize-1,
\			writes each longword location with it's own address,
\			then verifies.  The "mask" variable selects which
\			data lines are significant during the verify step.
\			This test checks for the uniqueness of individual
\			locations with RAM chips.  "Stuck" address lines
\			external to RAM chips would presumably be detected
\			more quickly by "mem-addr-test".
\
\ mats-test  ( membase memsize pattern -- fail-flag )
\			Within the range membase .. membase+memsize-1, tests
\			groups of 3 consecutive locations.  The first and third
\                       locations in the group are written with "pattern"
\			and the second location is written with the bitwise
\			inverse of "pattern".  Verifies the data bits selected
\			by the "mask" variable.
\			I'm not sure what kind of failures that this test
\			can catch, other than failures that are more easily
\			detected by other tests.
\
\ memory-test-suite  ( membase memsize -- status )
\			Performs a series of tests on the range of memory
\			from membase to membase+memsize-1.

hex

headerless
defer mem!  ' l! is mem!
defer mem@  ' l@ is mem@
headers
: display-status ( n -- )  drop  ;
variable group-code
nuser mask  mask on
headerless

: maskit  ( value -- masked-value )  mask @ n->l  and  ;

nuser mem-address
nuser mem-expected
nuser mem-observed

nuser failed		\ Local
: .mem-test-failure ( -- )
   ??cr
   ." Addr ="  mem-address  @ .lx
   ."  Exp ="  mem-expected @ dup .lx
   ."  Obs ="  mem-observed @ dup .lx
   ."  Xor ="  xor .lx
   ??cr
;

: ?failed  ( observed expected -- )
   2dup  <>  if
       mem-expected !  mem-observed !  failed on
   else
       2drop
   then
;

: mem-test  ( value address -- )
   dup mem-address !  mem@ maskit  swap maskit  ?failed
;

\ "Walking Address Line" test ( quick )

\ The following routine tests an individual address line for the
\ following static faults:
\    a) stuck at either 0 or 1
\    b) shorted to a data line
\    c) shorted to another address line
\ Sets the failed variable if a failure is detected

nuser add-base
nuser add-top
: address-line-test  ( addr# -- )

   \ First we write all zeroes to the top and bottom memory locations
   0 add-base @ mem!   0 add-top  @ mem!

   \ Now we write all ones to 2 locations: the location whose address
   \ differs from the bottom address only by the address line under test,
   \ and the location whose address differs from the top address only by
   \ the address line under test.

   1 over <<			( addr# offset )
   add-base @ over +  ffffffff swap mem! \ store ones at "base + [1 << addr#]"
   add-top  @ over -  ffffffff swap mem! \ store ones at "top  - [1 << addr#]"
				( addr# offset )

   \ Now we check to see if either of the top or bottom locations got
   \ clobbered when we wrote the other two locations.  This tests for
   \ address uniqueness in the one address line, and also for that address
   \ line stuck to a data line.

   0  add-base @  mem-test
   0  add-top  @  mem-test

   \ Finally, we do the whole thing again, except that we use the opposite
   \ data values.  This allows us to distinguish a stuck address line
   \ from an address line shorted to a data line.  We don't actually
   \ use this distinction, since the only output from this entire test
   \ is "good" or "bad".

				( addr# offset )
   ffffffff add-base @ mem!	\ store all ones into bottom of memory
   ffffffff add-top  @ mem!	\ store all ones into top of memory

   add-base @ over +  0 swap mem! \ store 0 at location "base + [ 1 << addr#]"
   add-top  @ over -  0 swap mem! \ store 0 at location "top - [ 1 << addr#]"

   ffffffff add-base @  mem-test
   ffffffff add-top  @  mem-test
				( addr# offset )

   \ If more detailed failure analysis were desired, we could distinguish
   \ between the various places where the test could fail.
   \ For now, we just return pass or fail.

   ( addr# offset )  2drop  ( )
;

\ This test loops over all the address lines, testing each of them
\ with the above "address-line-test"

: mem-addr-test  ( membase memsize -- fail-flag )
   "     Address quick test" diag-type

   failed off			\ set failed flag false

   tuck bounds			( memsize memtop membase )
   add-base !  /l - add-top !   ( memsize )

   \ Calculate the number of address lines to test
   log2				( #adr-lines )

   \ Loop over the address line numbers  2  ..  #adr-lines - 1
   \ Address lines 0 and 1 are byte and word selectors, which are
   \ not appropriate to test with this procedure

   ( #adr-lines )  2  do  i address-line-test  loop
   failed @			\ place failed flag on stack
;

: mem-size-test  ( membase -- fail-status )
   "     Data size test" diag-type

   failed off		\ set failed flag to false

   \ write data in word size
   h# 1234 over w!  h# 5678 over wa1+ w!     ( membase )

   h# 12345678  over  mem-test               ( membase )

   \ write data in byte size
   h# 12 over 0 ca+ c!  h# 34 over 1 ca+ c!
   h# 56 over 2 ca+ c!  h# 78 over 3 ca+ c!  ( membase )

   h# 12345678  over  mem-test               ( membase )
   drop
   failed @			\ place failed flag on stack
;

: mem-data-test ( membase -- fail-status )
   "     Data lines test" diag-type
   failed off			\ set failed flag to false

   \ Walking ones
    				( membase )
   d# 32 0 do			\ loop over all 32 data lines
      1 i <<  over  mem!	( membase )
      1 i <<  over  mem-test	( membase )
   loop                         ( membase )

   \ Walking zeroes
   d# 32 0 do			 \ loop over all 32 data lines
      1 i << invert  over  mem!	     ( membase )
      1 i << invert  over  mem-test  ( membase )
   /l +  loop                        ( membase )

   drop                         ( )
   failed @			\ put failed flag onto the stack
;

: mem-bits-test  ( membase memsize -- fail-status )
   "     Data bits test" diag-type
   failed off			\ set failed flag to false

   bounds			( memtop membase )
   2dup  ?do  h# ffffffff  i  2dup mem!  mem-test  /l +loop	\ stuck at 0 test
         ?do  h# 00000000  i  2dup mem!  mem-test  /l +loop	\ stuck at 1 test

   failed @			\ put failed flag onto the stack
;

: address=data-test  ( membase memsize -- status )
   "     Address=data test"  diag-type

   bounds  2dup  do  i i mem!  /l +loop	( memtop membase )

   failed off
   do  i i mem-test  /l +loop
   failed @			\ return failed flag on stack
;

\ This test writes groups of 3 consecutive locations.  The first and
\ third locations in the group are written with a pattern, and the second
\ location is written with the inverse of the pattern.

nuser mats-pattern
: mats-test  ( membase memsize pattern -- status )
   "     Mats test"  diag-type
   mats-pattern !

   bounds  2dup  do
      mats-pattern @
      dup          i       mem!
      dup  invert  i 1 la+ mem!
                   i 2 la+ mem!
   /l 3 * +loop

   failed off		( memtop membase )
   do
      mats-pattern @
      dup         i       mem-test
      dup  invert i 1 la+ mem-test
                  i 2 la+ mem-test
   /l 3 * +loop
   failed @
;

warning @ warning off 
nuser failed	\ Intentional redefinition
warning !
: ?fail  ( flag -- )
   ?dup  if
      failed @  max  failed !  ( )
      "  -- failed."  diag-type
   else
      "  -- succeeded." diag-type
   then  diag-cr
;
headers
: memory-test-suite  ( membase memsize -- status )
   failed off

   over  mem-data-test  ?fail   ( membase memsize )
   2dup  mem-addr-test  ?fail   ( membase memsize )
   over  mem-size-test  ?fail   ( membase memsize )
   diagnostic-mode?  if
      2dup mem-bits-test      ?fail   ( membase memsize )
      2dup address=data-test  ?fail   ( membase memsize )
\ Don't do the mats test, because I'm not convinced that it is useful
\       2dup h# a5a5a5a5  mats-test  ?fail   ( membase memsize )
   then
   2drop

   failed @
;
