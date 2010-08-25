\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: generic-names.fth
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
id: @(#)generic-names.fth 1.3 00/06/23
purpose: PCI bus package
copyright: Copyright 1997-2000 Sun Microsystems, Inc.  All Rights Reserved

\
\ Pulled from pcibus.fth from firmworks to keep the generic vs standard
\ name code localised.
\
: class-name ( code name$ --- )
   rot ,			( name$ )
   dup c,			( name$ )
   bounds do i c@ c, loop 0 c,	( -- )
   align			( -- )
;

hex
align
create class-names

ffffff ,  \ Mask
000100 " display"		class-name
0 , 	  \ No more entries for this mask

ff0000 ,  \ Mask
030000 " display"		class-name 
0a0000 " dock"			class-name 
0b0000 " cpu"			class-name
0 , 	  \ No more entries for this mask

ffff00 ,  \ Mask
010000 " scsi"			class-name
010100 " ide"			class-name
010200 " fdc"			class-name
010300 " ipi"			class-name
010400 " raid"			class-name
020000 " ethernet"		class-name
020100 " token-ring"		class-name
020200 " fddi"			class-name
020300 " atm"			class-name
040000 " video"			class-name
040100 " sound"			class-name
050000 " memory"		class-name
050100 " flash"			class-name
060000 " host"			class-name
060100 " isa"			class-name
060200 " eisa"			class-name
060300 " mca"			class-name
060400 " pci"			class-name
060500 " pcmcia"		class-name
060600 " nubus"			class-name
060700 " cardbus"		class-name
070000 " serial"		class-name
070100 " parallel"		class-name
080000 " interrupt-controller"	class-name
080100 " dma-controller"	class-name
080200 " timer"			class-name
080300 " rtc"			class-name
090000 " keyboard"		class-name
090100 " pen"			class-name
090200 " mouse"			class-name
0c0000 " firewire"		class-name
0c0100 " access-bus"		class-name
0c0200 " ssa"			class-name
0c0300 " usb"			class-name
0c0400 " fibre-channel"		class-name
0 ,       \ No more entries for this mask
0 ,       \ End of table

: @+  ( adr -- adr' n )  dup na1+ swap @  ;

: unknown-class?  ( class-code -- true | class-name$ false )
   \ The outer loop executes once for each distinct mask value
   class-names  begin  @+  dup  while        ( code adr mask )
      2 pick and >r                          ( code adr r: masked-code )

      \ The inner loop searches all entries with that mask value
      begin  @+  dup  while                  ( code adr match )

         r@ =  if                            ( code adr )
            \ A match under the mask was found; return the string
            r> drop nip  count false  exit   ( class-name$ false )
         then                                ( code adr )
         \ Skip the string and proceed to the next entry
         count + 1+ /n round-up
      repeat                                 ( code adr 0 )

      \ Proceed to the next mask value
      r> 2drop                               ( code adr )
   repeat                                    ( code adr 0 )

   \ No match was found
   3drop true                                ( true )
;
