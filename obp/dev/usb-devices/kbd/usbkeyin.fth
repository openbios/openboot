\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usbkeyin.fth
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
\ id: @(#)usbkeyin.fth 1.18 01/05/23
\ purpose: 
\ copyright: Copyright 1997-2001 Sun Microsystems, Inc.  All Rights Reserved


\ headers			\ XXX for debugging
external

1 instance value ha-toggle
: our-toggle  ( -- new-toggle )
  ha-toggle if
    0 dup to ha-toggle	( 0-toggle )
  else
    1 dup to ha-toggle	( 1-toggle )
  then
;


: get-keynumber  ( index -- key# )
  curr-byte1-bfaddr + c@
;


\ If the keyvalue (from the keymap) indicates a normal key (other than
\ ctrl, shift, altg, power, noop, oops, capslock, hole, monitor)
\ then return true, otherwise return false.
\
: is-keyvalue-nonspcl?  ( keyvalue -- flag )
  dup h# 80 <           ( keyvalue flag' )
  swap h# 9f > or       ( flag )
;


\ Once the current down keys have been evaluated and dealt with, they
\ become the previous report's keys, so copy all relevant data.
\
: copy-curr-to-prev  ( -- )

  /key-info-buff 0 do
     keybuff-curr^v i + c@   keybuff-prev i + c!
  loop

  shiftflag to pr-shiftflag   stopflag to pr-stopflag
  ctrlflag  to pr-ctrlflag    altgflag to pr-altgflag
  powerflag to pr-powerflag   monflag  to pr-monflag
;



\ Increment the variable (that's kept in the key input buffer) which
\ keeps track of how many nonspecial keys are down in the current report.
\
: count-curr-as-nonspcl  ( -- )
  keybuff-curr^v >#regl-keys-dn	( regkey-cnt-adr )
  dup c@ 1+ swap c!
;


\ If the keynumber matches for a special key ( Control, Shift - including
\ capslock, Altg, Power, Mon or Stop ) then set the index from the 1st
\ keybyte buff location into its "flag".
\ At the same time keep a count of the non-special keys.
\
\ Note that in a way this is cheating because we haven't used the
\ keymap to get the "intent" of the key# - we've explicitly associated
\ some of the key#s with their known actions.  This will be OK for two
\ reasons; 1) We won't take action on the special keys (except Stop)
\ until later when we're applying the "rules", and 2) regardless of
\ country layout, the key#/action for each of these keys will always
\ remain constant.  So, for example, if we get a key# of 102 (power
\ key), it will only matter to us later if a shift key is also present.
\
: chk-n-set-spcl|regl  ( -- )
  0 keybuff-curr^v >#regl-keys-dn c!		\ init count to 0
  curr-#ksdn-bfaddr c@				( #downkeys )
  0 do
     true   i get-keynumber			( yes-spcl-flag key# )
 
     case
     \ Note that the case doesn't contain values for rt shift or rt
     \ control since we explicitly convert the modifier byte's bits
     \ to be left shift and left control (in "add-key-to-array").
        d# 225 of   i to shiftflag   endof	\ left shift
        d# 224 of   i to ctrlflag    endof	\ left control
        d# 230 of   i to altgflag    endof	\ right alt == Altgraph
        d# 57  of   i to shiftflag   endof	\ capslock
        d# 102 of   i to powerflag   endof	\ power key
        d# 127 of   i to monflag     endof	\ mute(nonshift)
                                          	\ mon-off-on(shift)
        d# 120 of   i to stopflag    endof	\ stop (L1) key down
 
        nip false swap				( no-spcl-flag key# )
     endcase					( spcl-flag? )
 
     \ Now use the index and flag to mark the key as special or regular.
     false = if					( )
        count-curr-as-nonspcl			( )
     then
  loop
;


\ If the control key is down and it is in effect (it is the highest
\ priority control key down) then apply the control offset to the
\ keyvalue.
\
: chk&adjust4ctrl ( keyvalue' -- keyvalue )

  ctrl-in-effect if
     ctrlflag -1 > if
        h# 1f and	( keyvalue )
     then
  then
;


\ Take the key# (prior to conversion to the ascii char) and see if it was
\ in the previous report.
\
: in-last-rep?  ( key# -- flag )
  false swap					( flag' key# )
  keybuff-prev >#keys-down c@ dup if		( flag' key# #prev-kys-dn )
     0 do					( flag' key# )
        dup prev-byte1-bfaddr i + c@ = if	( flag' key# )
           nip true swap			( true-flag key# )
        then					( flag' key# )
     loop   1					( flag' key# dropjunk )
  then						( flag' key# something )
  2drop						( flag )
;


: set-repeating-flag  \ ( prpt|-1 rpting? newk|-1 key# keyval --
                      \   -- prpt|-1 rpting?' newk|-1 )
\ drop rot true or -rot
  2drop >r  true or  r> 
;


: chknset-potential-rpt  \ ( prpt|-1 rpting? newk|-1 k# keyval --
                         \   -- prpt rpting? newk|-1 )
  >r drop		( prpt|-1 rpting? newk|-1 ) ( R: keyval )
  rot dup -1 = if	( rpting? newk|-1 prpt|-1 ) ( R: keyval )
     drop r>		( rpting? newk|-1 prpt )    
  else
     r> drop		( rpting? newk|-1 prpt )    
  then
  -rot 			( prpt rpting? newk|-1 )
;


\ Set the keval as the newkey, but only if another keyval from the current
\ report hasn't already been set.  (The first "new" key found is used.)
\
: chknset-new-keyval-rcvd  \ ( prpt|-1 rpting? newk|-1 keyval --
                           \   -- prpt|-1 rpting? newkey' )
  swap dup -1 = if	( prpt|-1 rpting? keyval newk|-1 )
     drop 		( prpt|-1 rpting? newkey )
  else
     nip 		( prpt|-1 rpting? prev-newkey )
  then
;


: queue?-adjust-flags \ ( prpt|-1 rpting? newkey|-1 key# keyval -- 
                      \   -- prpt|-1' rpting?' newkey|-1' )
  dup curr-repeat-key = if	( prpt|-1 rpting? nwkey|-1 k# keyval )
     set-repeating-flag		( prpt|-1 rpting! newkey|-1 )
     exit
  then				( prpt|-1 rpting? nwkey|-1 k# keyval )

  over in-last-rep? if		( prpt|-1 rpting? nwkey|-1 k# keyval )
     chknset-potential-rpt	( prpt' rpting? newkey|-1 )
     exit
  then	nip			( prpt|-1 rpting? newkey|-1 keyval )

  dup bput			( prpt|-1 rpting? newkey|-1 keyval )
  chknset-new-keyval-rcvd	( prpt|-1 rpting? newkey' )
;


\ Go through the list of keys which are down, queuing any new keys after
\ they've been converted to ascii chars.  Three items are returned;
\ 1)  The first key in the current report which was also seen in the
\     last report - but which is not the repeat key, or -1 if those
\     criteria are not met.
\ 2)  A true/false flag which indicates if the repeat key was found in
\     in this latest report.
\ 3)  The first "new" key in the report, or a -1 if there were no new
\     keys seen.
\
defer convert      ' noop is convert

0 instance value shift-map?
0 instance value altg-map?

: setup-flags ( -- altg? shift? )
   altg-map? shift-map?
;

: queue-new-keys  ( -- potrptkey|-1 repeating? newkey|-1 )
  -1 false -1 	(		 prpt|-1 rpting? newk|-1 )

  curr-#ksdn-bfaddr c@		( prpt|-1 rpting? newk|-1 #dnkeys )
  0 do				( prpt|-1 rpting? newk|-1 )
     i get-keynumber dup	( prpt|-1 rpting? newk|-1 k# k# )
     setup-flags 		( prpt|-1 rpting? newk|-1 k# k# altg? shift? )
     convert			( prpt|-1 rpting? newk|-1 k# keyval )
     dup is-keyvalue-nonspcl? if ( prpt|-1 rpting? newk|-1 k# keyval )
        chk&adjust4ctrl		( prpt|-1 rpting? newk|-1  k# keyval' )
        queue?-adjust-flags	( prpt|-1' rpting?' newk|-1' )
     else  2drop
     then			( prpt|-1' rpting?' newk|-1' )
  loop
;


\ There's a new key, so mark it and add in the initial delay time
\ for the repeat timer mechanism.
\
: new-repeat-key  ( keyvalue -- )
  to curr-repeat-key				( )
  get-msecs d# 700 + to key-repeat-time
;


\ Using the specified keymap, have the regular keys queued and then
\ set the repeat key.  The algorithm for determining the repeat key is
\ as follows;
\ 1)  If a new keyvalue is found that was not in the last report then
\     set it as the new repeat key.
\ 2)  If no new keyvalue was found, see if the currently repeating
\     keyvalue was seen - if so take no action so that the timers will
\     be continuous.
\ 3)  If there's no new key, and the currently repeating key was not
\     seen, it's still possible that a keyvalue that was found in the
\     last report is still in the current report, and if so then that
\     keyvalue becomes the repeat key.  (This would occur if the user
\     pressed two or more keys simultaneously, but then released one
\     or more keys - including the repeat key, but still kept one or
\     more keys pressed.)
\
: process-dn-keys  ( -- )
  queue-new-keys	( potrptkey|-1 repeating? newkey|-1 )

  dup -1 > if		( potrptkey|-1 repeating? newkey|-1 )
     new-repeat-key	( potrptkey|-1 repeating? )
     2drop exit
  then  drop		( potrptkey|-1 repeating? )

  if			( potrptkey|-1 )
     drop exit		\ The "old" repeat key continues...
  then			( potrptkey|-1 )

  dup -1 = if		( potrptkey|-1 )
     drop		( )
     nokey to curr-repeat-key
  else
     new-repeat-key	( )
  then
;


\ The only special key down is Stop, and at least 1 regular key is down.
\ Stop-a was taken care of elsewhere.  Not yet certain if we're going
\ to attempt to put in Stop-d, Stop-n or Stop-f, so ignore for now.
\
: eval-stop+keys ( table-offset -- )
  process-dn-keys	( )
;

: stop-&-regl-dn  ( -- )
  false to shift-map? false to altg-map? eval-stop+keys	
;


: shift-&-regl-dn  ( -- )
  true to shift-map? false to altg-map? process-dn-keys
;


: altg-&-regl-dn  ( -- )
  false to shift-map? true to altg-map? process-dn-keys
;


\ Find out if each of the xspecial keys (don't bother with the monitor or
\ power keys) that are currently down were also down in the last report
\ - if so return a true flag.
\
: all-spcl-prev-dn?		( -- flag )
  true				( flag' )
  stopflag -1 <> if
     pr-stopflag -1 <> and	( flag' )
  then
  shiftflag -1 <> if
     pr-shiftflag -1 <> and	( flag' )
  then
  ctrlflag -1 <> if
     pr-ctrlflag -1 <> and	( flag' )
  then
  altgflag -1 <> if
     pr-altgflag -1 <> and	( flag )
  then
;


: check-shift-power&mon  ( -- )

  powerflag -1 > if   turn-me-off   then
  monflag -1 > if     toggle-mon    then
;


: do-shift-&-regl-dn  ( -- )
  check-shift-power&mon shift-&-regl-dn
;


\ Determine the highest priority spcecial key that is down so that only
\ it will be considered when we evaluate the "normal" keys that will go
\ into the queue.
\
: use-hipri-spcl  ( -- )
  stopflag -1 > if
     stop-&-regl-dn		( )
     exit
  then

  shiftflag -1 > if
     do-shift-&-regl-dn		( )
     exit
  then

  ctrlflag -1 > if
     -1 to ctrl-in-effect	( )
     shift-&-regl-dn		( )
     0 to ctrl-in-effect	( )
     exit
  then

  altgflag -1 > if
     altg-&-regl-dn		( )
     exit
  then
;



\ Return true if the current flag is set and the previous flag is not set.
\
: only-curr-set?  ( curr-flag-val|-1 prev-flag-val|-1 -- flag )
  -1 =			( curr-flag-val flag' )
  swap -1 > and
;


\ One or more special keys down.  If only one is new then ignore the
\ rest and use the new.  If more than one special key is new then use
\ the one with the highest priority.  Note that checking of Stop-a was
\ done prior to arriving here.
\
: spcl-keys-dn ( -- )

  all-spcl-prev-dn? if		( )
     \ Since there are no new special keys, we're going to select the
     \ highest priority key as the one to use.
     use-hipri-spcl		( )
  else
     \ Find out which of the special keys are "new" and select the
     \ highest priority key from that one.

     stopflag pr-stopflag only-curr-set? if
        stop-&-regl-dn		( )
        exit
     then

     shiftflag pr-shiftflag only-curr-set? if
        do-shift-&-regl-dn	( )
        exit
     then

     ctrlflag pr-ctrlflag only-curr-set? if
        -1 to ctrl-in-effect	( )
        shift-&-regl-dn		( )
        0 to ctrl-in-effect	( )
        exit
     then

     \ If none of the above-three are the new down special then it must
     \ be the AltGraph key.
     altg-&-regl-dn		( )
  then
;


\ Determine if special keys are present and will be used, or if there
\ are only std keys.
\ Note that checking of Stop-a was done prior to arriving here.
\
: due-process  ( #spclkeys-dn -- )
  dup curr-#ksdn-bfaddr c@ swap	( #spclkeys-dn #keys-dn #spclkeys-dn )
  - 0= if			( #spclkeys-dn )
     \ Only spcl keys down.
     shiftflag -1 = if		( #spclkeys-dn )
        \ If one of the spcl keys wasn't the shift key (indicating that a
        \ shift-power or shift-mon could be possible) then no keys from
        \ the current report will go into the queue.
        nokey to curr-repeat-key	( )
        drop   exit		( )
     then
  then				( #spclkeys-dn )
 
  if
     spcl-keys-dn		( )
  else
     false to shift-map? false to altg-map? process-dn-keys
  then
;


\ The Stop key is known to be down, so cycle through all down keys to
\ see if the 'a' key is down.
\
: stopA-active?  ( -- StopA? )
  false curr-#ksdn-bfaddr c@	( StopA?' #down-keys )
  0 do
     i get-keynumber		( StopA?' key# )
     4 = if			( StopA?' )
        true or leave		( yes-StopA )
     then
  loop				( StopA? )
;
 

\ If more than 1 key is down then we'll need to apply a set of "rules"
\ that will let us know the precedence of the pressed keys.  For example,
\ there might just be several normal keys down, or there may be special
\ keys down as well.  In the case where multiple keys are reported, we'll
\ look at the down keys in the previous report (if any) to see if it can
\ be determined which of the current down keys are "new".
\
: start-key-processing  ( -- StopA? )
  chk-n-set-spcl|regl			( )

  stopflag -1 > if
     stopA-active? dup if		( StopA? )
        exit				( yes-StopA )
     then
  else
     false				( no-stopA )
  then

  curr-#ksdn-bfaddr c@			( no-StopA #down-keys )
  keybuff-curr^v >#regl-keys-dn c@ -	( no-StopA #spclkeys-dn )
  due-process				( no-StopA )
;


\ Sets the global offset into the current and previous report's key-down
\ buffer to point to the 1st (of 9) key-down bytes.  A pointer to the
\ # of keys down in the current buffer is also set since it's used
\ frequently.
\
: set-oftused-buf-offsets  ( -- )
  keybuff-curr^v >kbd-in-byte1 to curr-byte1-bfaddr
  keybuff-curr^v >#keys-down   to curr-#ksdn-bfaddr

  keybuff-prev >kbd-in-byte1 to prev-byte1-bfaddr
;


\ Receive a keyvalue which represents a special key, and place it
\ into the 1st available array position in the input key array.
\
: add-key-to-array  ( #dn-keys modbyte byte-to-add -- #dn-keys' modbyte )
  swap >r				( #down-keys' byte-2-add )
  over keybuff-curr^v >kbd-in-byte1 +	( #dn-keys' byte-2-add byteN-addr)
  c!   1+   r>				( #dn-keys' modbyte )
;


\ 1 indicates a keyboard rollover - indicating too many keys pressed or
\ kbd is confused; 2 indicates kbd diag failure; 3 is undefined error;
\ The rollover error seems to be cleared on next understandable keypress,
\ but don't know about the other two.
\
: kbd-err?  ( key-value -- flag )
  4 < if true else false then
;


\ The "down" keys from the latest key report are placed into one of the
\ buffers by the HA by specifying its address in the enable-interrupts
\ call to the HA; We then use pointers to the buffers to get at the
\ key information.
\ USB keyboards automatically sets individual key bytes to 0 if no key
\ is down.
\ Note that we'll "copy" any shift, cntrl or AltGraph keys into the
\ 1st open slot in the array (based on the info in the modifier byte). This
\ is being done since the code was originally written to expect those
\ three special keys to be returned in the array rather than the modifier
\ byte.  The buffer definition was extended 3 bytes just for this purpose.
\
: set-#down-keys  ( -- #down-keys )
  0						( #down-keys' )
  6 0 do
     i get-keynumber ?dup if			( #down-keys' key-value )
        kbd-err? if				( #down-keys' )
           drop 0 leave				( 0-down-keys )
        else
           1+					( #down-keys' )
        then
     then
  loop						( #down-keys' )

  dup 0= if
    exit					( #down-keys )
  then						( #down-keys' )

  keybuff-curr^v >kbd-in-modkeys c@		( #down-keys' modbyte )

  dup h# 11 and if				\ either left or rt cntrl
     d# 224 add-key-to-array			( #down-keys' modbyte )
     \ put the byte representing a Cntrl into
     \ the 1st available key array locn
  then
  dup h# 22 and if				\ either left or rt shift
     d# 225 add-key-to-array
     \ put the byte representing a Shift into
     \ the 1st available key array locn
  then
  dup h# 40 and if				\ rt alt = AltGraph
     d# 230 add-key-to-array			( #down-keys' modbyte )
     \ put the byte representing an AltGraph 
     \ into the 1st available key array locn
  then
  drop						( #down-keys )
  dup curr-#ksdn-bfaddr c!			( #down-keys )
;
 

\ In the buffer that holds the key information for the previous key
\ report, zero the bytes that hold the # of down keys and # of "regular"
\ down keys, and clear the special key flags.
\
: clear-all-prev-keys  ( -- )
  0 keybuff-prev >#keys-down c!
  0 keybuff-prev >#regl-keys-dn c!
  -1 to pr-shiftflag   -1 to pr-ctrlflag   -1 to pr-altgflag
  -1 to pr-powerflag   -1 to pr-monflag    -1 to pr-stopflag
;


\ In the buffer that holds the key information for the current key
\ report, zero the bytes that hold the # of down keys and # of "regular"
\ down keys, and clear the special key flags.  Don't need to zero the
\ individual key data bytes because they are set for each report by the
\ hid kbd device.
\
: clear-all-curr-keys  ( -- )
  0 curr-#ksdn-bfaddr c!
  0 keybuff-curr^v >#regl-keys-dn c!
  -1 to shiftflag   -1 to ctrlflag   -1 to altgflag
  -1 to powerflag   -1 to monflag    -1 to stopflag
;


\ An "ack" was received from the keyboard, so we can now go and evaluate
\ the keycodes that were received in the current report.
\
: eval-key-data   ( -- Stop-a? )

   0 to unstall-cnt
  set-#down-keys if			( )
  \ If *any* key was pressed - std or "special", i.e. cntrl.
     start-key-processing		( Stop-a? )
     copy-curr-to-prev			( Stop-a? )
     clear-all-curr-keys		( Stop-a? )
  else
     clear-all-prev-keys   false	( no-Stop-a )
     nokey to curr-repeat-key		( no-Stop-a )
  then
;

\ Clear the software state associated with the keyboard. This is called
\ when the PROM is entered from an unknown state.
\
: clear-keyboard ( -- )
  initkeybuf		\ clear the keyboard circular queue
  clear-all-curr-keys
  clear-all-prev-keys
  nokey to curr-repeat-key
;
