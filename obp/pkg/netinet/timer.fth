\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: timer.fth
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
id: @(#)timer.fth 1.1 04/09/07
purpose: Timer utility functions
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

struct
   /l  field   >tm-start	\ Time this entry was made
   /l  field   >tm-expire	\ Time this timer expires
constant /timer

\ Set timer event.
: set-timer ( timer interval -- )
   get-msecs tuck +  rot tuck >tm-expire l!  >tm-start l!
;

\ Clear timer event. Return time elapsed since event entry was made.
: clear-timer ( timer -- timespent )
   get-msecs  over >tm-start l@ -  swap		( timespent timer )
   0  over >tm-expire  l!			( timespent timer )
   0  swap >tm-start   l!			( timespent )
;

\ Get time elapsed since the timer event entry was made.
: get-timer ( timer -- timespent )
   >tm-start l@  get-msecs  swap -
;

\ Check if timer has expired.
: timer-expired? ( timer -- flag )
   >tm-expire l@  ?dup if  get-msecs <  else  false  then
;

\ Check if timer is in use. 
: timer-running? ( timer -- flag )  >tm-expire l@ 0<> ;

headers
