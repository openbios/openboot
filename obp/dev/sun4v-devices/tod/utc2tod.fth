\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: utc2tod.fth
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
id: @(#)utc2tod.fth 1.2 06/03/17
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ ordinary year calendar
create year-days
   d# 31 c, d# 28 c, d# 31 c, d# 30 c, d# 31 c, d# 30 c,
   d# 31 c, d# 31 c, d# 30 c, d# 31 c, d# 30 c, d# 31 c,

\ leap-year calendar (february has 29 days)
create leap-days
   d# 31 c, d# 29 c, d# 31 c, d# 30 c, d# 31 c, d# 30 c,
   d# 31 c, d# 31 c, d# 30 c, d# 31 c, d# 30 c, d# 31 c,

\ Determine time within the day 
: utc-to-time ( utc -- h m s )
   >r					(  )		( r: utc )
   r@ d# d# 86400 mod d# 3600 /		( h )		( r: utc )
   r@ d# 3600 mod d# 60 /		( h m )		( r: utc )
   r> d# 60 mod				( h m s )
;


\ Walk through each month decrementing number of days left, leaving month and
\ day on stack. This depends on january having longest month, so when we have
\ found a date, subsequent calls just return leaving date unaltered. If we
\ walk through the entire calendar's worth of days without having run out of
\ days, we increment the year number and revert month to january.

: calc-month ( year month days-left calendar -- year month days-left )

   swap 				( year month calendar days-left )

   \ Walk through all twelve months, subtracting number of days per month
   \ until we find a month with more days than we have left - then return.
   d# 12 0 do
      over i + c@ 2dup > if		( year month cal days-left #days )
         - rot 1+ -rot			( year month+1 calendar days-left )
      else
         drop nip unloop exit		( year month day )
      then
   loop					( year month cal days-left )

   \ If we get here, we've decremented an entire year of days. Bump year#.
   nip -rot drop 1+ 1 rot		( year+1 1 days-left )
;

\ Convert utc (number of seconds since jan 0, 1970) to
\ day of week, day of month, month and years-since-1900.

: utc-to-date ( utc -- dow d m y )

   d# 86400 / 				( days-since-1970 )
   dup 4 + 7 mod 1+ swap		( dow days-since-1970 )

   \ Skip over 4-year groups (three years and one leap year), so we can then
   \ determine the date within the more complicated pattern of leap years. Each
   \ four-year group consists of 1461 days (365*3 + 366). Note that we depend
   \ on the fact that 2000 (unlike 1900 or 2100) was a leap year. This code
   \ will need to be fixed sometime this century.

   d# 1461 2dup / dup >r		( dow days-since-1970 quadreniums )
					( r: quadreniums )
   * -					( dow days-since-quadrenium )
					( r: quadreniums )

   \ Quadreniums * 4 + 70 = years since 1900.
   1+ r> 4 * d# 70 + swap 1 swap	( dow year month days-left )
 
   \ Walk through month-by-month within the quadrenium

   year-days calc-month			( dow year month days-left )
   year-days calc-month			( dow year month days-left )
   leap-days calc-month			( dow year month days-left )
   year-days calc-month			( dow year month days-left )
   -rot swap				( dow day month year )
;

