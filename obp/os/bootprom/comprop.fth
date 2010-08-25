\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: comprop.fth
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
id: @(#)comprop.fth 1.7 02/06/12
purpose:
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

: decode-ints  ( adr len n -- nn .. n1 )
   dup begin  ?dup  while              ( adr len n cnt )     ( r: phys.hi.. )
      >r >r  decode-int r> r> rot >r   ( adr' len' n cnt )   ( r: phys.hi... )
      1-                               ( adr' len' n cnt-1 ) ( r: phys.hi... )
   repeat                              ( adr' len' n )       ( r: phys.hi..lo )
   begin  ?dup  while                  ( adr' len' cnt )     ( r: phys.hi.. )
      r> swap 1-                       ( adr' len' phys.lo.. cnt-1 )
   repeat                              ( adr' len' phys.lo..hi )
;

headers
: encode-phys  ( phys.lo..hi -- addr len )
   0 0 encode-bytes my-#adr-cells 0  ?do  rot encode-int encode+  loop
;

: decode-phys  ( adr len -- adr' len' phys.lo..hi )
   my-#adr-cells decode-ints
;

: encode-reg  ( phys.lo..hi size -- adr len )
   >r  encode-phys  r> encode-int encode+
;

headerless
\ The IEEE standard restricts the use of encode-reg to buses
\ with #size-cells=1 .  Therefore, the generalized code that
\ immediately follows is not strictly necessary; the simplified
\ version above is sufficient for IEEE compliance.

: my-parent-#size-cells  ( -- #size-cells )
   \ Root node has no parent, therefore the size of its parent's address
   \ space is meaningless
   my-voc  ['] root-node =  if  0  exit  then

   " #size-cells"    my-parent ihandle>phandle  ( adr len phandle )
   get-package-property  if  1  else  get-encoded-int  then
;

headers

: string-property   ( value-adr,len name-adr,len -- )
   2swap encode-string 2swap  property
;
: integer-property ( value  name-adr,len -- )
   rot encode-int 2swap property
;
: device-name  ( adr len -- )  " name" string-property  ;
alias nameprop device-name

: driver  ( adr len -- )   \ string is of the form: manufacturer,name
   ascii , left-parse-string                          ( after-, before-, )
   2swap  dup  if                                     ( man.-str name-str )
      device-name
      " manufacturer" string-property
   else                                               ( null-str name-str )
      2drop  device-name
   then
;
: device-type  ( adr len -- )  " device_type" string-property  ;

headerless
: encode-ranges ( child.hi child.lo parent.hi parent.lo child.size -- adr len )
   >r >r >r  swap encode-phys  r> r> swap r> encode-reg  encode+
;
headers
