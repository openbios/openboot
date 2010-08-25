\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: alarm.fth
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
id: @(#)alarm.fth 2.17 05/04/08
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ alarm function.
\ To install an alarm:  ['] forth-function #msecs alarm
\ To uninstall alarm:   ['] forth-function 0      alarm
\
headerless

variable alarm-list alarm-list off
struct
   /n  field  >active
   /n  field  >time-out
   /n  field  >time-remain
   /n  field  >acf
   /n  field  >ihandle
constant /alarm-node
d# 32 constant /max-alarms
/max-alarms /alarm-node * constant /alarm-list

: init-alarm-list
   /alarm-list dup alloc-mem			( len adr )
   dup alarm-list !				( len adr )
   swap erase					( )
;

\ execute acf for each active node in the alarm list
\ with the acf args and active node on the stack ( ??? node -- ??? flag )
\ exit with the alarm node for which the acf returns true on the stack
\ or 0 if the acf returns false for all alarms
: active-alarms  ( ??? acf -- node|0 )
   alarm-list @ /alarm-list 			( ??? acf adr len )
   bounds do					( ??? acf )
      i >active @ if				( ??? acf )
         i swap dup >r execute if		( ??? )           ( r: acf )
            r> drop i false leave		( ??? node flag ) ( r: )
         then					( ??? )           ( r: acf )
         r>					( ??? acf )       ( r: )
      then					( ??? acf )
      /alarm-node				( ??? acf sz )    ( r: )
   +loop					( ??? acf )       ( r: )
   if false then
;

: show-alarm  ( node -- flag )
   dup >acf @ .name  d# 20 to-column  dup >ihandle @ 9 u.r
   dup >time-out @ d# 7 u.r  >time-remain @ d# 10 u.r  cr
   false
;
headers
: .alarms  ( -- )
   ." Action                Ihandle  Interval  Remaining" cr
   ['] show-alarm active-alarms drop
;
headerless

\ Return flag will be true if the acf of the give node is equal to
\ the given acf.
: target-node?  ( ihandle acf node -- ihandle acf flag )
   2dup >acf @  =				( ihandle acf node flag )
   3 pick rot >ihandle @  = and			( ihandle acf flag )
;

: find-alarm  ( ihandle acf -- ihandle acf node|0 )
   ['] target-node? active-alarms
;

\ find next inactive alarm node for new alarm
: new-alarm  ( -- node|0 )
   false alarm-list @ /alarm-list 		( false adr len )
   bounds do					( false )
      i >active @ 0= if  drop i leave  then	( node )
      /alarm-node				( false sz )
   +loop					( false|node )
;

\ If a node with "acf" is already in the alarm-list, then just set the
\ time-out and time-remain with the new value "n"; else allocate a
\ new node and set up all fields with the given info.
: set-alarm-node  ( ihandle acf n -- )
   \ convert n miliseconds to #clock-ticks.
   ms/tick /mod  swap 0<>  if  1+  then		( ihandle acf #clock-ticks )
   >r find-alarm ?dup if			( ihandle acf node ) ( r: clk )
      0 over >active !				( ihandle acf node )
   else						( ihandle acf )
      new-alarm ?dup 0= if			( ihandle acf )
         ." ERROR: Alarm " .h			( ihandle )
         ."  not installed." cr   		( ihandle )
         ." Out of available alarms! " cr	( ihandle )
         r> 2drop abort				( )
      then					( )
   then						( ihandle acf node )
   tuck >acf !					( ihandle node )
   r@ over >time-out !				( ihandle node )
   r> over >time-remain !			( ihandle node )
   tuck >ihandle !				( node )
   -1 swap >active !				( )
;

\ find alarm by matching in ihandle/acf and set it inactive
: turn-off-alarm  ( ihandle acf -- )
   find-alarm ?dup if				( ih acf node )
      >active 0 swap ! 2drop			( )
   else						( ih acf )
      ." No alarm was installed for " .h  cr	( ih )
      drop					( )
   then
;

\ First check to see if the alarm is on (time-out >0).  If it is,
\ then check to see if the time is expired (time-remain = 0).
\ If time is not expired, decrement the time-remain.
: time-expired?  ( node -- flag )
   dup  >time-remain @  1- dup 0<=  if		( node remain )
      drop  dup >time-out @  over		( node out node )
      dup >acf @  swap >ihandle @		( node out acf ih )
      call-package				( node out )
   then swap >time-remain ! false		( false )
;

\ on entry alarms are disabled by setting alarm-disabled? true.
\ after alarms complete, alarm-disabled? set back to false to reenable alarms.
\ if any alarm results in an exception, we won't return from active-alarms
\ and alarm-disabled? will remain true so that alarms are permanently
\ disabled until the system is reset (breaks won't work). this is to
\ prevent exception-causing alarms from recurring everytime obp tries to
\ recover from the last exception. 
variable alarm-disabled? alarm-disabled? off
: check-alarm  ( -- )
   alarm-disabled? @ if  exit  then
   alarm-disabled? on
   ['] time-expired? active-alarms drop
   alarm-disabled? off
;

headers
: alarm  ( acf n -- )
   my-self -rot				( ihandle acf n )
   ?dup if  set-alarm-node  else  turn-off-alarm  then
;
