\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: canon.fth
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
id: @(#)canon.fth 1.3 02/05/02
purpose: 
copyright: Copyright 1995-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
0 value canon-buf
0 value canon-len
0 value canon-max

: canon+  ( adr len -- )
   canon-max canon-len - 1-  min     ( adr len )
   tuck  canon-buf canon-len +  swap move  canon-len +  to canon-len
;

: canon-node  ( buf path$ -- buf path$' )
   parse-component				( buf path$' args$ devname$ )
   noa-find-device				( buf path$' args$ )
   root-device? if				( buf path$' args$ )
      2drop root-device				( buf path$' )
   else						( buf path$' args$ )
      " /" 6 pick 0 $add			( buf path$' args$ node$ )
      unit#-valid?  if				( buf path$' args$ node$ )
         (append-name) 2>r			( buf path$' args$ )
         unit-bounds  ?do  i @  /n +loop	( buf path$' args$ n..n )
         '#adr-cells @  reorder			( buf path$' args$ n..n )
         2r> (append-unit)			( buf path$' args$ node$ )
      else					( buf path$' args$ node$ )
         (append-name+unit)			( buf path$' args$ node$ )
      then					( buf path$' args$ node$ )
      (append-args)				( buf path$' node$ )
      canon+					( buf path$' )
   then						( buf path$' )
;

: (canon)  ( path$ -- )
   ?dup  if						( path$ )
      \ Establish the initial parent
      null to current-device				( path$ )
      ?expand-alias					( path$ )
      "temp -rot					( adr path$ )
      begin  canon-node  dup  0= until			( adr path$' )
      3drop						( )
   else							( adr )
      not-found throw					(  )
   then							(  )
;

headers
cif: canon  ( len adr cstr -- actual-len )
   push-hex						( path$ )
   over 0=  if  3drop -1 exit  then
   cscount  2swap to canon-buf  to canon-max  0 to canon-len
   current-device >r

   ['] (canon) catch  if
      2drop  -1
   else
      0  canon-buf canon-len +  c!
      canon-len
   then

   r> push-device
   pop-base
;
