\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: showdisk.fth
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
id: @(#)showdisk.fth 1.10 02/05/02
purpose: 
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
\ more-poss? is true if there are possibly more devices
0 value more-poss?

\ The prefix deal- relates to "device alias".
\ deal-display is turned on if we want to display text in menu
\ It also affects displaying of individual device path names.
0 value deal-display

\ menu-cont? controls begin while repeat loop to display/receive input
\ It affects only the end text of menu.
true value menu-cont?

\ deal-counter countes all devices of a given type, along with deal-cycle.
0 value deal-counter

\ user's selected counter
0 value my-deal-counter

\ If devices to display are more than those can be displayed in one menu
0 value deal-cycle

\ value of cycle when user selected counter
0 value my-deal-cycle

\ turn off deal-unchosen? after user selects "q" or some valid device
true value deal-unchosen?

h# 90 constant  /deal-buffs
h# 20 constant  /deal-tbuffs
d# 10 constant cyclesize		\ no. of items to display in one menu
/deal-buffs   buffer: start-deal	\ initial path/expanded alias
/deal-buffs  buffer: deal-seled		\ device path selected by user.
/deal-tbuffs  buffer: deal-type-buff	\ device_type to search

\ display one choice for device
: show-me ( -- )
   true to deal-display
   deal-unchosen?  if
      deal-counter ascii a + emit ." ) "
      deal-seled 0 (pwd) type			( )
      cr
   then
;

\ Redisplay selection and some help on how to use it.
: show-only-my ( -- )
   false to deal-display
   \ get correct selection
   deal-counter my-deal-counter =
   deal-cycle my-deal-cycle = and  if   ( )
      \ collect device name in buffer
      [ also hidden also command-completion ]
      cr kill-buffer 1+ 0 (pwd) swap 1- tuck c! dup ".	( pstr )
      [ previous previous ]
      ."  has been selected." cr
      ." Type ^Y ( Control-Y ) to insert it in the command line. " cr
      ." e.g. ok nvalias mydev ^Y " cr
      ."          for creating devalias mydev for " ". cr
   then
;

\ process input from user  other than "m"/"q"
: get-menu ( counter -- counter )
   \ make sure my-deal-counter is less than current deal-counter
   dup deal-counter <
   over 0 >= and  if  ( counter )
      \ there was a valid choice
      deal-cycle to my-deal-cycle
      false to menu-cont?
      false to deal-unchosen?
      false to deal-display
      \ ." correctly selected counter/cycle "
   else   ( counter )
      \ there was an invalid choice
      true to deal-unchosen?
      (cr ." valid choice: a..." deal-counter 1- ascii a + emit ." , "
      more-poss?  if
	 ." m for more or "
      then
      ." q to quit "
   then    ( counter )
;

\ display end portion of menu and take input. process "m"/"q" input
: deal-menu ( -- )
   more-poss?  if
      ." m) MORE SELECTIONS " cr
   then
   deal-display  if
      ." q) NO SELECTION " cr
      ." Enter Selection, q to quit: "
   then
   \ true to menu-cont?
   deal-cycle deal-counter or to menu-cont?
   begin  menu-cont?  while
      key lcc dup emit
      ascii a - to my-deal-counter
      my-deal-counter case
	 [ ascii m ascii a - ] literal ( h# c ) of
	    more-poss?  if
	       \ next round
	       false to menu-cont?
	       deal-display  if  cr cr cr  then
	    else
	       (cr ." valid choice: a..." deal-counter 1- ascii a + emit ." , "
	       ." q to quit "
	    then
	    true to deal-unchosen?
	 endof

	 [ ascii q ascii a - ] literal ( h# 10 ) of
	    false to menu-cont?
	    false to deal-unchosen?
	    false to deal-display
	    \ quitting
	 endof

	 ( default )   get-menu ( my-deal-counter -- my-deal-counter )
      endcase
   repeat
;

\ call routine to individually process a device path name and
\ call routine to get input when one set of devices (cyclesize) are displayed.
: .countedshow  ( acf -- )
   \ execute single device handling routine
   execute  ( )
   deal-counter 1+ is deal-counter
   deal-counter cyclesize mod 0=  if
      \ handle selection from user
      \ TODO if we can terminate (search-preorder) after we select a device,
      \ then we don't need to worry about deal-unchosen? below
      deal-display deal-unchosen? and  if
	 deal-menu
      then
      deal-cycle 1+ is deal-cycle
      0 to deal-counter
   then
;

\ select a device of required device_type
: (sel-dev-type)  ( acf -- )
   \  see if device_type property exists,
   " device_type" get-property  if           ( acf )
      \ not of interest
      drop  				     (  )
   else ( device may be of interest )        ( acf val-adr,len )
      \ since device_type existed, this device may be of interest
      \ see if this device_type is same as we are looking for
      get-encoded-string  deal-type-buff count  $=  if  ( acf )
	 \ really interesting device
	 .countedshow                        (  )
      else                                   ( acf )
	 \ skip this device since device_type is of no interest to us
	 drop                                (  )
      then                                   (  )
   then
;

\ for selecting all devices of a given device_type
: sel-devs ( -- flag )  ['] show-me (sel-dev-type) false  ;

\ for selecting only one device which was chosen by user
: sel-only-my ( -- flag )  ['] show-only-my (sel-dev-type) false  ;

: init-my-counters ( -- )
   true to more-poss?
   true to deal-unchosen?
   0 to my-deal-cycle
   0 to my-deal-counter
;

: init-his-counters ( -- )
   deal-seled /deal-buffs erase
   0 to deal-cycle
   0 to deal-counter
   false to deal-display
;

: init-deal ( type-adr,len -- )  \ initialize counters
   deal-type-buff  /deal-tbuffs erase
   start-deal /deal-buffs erase
   deal-type-buff pack drop     (  )
   init-his-counters            (  )
   init-my-counters             (  )
;

\ initialization and dealing with device path/alias entered by user.
: deal-head ( type-adr,len -- dev-pathadr,len )
   init-deal  ( )
   \ handle optional devicepath or alias
   optional-arg-or-/$        ( dev-pathadr,len )
   ?expand-alias             ( dev-pathadr,len )
   \ save initial path in a buffer for later use with deal-find.
   2dup start-deal pack drop ( dev-pathadr,len )
;

\ main routine which calls preorder search on device tree
: deal-find ( dev-pathadr,len acf -- )
   -rot  find-device  ( acf )
      ( acf )  ['] (search-preorder) catch 2drop
   device-end
;

\ for confirming user's selection (redisplay of the selected device path)
: show-sel ( -- )
   my-deal-counter
   ( ascii q ascii a - ) h# 10 <>  if
      init-his-counters                 (  )
      \ start with the same device path/alias as user entered
      start-deal count                  ( dev-pathadr,len )
      ['] sel-only-my deal-find
   then
;

\ main high level routine to find all devices of a given type.
\ stack input is counted string for that device type
: deal-devs ( type-adr,len -- )
   current-device >r
   \ init and handle optional input
   deal-head  ( dev-pathadr,len )
   ['] sel-devs deal-find
   \ in case we never made a choice
   begin
      deal-unchosen? deal-cycle deal-counter or and
   while
      false to more-poss?
      deal-menu
      false to deal-display
   repeat
   \ after a valid selection by user, redisplay user's selection
   show-sel
   r>  push-device
;

headers
: show-disks    ( -- )  " block"         deal-devs  ;
: show-ttys     ( -- )  " serial"        deal-devs  ;
: show-hier     ( -- )  " hierarchical"  deal-devs  ;
: show-nets     ( -- )  " network"       deal-devs  ;
: show-tapes    ( -- )  " byte"          deal-devs  ;
: show-displays ( -- )  " display"       deal-devs  ;
