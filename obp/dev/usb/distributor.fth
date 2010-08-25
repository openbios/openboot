\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: distributor.fth
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
id: @(#)distributor.fth 1.11 02/03/12
purpose: 
copyright: Copyright 1997-2000, 2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

: end-of-line  ( first-transfer -- last-transfer )
   begin
      dup next-transfer le-l@
   while
      next-transfer le-l@ dev>virt
   repeat
;

: add-to-line  ( transfer-d last-transfer -- )
   swap virt>dev swap  next-transfer le-l!
;

\ Put on done q in the same order as they show up on the controller done-q.
\ Stored on the endpoint done-q's as dev addresses, little endian, because
\ we reuse next-transfer to tie the q together, just as the other q's.
\ Could change to use a different field and virt addresses.
\ Don't need to sync this because the controller never accesses this field.
: t>end-done  ( transfer-d -- )
   0 over next-transfer l!	\ at least for now, this will be the last one
				\ "should" be le-l!, but the result is the same
   dup my-endpoint @
   dup ping-done-q
   swap for-controller @ +	( transfer-d endp-q-pointer )
   dup @  if			\ go to the end of the line
      @ end-of-line add-to-line
   else  !
   then
;

: distribute-replies  ( dev-done-head -- )
   begin
      dev>virt dup sync-transfer
      dup next-transfer le-l@ swap		( dev-next curr-transfer-d )
      t>end-done				( dev-next )
      ?dup 0=					\ 0 marks end of q
   until
;

variable done-mutex		\ must be global

\ This mutex code is a little cleverer, it will release the mutex if
\ the caller is the current owner.
\ Stolen from the keyboard code.
\ XXX may not need this cleverness.
\ XXX heavily dependent on 32 bit execution tokens, as it gets something
\ from the return stack and saves it in a 32 bit variable.

\ XXX doesn't look like it really works here.  mutex-enter is only called by take-done-q,
\ so the done-owner is always the same (once the open is done).  open always unlocks
\ the mutex, so how does this protect the distributor?

\ variable done-owner		\ XXX global?

\ : mutex-enter  ( -- locked? )
\  done-mutex dup @ swap on		( locked? )
\  r@ done-owner rot  if			( req var )
\    2dup @ <>  if			( req var )
\      2drop true exit			( true )
\    then				( var req )
\  then					( req var )
\  ! false				( false )
\ ;

\ : mutex-exit ( -- )  done-mutex off  ;

\ Used by done-waiting?
: take-done-q  ( -- )
   new-done?  if
      sync-hcca
      hcca done-head le-l@
\ toss interrupt-on bit which un-aligns the done-head:
      1 invert and
      clear-done-head
      distribute-replies
   then
;

\ Really should take off the alarm list when quit level runs, then put back on alarm
\ list.  Redman says that triggers an alarm list bug, so can't do it now.

: alarm-take-done-q  ( -- )		\ use on alarm level with 10 ms tick timer
   done-mutex @ 0=  if			\ XXX diff from use in mutex-enter, -exit
      take-done-q
   then
;

: quit-take-done-q  ( -- )		\ use on quit loop level
   true done-mutex !			\ XXX diff from use in mutex-enter, -exit
   take-done-q
   0 done-mutex !
;

\ Replies are distributed by children, but the distributor is protected by
\ the mutex so that replies go in order.

\ XXX Check this code to make sure it's re-entrant.
\ XXX Check this code to make sure it has no race conditions with the code
\ running at the normal level which is editing the q's to install new stuff
\ or disable-int-transactions.

\ XXX Problem:  10 ms timer ticking for the keyboard and disk being booted
\ from.  each can see the other's transfer descriptors on the done q.
\ Keep old done-q's until descriptors are all claimed?  Or timed out somehow?
\ **attach a done-q to each endpoint descriptor and distribute them from the
\ chip's done-q?

\ Still a problem if the keyboard is looking at 10ms timer intervals,
\ essentially interrupting, while the boot device is looking at the regular
\ execution intervals.  There's a race condition over who looks at the
\ done q of the chip to distribute the transfer descriptors.

\ In practice there will be 1 set of transactions running off the 10ms timer
\ for the keyboard and 1 running as usual for a boot device.  There may be
\ more instances of usb devices open, but only these will be running.
\ Even if there is a usb output device that runs interrupt transfers, that
\ will probably be run as a normal device, rather than hung off the 10 ms
\ timer.

\ The normal code looks to see if there are transfers to distribute.  There
\ are.  Just then, the interrupt code runs, finds and distributes the
\ transfers.  It finishes, and the normal code thinks there are transfers
\ to distribute, so it tries to do so -- but they have already been
\ distributed before the normal code could grab the done q.

\ One possible solution:
\ Put the done-q transfer distribution code at the 10 ms interrupt as well.

\ Another one:
\ The normal instance looks again after grabbing the done q to find out if
\ there are really any transfers to distribute (by looking at the bit in the
\ register?).  If there are it distributes them, because it really has the
\ done q now, having set the control.  If the ones that were there before
\ have already been distributed, but new ones arrived (so the bit is true),
\ that's ok.  Just go ahead and distribute them.

\ **Better variation:
\ Grab the done q before finding out whether there are any entries.  Then
\ look at the done q and distribute.  Then give up the q, and look at the
\ endpoint done q.

\ Is there another race condition?  The normal code looks at its endpoint
\ done q, and while fiddling with it, a new transfer is distributed to it
\ by the 10ms timer instance.  What happens?  Does grabbing the done q
\ extend to grabbing all the done q's at once?

\ Note, once the chip done-q is turned over to the software, the chip
\ essentially stalls until it is returned to the chip.  The chip doesn't
\ re-use the old done-q, but rather starts a new one.  So all the transfers
\ on the done-q must be distributed before the done-q is lost track of.  So
\ can't have the situation where the normal code grabbed its own done q and
\ locked out the 10 ms timer code from distributing a transfer onto the normal
\ done q, as the 10 ms timer code has a problem knowing what to do with the
\ leftover transfers, and can't sit waiting for the normal code to release
\ its done q.

\ **use two endpoint done q's.  one being emptied by the code, one being filled
\ by the distributor.  while the code is emptying one, it does not touch the
\ other.  also, the distributor only puts them on the other and does not touch
\ the one being emptied.  when 1st is empty, code switches to the other.
\ switch is ok, as if distributor puts some more on just as code is switching,
\ that's ok.

\ what about a pipe between the distributor and the code?  don't see it.

\ could also use a ring of transfer addresses without links.  could work,
\ but it seems more cumbersome than just ping-ponging the q's.

\ must be the kind of thing that the normal code doesn't need to lock, since
\ the distributor code can't block, since it might be running as part of
\ the 10ms timer instance.
