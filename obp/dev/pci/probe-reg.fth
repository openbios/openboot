\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: probe-reg.fth
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
id: @(#)probe-reg.fth 1.15 06/04/21
purpose: PCI/UPA bus mapping
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

headerless

h# 0000.1fff invert constant pci-pagemask

struct
   /n field >bar.phys.hi			\ encoded phys.hi
   /n field >bar.size				\ current allocated size
   /n field >bar.value				\ current PA
   /n field >bar.implemented?
   /n field >bar.assigned?
constant /bar-struct

d# 7 /bar-struct * constant /bar-data

: alloc-bar-struct ( -- ptr )  /bar-data alloc-mem  ;
: free-bar-struct  ( ptr -- )  /bar-data free-mem   ;

\ We always need at least one of these.
alloc-bar-struct to bar-struct-addr

\ this returns an effective bar# which may be used to index into bar.struct
: get-bar# ( phys.hi -- bar# )
   h# ff and					( cfg-offset )
   h# 10 - 4 /					( bar# )
   \ BARs 0-5 are normal. 6 is either at offset 30 or 38 (ROMBAR)
   dup h# 6 > if drop 6 then			( bar# )
;

: >bar-struct ( bar# -- struct ) /bar-struct *  bar-struct-addr  +  ;

: probe-l@ ( physhi -- n ) $config-l@ $call-parent ;
: probe-l! ( n physhi -- ) $config-l! $call-parent ;

\
\ This used to be clean.. now it is polluted with a BAR check!
\ This is there because certain PLX devices violate the PCI SPEC by
\ permitting thier IO/MEM bit to be *WRITEABLE*, so probing with -2
\ which should be safe for all BARs screws them up..
\ Wintel has a lot to answer for!
\
: probe-reg ( physhi -- size )
   dup >r probe-l@				( old-value )
   -1 r@ get-bar# 6 = if  1-  then  r@ probe-l!	( old-value )
   r@ probe-l@					( old-value new-value )
   swap r> probe-l!				( new-value )
;

: probe-base-reg ( offset -- offset implemented? )
   my-space +					( phys.hi )
   dup get-bar# dup >r 5 > if			( phys.hi )
      \ This is a ROMBAR			( phys.hi )
      2 ss#>cfg or dup probe-reg		( phys.hi bits )
      pci-pagemask and				( phys.hi size' )
      4 -rot					( #bytes phys.hi size' )
   else						( phys.hi )
      dup probe-l@				( phys.hi bar-bits )
      dup 1 and if				( phys.hi bar-bits )
         \ I/O register				( phys.hi )
         drop dup probe-reg			( phys.hi bits )
         3 invert and				( phys.hi bits )
         dup h# 1.8000 and  h# 0.8000 = if	( phys.hi bits )
            \ Some cards don't implement the
            \  high bits in the I/O decoder.
            h# ffff d# 16 lshift or		( phys.hi bits' )
         then					( phys.hi bits )
         swap 1 ss#>cfg or swap			( phys.hi size )
         4 -rot					( 4 phys.hi size )
      else					( phys.hi bar-bits )
         \ Memory				( phys.hi bar-bits )
         \ Save Bar contents for later use after this case 
         tuck 1 >> 3 and case			( bar-bits phys.hi )
            0 of     2 ss#>cfg or 4  endof	( bar-bits phys.hi #bytes )
            1 of h# 82 ss#>cfg or 4  endof	( bar-bits phys.hi #bytes )
            2 of     3 ss#>cfg or 8  endof	( bar-bits phys.hi #bytes )
            3 of ." BAR has reserved bits set" abort endof
         endcase				( bar-bits phys.hi #bytes )
         -rot					( #bytes bar-bits phys.hi )
         \ If prefetchable bar, propagate into REG.
         \ prefetch bit is bit 3, from the pci local bus spec
         swap h# 8 and if 40 ss#>cfg or  then	( #bytes phys.hi )
         dup probe-reg				( #bytes phys.hi bits )
         pci-pagemask and			( #bytes phys.hi bits' )
      then					( #bytes phys.hi bits' )
   then						( #bytes phys.hi bits' )
   dup invert 1+ and32				( #bytes phys.hi size )
   r>						( #bytes phys.hi size bar# )
   >bar-struct					( #bytes phys.hi size adr )
   over 0<> dup >r over >bar.implemented? !	( #bytes phys.hi size adr )
   debug-probe-bar? if  ." ( " over .x ." )"  then
   tuck >bar.size !				( #bytes phys.hi adr )
   >bar.phys.hi !				( #bytes phys.hi adr )
   r>						( #bytes implemented? )
;

: make-power-of-2 ( n -- n' )
   d# 32 0 do					( n )
      1 i lshift				( n p2 )
      2dup u<= if				( n p2 )
        nip leave				( p2 )
      else					( n p2 )
        drop					( n )
      then					( n )
   loop						( p2 )
;

\ How we assign physical resource to a BAR
\
\ Note the defer..
\ It is unfortunate that this routine can be called in 2 different
\ contexts.
\   1. (the normal path) As a result of normal BAR probing in which case
\      the code is executing in the child instance and we need to
\      $call-parent to do config accesses.
\   2. (the abnormal path) As a result of a map-in at probe time that
\      exceeds the allocated resource sizes of the BAR. In which case
\      we were called by $call-parent and now need to $call-self to do
\      config accesses.
\
\ By duplicating the $config-X $call-who I attempted to reduce the
\ chances of someone accidently refering to the either uninitialised
\ defer or the more likely incorrectly initialised defer.
\
defer $call-who
: (assign-bar-resources) ( phys.hi acf -- )
   to $call-who					( phys.hi )
   get-bar# >bar-struct >r			( -- )
   r@ >bar.size dup @				( addr size )
   make-power-of-2 tuck	swap !			( size )
   r@ >bar.phys.hi @				( size phys.hi )
   cfg>ss# h# 3 and case			( -- )
      0 of 3drop true endof			( true )
      1 of dup pci-io-list allocate-memrange 	( pa,0 | true )
           dup 0= if			 	( pa,0 | true )
              over r@ >bar.phys.hi @		( pa,0 pa phys.hi )
              $config-l! $call-who		( pa,0 )
           then					( pa,0 | true )
        endof					( pa,0 | true )
      2 of dup pci-memlist allocate-memrange	( pa,0 | true )
           dup 0= if				( pa,0 | true )
              over r@ >bar.phys.hi @		( pa,0 pa phys.hi )
              $config-l! $call-who		( pa,0 )
           then					( pa,0 | true )
        endof					( pa,0 | true )
      3 of dup pci-memlist allocate-memrange	( pa,0 | true )
           dup 0= if				( pa,0 | true )
              r@ >bar.phys.hi @	>r		( pa 0 )
              over r@ $config-l! $call-who	( pa,0 )
              0 r> 4 + $config-l! $call-who	( pa,0 )
           then					( pa,0 | true )
        endof					( pa,0 | true )
   endcase					( pa,0 | true )
   r> swap if					( ptr )
      \ Resource allocation problem..
      ." Unable to assign resources for device "
      " name" my-self ihandle>phandle get-package-property
      if ." <unnamed>" else type then cr
      drop abort				( -- )
   else						( pa ptr )
      debug-probe-bar? if  ." Reg: " dup >bar.phys.hi @ .x ." = " over .x cr  then
      true over >bar.assigned? !		( pa ptr )
      >bar.value !				( -- )
   then						( -- )
;

\ Called when probing, executing in child instance
: assign-bar-resources ( phys.hi -- )
  ['] $call-parent (assign-bar-resources)
;

\ Called at probe time from map-in via a $call-parent
: reassign-bar-resources ( phys.hi -- )
  ['] $call-self (assign-bar-resources)
;

\
\ How we release resources a BAR has been using.
\ 
: release-bar-resources ( phys.hi -- )
   dup get-bar# >bar-struct >r			( phys.hi -- )
   r@ >bar.assigned? @ 0= if			( phys.hi )
      r> 2drop					( -- )
   then						( phys.hi )
   0 r@ >bar.assigned? !			( phys.hi )
   debug-probe-bar? if  ." Releasing: BAR " dup .x ." = "   then
   r@ >bar.value dup @				( phys.hi addr pa )
   0 rot !					( phys.hi pa )
   r> >bar.size @				( phys.hi pa len )
   debug-probe-bar? if  over .x dup .x cr  then
   rot cfg>ss# 3 and 1 >			( pa len mem? )
   if  pci-memlist  else  pci-io-list  then	( pa len list )
   free-memrange				( -- )
;

: read-bar-resources ( offset -- incr implemented )
   debug-probe-bar? if  ." read-bar-resources: " dup .x   then
   \ This is called for devices that are currently enabled.
   \ We are much cruder here.. We set the size to the first multiple of
   \ 2 that the current register address is at.
   \ This is not optimal but is safe, probing an active device isn't.
   dup get-bar# >bar-struct >r			( offset )
   my-space +					( phys.hi )
   dup $config-l@ $call-parent 			( phys.hi size )
   over get-bar# 5 > if				( phys.hi size )
      h# f					( phys.hi size mask )
   else						( phys.hi size )
      dup 1 and  if 3  else h# f then 		( phys.hi size mask )
   then						( phys.hi size mask )
   invert over and  				( phys.hi size size' )
   0=  if 					( phys.hi size )
      drop					( phys.hi )
      my-space - 				( offset )
      dup probe-base-reg if                     ( phys.hi next )
         swap assign-bar-resources true         ( next true )
      else                                      ( phys.hi next )
         nip false                              ( next 0 )
      then                                      ( offset implemented? )
      r> drop					( offset implemented? )
   else 					( phys.hi size )
      >r					( phys.hi )
      r@ 1 and if				( phys.hi )
         h# 81 ss#>cfg or 4			( phsy.hi' size )
      else					( phys.hi )
         r@ 1 rshift 3 and 2 =			( phys.hi mem64? )
         if   8 3  else  4 2  then		( phys.hi size type )
         r@ 8 and if  h# 40 or  then swap	( phys.hi type' size )
         >r h# 80 or ss#>cfg or r>		( phys.hi' size )
      then					( phys.hi' size )
      swap r>					( size phys.hi value )
      debug-probe-bar? if  over .x ." @ " dup .x  then
      over cfg>mask and				( size phys.hi value' )
      dup dup invert 1+ and			( size phys.hi value' decode )
      debug-probe-bar? if  ." ( " dup .x ." )" cr  then
      r@ >bar.size !				( size phys.hi value' )
      dup r@ >bar.value !			( size phys.hi value' )
      0<>					( size phys.hi 0? )
      dup r@ >bar.assigned? !			( size phys.hi 0? )
      dup r@ >bar.implemented? !		( size phys.hi 0? )
      swap					( size 0? phys.hi )
      r> >bar.phys.hi !				( size 0? )
   then
;

: probe-and-assign-bar ( offset -- incr implemented? )
   debug-probe-bar? if  ."  probe-and-assign-bar: " dup .x  then
   dup probe-base-reg if			( phys.hi next )
      swap assign-bar-resources true		( next true )
   else						( phys.hi next )
     debug-probe-bar? if  cr  then		( phys.hi next )
     nip false					( next 0 )
   then						( offset implemented? )
;

: device-enabled? ( -- flag? )  4 parent-w@ 7 and ;

defer build-bar-resources ( offset -- )

\ page 347 top para of PCI System Architecture
\ 3rd edition  (ISBN 0-201-40993-3) states:
\ ... the configuration software will stop looking for base
\ registers in a devices header when it detects the first
\ unimplemented base register ...
\
\ However the PCI spec states:
\ The PCI specification Revision 2.2 states in section 6.2.5.1:
\ A type 00h predefined header has six DWORD locations allocated
\ for Base Address registers starting at offset 10h in Configuration
\ Space. A device may use any of the locations to implement
\ Base Address registers. An implemented 64-bit Base Address
\ register consumes two consecutive DWORD locations. Software looking
\ for implemented Base Address registers must start at offset 10h
\ and continue upwards through offset 24h.
\

: assign-addresses ( -- )
   bar-struct-addr /bar-data erase		( -- )
   device-enabled? if				( -- )
      ['] read-bar-resources			( acf )
   else						( -- )
      ['] probe-and-assign-bar			( acf )
   then  to build-bar-resources			( -- )
   base-register-bounds do			( -- )
      i build-bar-resources drop		( next )
   +loop					( )
   card-bus? 0= if
      expansion-rom build-bar-resources  2drop	( )
   then
;


0 value make-assigned?

\
\ This routine is used to construct the "assigned-addresses" and the "reg"
\ property. The code path was so similar it wasn't worth factoring.
\
: make-reg-type-property ( assigned? -- xdr,len )
   if h# 80 else 0 then to make-assigned?	( -- )
   0 0 encode-bytes				( xdr,len )
   make-assigned? 0= if				( xdr,len )
      my-space en+ 0 en+ 0 en+ 			( xdr,len )
      0 en+ 0 en+				( xdr,len )
   then						( xdr,len )
   7 0 do					( xdr,len )
      i >bar-struct 				( xdr,len ptr )
      dup >bar.implemented? @ if		( xdr,len ptr )
         dup >bar.size @ >r 0 >r		( xdr,len ptr )
         dup >bar.phys.hi @	  		( xdr,len ptr phys.hi )
[ifdef] 64BIT-ASSIGNED?
         make-assigned? if
            dup cfg>ss# 3 and 3 = if		( xdr,len ptr phys.hi )
               1 ss#>cfg xor			( xdr,len ptr phys.hi' ) 
            then
         then
[then]
         dup not-relocatable? make-assigned? or if	( xdr,len ptr phys.hi )
            over >bar.value @			( xdr,len ptr phys.hi phys.lo )
         else					( xdr,len ptr phys.hi )
            0					( xdr,len ptr phys.hi phys.lo )
         then >r 0 >r				( xdr,len ptr phys.hi )
         make-assigned? ss#>cfg or >r		( xdr,len ptr )
          -rot r> r> r> r> r> encode5 rot	( xdr,len ptr )
         >bar.phys.hi @ cfg>ss#			( xdr,len SS )
         h# 3 and 3 <> if 1 else 2 then		( xdr,len incr )
      else					( xdr,len )
         drop 1					( xdr,len incr )
      then					( xdr,len incr )
   +loop					( xdr,len )
;

: make-reg-property ( -- )  0 make-reg-type-property " reg" property ;

\
\ We only need to decode the "reg" property if we evaluated some fcode
\ because that is the only way the reg property could be made to differ
\ from the h/w.
\
\ We pull this stunt to permit cards that lie about thier decode ability
\ in h/w to be corrected in s/w. Certain Diamond cards are guilty of this.
\
: make-assigned-property ( parse? -- )
   " reg" my-self ihandle>phandle		( parse? reg$ phandle )
   get-package-property if  drop exit  then	( parse? xdr,len )
   rot 0= if drop 0 then			( xdr,len' )
   begin					( xdr,len )
      dup 0> while				( xdr,len )
         decode-int				( xdr,len phys.hi )
         dup >r 4 0 do drop decode-int loop	( xdr,len len )
         r> dup cfg>ss# 3 and if		( xdr,len len phys.hi )
            dup get-bar# >bar-struct >r		( xdr,len len phys.hi )
            r@ >bar.implemented? @  if		( xdr,len len phys.hi )
               drop r@ >bar.size @ over <  if	( xdr,len len reg-bigger? )
                  r@ >bar.phys.hi @		( xdr,len len phys.hi )
                  dup release-bar-resources	( xdr,len len phys.hi )
                  swap r@ >bar.size !		( xdr,len phys.hi )
                  assign-bar-resources		( xdr,len )
                  0				( xdr,len 0 )
               then				( xdr,len ? )
            else				( xdr,len len phys.hi )
	       -1 r@ >bar.implemented? !	( xdr,len len phys.hi )
 	       r@ >bar.phys.hi !		( xdr,len len phys.hi )
               r@ >bar.size !			( xdr,len len )
	       0 				( xdr,len 0 )
            then				( xdr,len ? )
            r>					( xdr,len ? ? )
         then					( xdr,len ? ? )
         2drop					( xdr,len )
   repeat 2drop					( -- )
   1 make-reg-type-property dup if
      " assigned-addresses" property
   else
      2drop
   then
;

: .dump-assigned-addr ( -- )
  ." Assigned BARs:" cr
  7 0 do
    i >bar-struct >r
    r@ >bar.implemented? @ r@ >bar.assigned? @ and if
      r@ >bar.phys.hi @ ." Phys.hi: " .x
      r@ >bar.size    @ ." size: " .x
      r@ >bar.value   @ ." located: " .x cr
      r> >bar.phys.hi @ cfg>ss# 3 = if 2 else 1 then
    else
      r> drop 1
    then
  +loop cr
;

: make-available-property ( -- )
   pci-io-list @ pci-memlist @ 2dup or if		( mem io )
      >r >r 0 0 encode-bytes				( xdr,len )
      r> begin						( xdr,len )
        dup while					( xdr,len node )
           dup >mem.size @ >r 0 >r			( xdr,len node )
           dup >mem.adr @ >r 0 >r h# 81 ss#>cfg >r	( xdr,len node )
           >next-node @ -rot r> r> r> r> r> encode5 rot ( node xdr,len )
      repeat  drop					( xdr,len node )
      r> begin						( xdr,len )
        dup while					( xdr,len node )
           dup >mem.size @ >r 0 >r			( xdr,len node )
           dup >mem.adr @ >r 0 >r h# 82 ss#>cfg >r	( xdr,len node )
           >next-node @ -rot r> r> r> r> r> encode5 rot	( node xdr,len )
      repeat  drop					( xdr,len )
      " available" property				( -- )
   else							( mem io )
      2drop						( -- )
   then							( -- )
;


