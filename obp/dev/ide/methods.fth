\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: methods.fth
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
id: @(#)methods.fth 1.5 02/05/02
purpose: 
copyright: Copyright 1997-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

external
: decode-unit  ( adr len -- lo hi )  decode-2int ;
: encode-unit ( l h -- adr,len )  swap <# u#s drop ascii , hold u#s u#> ;
: dma-alloc ( n -- v ) " dma-alloc" $call-parent ;
: dma-free ( vaddr bytes -- ) " dma-free" $call-parent ;
: dma-map-in  ( vaddr n cache? -- devaddr )  " dma-map-in" $call-parent  ;
: dma-map-out  ( vaddr devaddr n -- )        " dma-map-out" $call-parent  ;

: disk-block-size ( bytes -- ) is blocksize ;

: run-command ( pkt -- error? )
   dup >xfer-type l@ case
     0 of run-ata endof
     1 of run-atapi endof
     ( pkttype ) >r drop true r>
   endcase
   timeout? if false  (reset)  drop  then
;

: identify ( target lun -- )
  set-address if
    h# EC id-cmd c!				( -- )
    id-buf id-cmd d# 2000 id-pkt		( buffer cmd timeout pkt )
    set-pkt-data run-ata if			( -- )
      id-pkt >status l@ h# 1 and if		( -- )
        false (reset) drop			( -- )
        h# A1 id-cmd c!				( -- )
        id-buf id-cmd d# 2000 id-pkt		( buffer cmd timeout pkt )
        set-pkt-data run-ata if			( -- )
          .not-present				( false )
        else					( -- )
          true					( true )
        then					( data? )
      else					( -- )
        .not-present				( -- false )
      then					( data? )
    else					( -- )
      true					( true )
    then					( data? )
    if                                          ( -- )
      id-buf w@ dup 4 spaces
      h# 80 bitset? if ." Removable" then space
      ." ATA" h# 8000 bitset? if ." PI" then space
      Model-#
    then
  then cr
;

: device-present? ( target -- present? )
   present 1 rot << and        
;

: reset&check ( -- )
  secondary? if 4 else 2 then 0 do
     i 0 set-address if
      true (reset)  if 
         reset-bsy-timeout wait-!busy?  if 
            present h# 10 and 0=  if
               present  3 i << or is present 
            then
         then
      then
     then
  2 +loop
  present h# 10 and 0=  if  present h# 10 or is present  then
  
;

: reset ( -- )
   map-regs
   secondary? if 4 else 2 then 0 do 
      i 0 set-address if  false (reset) drop  then
   2 +loop
   unmap-regs
;

: open	( -- flag )
  map-regs reset&check			\ reset primary
  true
;

: close	 ( -- )
  unmap-regs
;

: show-children ( -- )
   open 0= if exit then
   secondary? if 4 else 2 then 0 do
      ."   Device " i . 
      i 1 and i 1 >>
      ."  ( " if  .secondary else .primary then
      if .slave  else  .master  then ." ) " cr
      5 spaces 
      present 1 i << and  if 
         i 0 identify 
      else 
         .not-present cr drop 
      then cr
   loop
   close
;

reset
